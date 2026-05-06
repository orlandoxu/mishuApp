import { config } from "../config/config";
import { DoubaoCallLog } from "../models/DoubaoCallLog";

// DONE-AI: 统一只使用 userId 字段，避免 user/userId 双字段并存导致调用与日志口径不一致。
export type DoubaoEmbeddingRequest = {
  input: string | string[];
  userId?: string;
};

export type DoubaoEmbeddingVector = {
  index: number;
  embedding: number[];
};

export type DoubaoEmbeddingResult = {
  model: string;
  vectors: DoubaoEmbeddingVector[];
  usage?: {
    promptTokens: number;
    totalTokens: number;
  };
};

type ArkEmbeddingResponse = {
  model: string;
  data: Array<{ index: number; embedding: number[] }>;
  usage?: {
    prompt_tokens: number;
    total_tokens: number;
  };
};

function getEmbeddingApiUrl(): string {
  return `${config.doubao.baseUrl.replace(/\/$/, "")}/embeddings`;
}

function getHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.doubao.k}`,
  };
}

function normalizeInput(input: string | string[]): string | string[] {
  if (Array.isArray(input)) {
    const values = input.map((item) => item.trim()).filter(Boolean);
    if (values.length === 0) {
      throw new Error("doubao embedding 输入不能为空");
    }
    return values;
  }

  const text = input.trim();
  if (!text) {
    throw new Error("doubao embedding 输入不能为空");
  }
  return text;
}

function estimateTextTokens(text: string): number {
  const normalized = text.trim();
  if (!normalized) return 0;
  const cjkChars = (normalized.match(/[\u3400-\u9FFF]/g) ?? []).length;
  const otherChars = normalized.length - cjkChars;
  return Math.max(1, Math.ceil(cjkChars * 1.1 + otherChars / 4));
}

function estimateEmbeddingInputTokens(input: string | string[]): number {
  if (Array.isArray(input)) {
    return input.reduce((acc, item) => acc + estimateTextTokens(item), 0);
  }
  return estimateTextTokens(input);
}

function buildPreview(value: unknown, maxLen = 600): string {
  const raw = typeof value === "string" ? value : JSON.stringify(value);
  if (!raw) return "";
  return raw.length > maxLen ? `${raw.slice(0, maxLen)}...` : raw;
}

export class DoubaoEmbaddingService {
  static async createEmbedding(
    request: DoubaoEmbeddingRequest,
  ): Promise<DoubaoEmbeddingResult> {
    const startTime = Date.now();
    const modelName = config.doubao.embeddingModel;
    const requestPayload: Record<string, unknown> = {
      model: modelName,
      input: normalizeInput(request.input),
      user: request.userId,
    };
    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      config.doubao.timeoutMs,
    );

    try {
      const response = await fetch(getEmbeddingApiUrl(), {
        method: "POST",
        headers: getHeaders(),
        body: JSON.stringify(requestPayload),
        signal: controller.signal,
      });

      if (!response.ok) {
        const raw = await response.text();
        throw new Error(
          `doubao embedding 请求失败(${response.status}): ${raw}`,
        );
      }

      const data = (await response.json()) as ArkEmbeddingResponse;
      const result = {
        model: data.model ?? modelName,
        vectors: data.data ?? [],
        usage: data.usage
          ? {
              promptTokens: data.usage.prompt_tokens,
              totalTokens: data.usage.total_tokens,
            }
          : undefined,
      };
      await DoubaoCallLog.writeLog({
        apiType: "embedding",
        modelId: result.model,
        userId: request.userId,
        requestPayload,
        responsePayload: data as unknown as Record<string, unknown>,
        requestPreview: buildPreview(requestPayload),
        responsePreview: buildPreview({ vectors: result.vectors.length }),
        inputTokens:
          result.usage?.promptTokens ??
          estimateEmbeddingInputTokens(
            requestPayload.input as string | string[],
          ),
        outputTokens: 0,
        totalTokens:
          result.usage?.totalTokens ??
          estimateEmbeddingInputTokens(
            requestPayload.input as string | string[],
          ),
        tokenSource: result.usage ? "provider" : "estimated",
        durationMs: Date.now() - startTime,
        success: true,
      });
      return result;
    } catch (error) {
      await DoubaoCallLog.writeLog({
        apiType: "embedding",
        modelId: modelName,
        userId: request.userId,
        requestPayload,
        requestPreview: buildPreview(requestPayload),
        responsePreview: "",
        inputTokens: estimateEmbeddingInputTokens(
          requestPayload.input as string | string[],
        ),
        outputTokens: 0,
        totalTokens: estimateEmbeddingInputTokens(
          requestPayload.input as string | string[],
        ),
        tokenSource: "estimated",
        errorMessage: (error as Error).message,
        durationMs: Date.now() - startTime,
        success: false,
      });
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
  }

  static async embedText(text: string): Promise<number[]> {
    const result = await this.createEmbedding({ input: text });
    const first = result.vectors[0]?.embedding;
    if (!first || first.length === 0) {
      throw new Error("doubao embedding 返回空向量");
    }
    return first;
  }
}
