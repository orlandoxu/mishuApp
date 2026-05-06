import { config } from "../config/config";

export type DoubaoMessageRole = "system" | "user" | "assistant";

export type DoubaoMessage = {
  role: DoubaoMessageRole;
  content: string;
};

export type DoubaoChatRequest = {
  messages: DoubaoMessage[];
  temperature?: number;
  maxTokens?: number;
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
    const messages = normalizeMessages(request.messages);
    assertMessages(messages);

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      config.doubao.timeoutMs,
    );

    try {
      const response = await fetch(getApiUrl(), {
        method: "POST",
        headers: getHeaders(),
        body: JSON.stringify({
          model: config.doubao.model,
          messages,
          stream: false,
          temperature: request.temperature,
          max_tokens: request.maxTokens,
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const raw = await response.text();
        throw new Error(`doubao 请求失败(${response.status}): ${raw}`);
      }

      const data = (await response.json()) as ArkChatResponse;
      const first = data.choices?.[0];
      const content = first?.message?.content?.trim() ?? "";
      return {
        content,
        model: data.model ?? config.doubao.model,
        finishReason: first?.finish_reason ?? null,
        usage: toUsage(data.usage),
      };
    } finally {
      clearTimeout(timeoutId);
    }
  }

  static async *chatCompletionStream(
    request: DoubaoChatRequest,
  ): AsyncGenerator<string, DoubaoChatResult> {
    const messages = normalizeMessages(request.messages);
    assertMessages(messages);

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      config.doubao.timeoutMs,
    );

    let model = config.doubao.model;
    let finishReason: string | null = null;
    let usage: DoubaoChatResult["usage"];
    let fullText = "";

    try {
      const response = await fetch(getApiUrl(), {
        method: "POST",
        headers: getHeaders(),
        body: JSON.stringify({
          model: config.doubao.model,
          messages,
          stream: true,
          temperature: request.temperature,
          max_tokens: request.maxTokens,
        }),
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

      return {
        content: fullText,
        model,
        finishReason,
        usage,
      };
    } finally {
      clearTimeout(timeoutId);
    }
  }
}
