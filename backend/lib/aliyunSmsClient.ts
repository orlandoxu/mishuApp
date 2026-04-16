import crypto from "node:crypto";
import { config } from "../config/config";

export type SmsSendResult = {
  success: boolean;
  message: string;
  code?: string;
  requestId?: string;
};

type SmsSendParams = {
  phoneNumber: string;
  code: string;
};

const SIGNATURE_ALGORITHM = "ACS3-HMAC-SHA256";
const API_VERSION = "2017-05-25";
const ACTION = "SendSms";

export function mapAliyunSmsError(code?: string): string {
  const messages: Record<string, string> = {
    "isv.BUSINESS_LIMIT_CONTROL": "发送过于频繁，请稍后再试",
    "isv.MOBILE_NUMBER_ILLEGAL": "手机号码格式错误",
    "isv.TEMPLATE_MISSING_PARAMETERS": "模板参数缺失",
    "isv.INVALID_PARAMETERS": "参数无效",
    "isv.SIGN_NAME_ILLEGAL": "签名不合法",
    "isv.TEMPLATE_ILLEGAL": "模板不合法",
    "isv.SMS_TEMPLATE_ILLEGAL": "短信模板不合法",
    "isv.SMS_SIGNATURE_ILLEGAL": "短信签名不合法",
    "isp.RAM_PERMISSION_DENY": "短信服务权限不足",
    NETWORK_ERROR: "网络连接异常，请稍后重试",
  };
  return messages[code ?? ""] ?? "短信发送失败";
}

function sha256Hex(content: string): string {
  return crypto.createHash("sha256").update(content, "utf8").digest("hex");
}

function hmacSha256Hex(secret: string, content: string): string {
  return crypto
    .createHmac("sha256", secret)
    .update(content, "utf8")
    .digest("hex");
}

function encodeRFC3986(value: string): string {
  return encodeURIComponent(value).replace(
    /[!'()*]/g,
    (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

function buildQueryString(params: Record<string, string>): string {
  return Object.entries(params)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${encodeRFC3986(k)}=${encodeRFC3986(v)}`)
    .join("&");
}

export async function sendVerificationCodeSms(
  params: SmsSendParams,
): Promise<SmsSendResult> {
  const endpointURL = new URL(config.sms.endpoint);
  const host = endpointURL.host;
  const payloadHash = sha256Hex("");
  const xAcsDate = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const xAcsSignatureNonce = crypto.randomUUID().replaceAll("-", "");

  const requestParams: Record<string, string> = {
    Action: ACTION,
    Version: API_VERSION,
    PhoneNumbers: params.phoneNumber,
    SignName: config.sms.signName,
    TemplateCode: config.sms.templateCode,
    TemplateParam: JSON.stringify({ code: params.code }),
  };

  const canonicalQueryString = buildQueryString(requestParams);
  const signedHeaders =
    "host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version";
  const canonicalHeaders =
    `host:${host}\n` +
    `x-acs-action:${ACTION}\n` +
    `x-acs-content-sha256:${payloadHash}\n` +
    `x-acs-date:${xAcsDate}\n` +
    `x-acs-signature-nonce:${xAcsSignatureNonce}\n` +
    `x-acs-version:${API_VERSION}\n`;
  const canonicalRequest =
    `POST\n` +
    `/\n` +
    `${canonicalQueryString}\n` +
    `${canonicalHeaders}\n` +
    `${signedHeaders}\n` +
    `${payloadHash}`;
  const stringToSign = `${SIGNATURE_ALGORITHM}\n${sha256Hex(canonicalRequest)}`;
  const signature = hmacSha256Hex(config.sms.accessKeySecret, stringToSign);
  const authorization = `${SIGNATURE_ALGORITHM} Credential=${config.sms.accessKeyId},SignedHeaders=${signedHeaders},Signature=${signature}`;

  const requestURL = `${config.sms.endpoint}/?${canonicalQueryString}`;

  try {
    const response = await fetch(requestURL, {
      method: "POST",
      headers: {
        host,
        Authorization: authorization,
        "x-acs-action": ACTION,
        "x-acs-version": API_VERSION,
        "x-acs-date": xAcsDate,
        "x-acs-signature-nonce": xAcsSignatureNonce,
        "x-acs-content-sha256": payloadHash,
      },
    });
    const json = (await response.json()) as {
      Code?: string;
      Message?: string;
      RequestId?: string;
    };

    if (json.Code === "OK") {
      return {
        success: true,
        message: "验证码发送成功",
        requestId: json.RequestId,
      };
    }

    return {
      success: false,
      message: json.Message ?? "短信发送失败",
      code: json.Code,
      requestId: json.RequestId,
    };
  } catch (error: any) {
    if (error?.code && error?.data) {
      return {
        success: false,
        message: error.data.Message ?? "短信发送失败",
        code: error.code,
        requestId: error.data.RequestId,
      };
    }
    return {
      success: false,
      message: error instanceof Error ? error.message : "短信发送异常",
      code: "NETWORK_ERROR",
    };
  }
}
