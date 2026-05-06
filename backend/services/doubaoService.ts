import { config } from "../config/config";
import { DoubaoCallLog } from "../models/DoubaoCallLog";

export type DoubaoMessageRole = "system" | "user" | "assistant";

export type DoubaoMessage = {
  role: DoubaoMessageRole;
  content: string;
};

export type DoubaoChatRequest = {
  messages: DoubaoMessage[];
  temperature?: number;
  maxTokens?: number;
  responseFormat?: "text" | "json_object";
};

export type DoubaoChatResult = {
  content: string;
  model: string;
  finishReason: string | null;
  usage?: {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
  };
};

export type DoubaoJsonRequest = DoubaoChatRequest & {
  // 给模型的 JSON 结构约束说明（自然语言或字段约定）
  jsonSchemaHint?: string;
};

export type DoubaoJsonResult<T> = {
  data: T;
  raw: string;
  model: string;
  finishReason: string | null;
  usage?: DoubaoChatResult["usage"];
};

type ArkChatChoice = {
  index: number;
  finish_reason: string | null;
  message?: { role: string; content?: string | null };
  delta?: { content?: string | null };
};

type ArkChatResponse = {
  id: string;
  model: string;
  choices: ArkChatChoice[];
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
};

function getApiUrl(): string {
  return `${config.doubao.baseUrl.replace(/\/$/, "")}/chat/completions`;
}

function getHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.doubao.k}`,
  };
}

function normalizeMessages(messages: DoubaoMessage[]): DoubaoMessage[] {
  return messages
    .map((message) => ({
      role: message.role,
      content: message.content.trim(),
    }))
    .filter((message) => message.content.length > 0);
}

function assertMessages(messages: DoubaoMessage[]): void {
  if (messages.length === 0) {
    throw new Error("doubao messages 不能为空");
  }
}

function toUsage(usage: ArkChatResponse["usage"]): DoubaoChatResult["usage"] {
  if (!usage) {
    return undefined;
  }
  return {
    promptTokens: usage.prompt_tokens,
    completionTokens: usage.completion_tokens,
    totalTokens: usage.total_tokens,
  };
}

function parseSseDataLine(line: string): string | null {
  if (!line.startsWith("data:")) {
    return null;
  }
  return line.slice(5).trim();
}

function extractJsonText(raw: string): string {
  const text = raw.trim();
  if (!text) {
    throw new Error("doubao JSON 输出为空");
  }

  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  if (fenced?.[1]) {
    return fenced[1].trim();
  }

  const firstBrace = text.indexOf("{");
  const lastBrace = text.lastIndexOf("}");
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return text.slice(firstBrace, lastBrace + 1).trim();
  }

  return text;
}

function parseJsonOrThrow<T>(raw: string): T {
  const normalized = extractJsonText(raw);
  try {
    return JSON.parse(normalized) as T;
  } catch (error) {
    throw new Error(
      `doubao JSON 解析失败: ${(error as Error).message}; raw=${raw.slice(0, 500)}`,
    );
  }
}

async function* parseArkSseStream(
  body: ReadableStream<Uint8Array>,
): AsyncGenerator<ArkChatResponse> {
  const decoder = new TextDecoder();
  const reader = body.getReader();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    buffer += decoder.decode(value, { stream: true });
    const blocks = buffer.split("\n\n");
    buffer = blocks.pop() ?? "";

    for (const block of blocks) {
      const lines = block
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean);

      for (const line of lines) {
        const data = parseSseDataLine(line);
        if (!data || data === "[DONE]") {
          continue;
        }
        yield JSON.parse(data) as ArkChatResponse;
      }
    }
  }
}

export class DoubaoService {
  static async chatCompletion(
    request: DoubaoChatRequest,
  ): Promise<DoubaoChatResult> {
    const startTime = Date.now();
    const messages = normalizeMessages(request.messages);
    assertMessages(messages);
    const modelName = config.doubao.model;
    const requestPayload: Record<string, unknown> = {
      model: modelName,
      messages,
      stream: false,
      temperature: request.temperature,
      max_tokens: request.maxTokens,
      response_format:
        request.responseFormat === "json_object"
          ? { type: "json_object" }
          : undefined,
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      config.doubao.timeoutMs,
    );

    try {
      const response = await fetch(getApiUrl(), {
        method: "POST",
        headers: getHeaders(),
        body: JSON.stringify(requestPayload),
        signal: controller.signal,
      });

      if (!response.ok) {
        const raw = await response.text();
        throw new Error(`doubao 请求失败(${response.status}): ${raw}`);
      }

      const data = (await response.json()) as ArkChatResponse;
      const first = data.choices?.[0];
      const content = first?.message?.content?.trim() ?? "";
      const result = {
        content,
        model: data.model ?? modelName,
        finishReason: first?.finish_reason ?? null,
        usage: toUsage(data.usage),
      };
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion",
        modelId: result.model,
        requestPayload,
        responsePayload: data as unknown as Record<string, unknown>,
        responseText: result.content,
        durationMs: Date.now() - startTime,
        success: true,
      });
      return result;
    } catch (error) {
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion",
        modelId: modelName,
        requestPayload,
        errorMessage: (error as Error).message,
        durationMs: Date.now() - startTime,
        success: false,
      });
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
  }

  static async *chatCompletionStream(
    request: DoubaoChatRequest,
  ): AsyncGenerator<string, DoubaoChatResult> {
    const startTime = Date.now();
    const messages = normalizeMessages(request.messages);
    assertMessages(messages);
    const modelName = config.doubao.model;
    const requestPayload: Record<string, unknown> = {
      model: modelName,
      messages,
      stream: true,
      temperature: request.temperature,
      max_tokens: request.maxTokens,
      response_format:
        request.responseFormat === "json_object"
          ? { type: "json_object" }
          : undefined,
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      config.doubao.timeoutMs,
    );

    let model = modelName;
    let finishReason: string | null = null;
    let usage: DoubaoChatResult["usage"];
    let fullText = "";

    try {
      const response = await fetch(getApiUrl(), {
        method: "POST",
        headers: getHeaders(),
        body: JSON.stringify(requestPayload),
        signal: controller.signal,
      });

      if (!response.ok) {
        const raw = await response.text();
        throw new Error(`doubao 流式请求失败(${response.status}): ${raw}`);
      }
      if (!response.body) {
        throw new Error("doubao 流式返回为空");
      }

      for await (const chunk of parseArkSseStream(response.body)) {
        model = chunk.model ?? model;
        if (chunk.usage) {
          usage = toUsage(chunk.usage);
        }

        const choice = chunk.choices?.[0];
        if (!choice) {
          continue;
        }
        if (choice.finish_reason) {
          finishReason = choice.finish_reason;
        }

        const delta = choice.delta?.content ?? "";
        if (!delta) {
          continue;
        }

        fullText += delta;
        yield delta;
      }

      const result = {
        content: fullText,
        model,
        finishReason,
        usage,
      };
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion_stream",
        modelId: result.model,
        requestPayload,
        responsePayload: {
          finishReason: result.finishReason,
          usage: result.usage,
        },
        responseText: result.content,
        durationMs: Date.now() - startTime,
        success: true,
      });
      return result;
    } catch (error) {
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion_stream",
        modelId: model,
        requestPayload,
        responseText: fullText,
        errorMessage: (error as Error).message,
        durationMs: Date.now() - startTime,
        success: false,
      });
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
  }

  static async jsonCompletion<T = Record<string, unknown>>(
    request: DoubaoJsonRequest,
  ): Promise<DoubaoJsonResult<T>> {
    const startTime = Date.now();
    const schemaHint = request.jsonSchemaHint?.trim();
    const systemRule = [
      "你必须仅返回一个合法 JSON 对象。",
      "不要输出任何额外说明、Markdown、代码块标记。",
      schemaHint ? `JSON 结构要求: ${schemaHint}` : "",
    ]
      .filter(Boolean)
      .join("\n");

    try {
      const result = await this.chatCompletion({
        ...request,
        responseFormat: "json_object",
        messages: [{ role: "system", content: systemRule }, ...request.messages],
      });

      const data = parseJsonOrThrow<T>(result.content);
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion_json",
        modelId: result.model,
        requestPayload: {
          ...request,
          jsonSchemaHint: request.jsonSchemaHint,
        } as unknown as Record<string, unknown>,
        responsePayload: data as unknown as Record<string, unknown>,
        responseText: result.content,
        durationMs: Date.now() - startTime,
        success: true,
      });
      return {
        data,
        raw: result.content,
        model: result.model,
        finishReason: result.finishReason,
        usage: result.usage,
      };
    } catch (error) {
      await DoubaoCallLog.writeLog({
        apiType: "chat_completion_json",
        modelId: config.doubao.model,
        requestPayload: request as unknown as Record<string, unknown>,
        errorMessage: (error as Error).message,
        durationMs: Date.now() - startTime,
        success: false,
      });
      throw error;
    }
  }
}
