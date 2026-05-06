import { config } from "../config/config";
import { DoubaoCallLog } from "../models/DoubaoCallLog";

export type DoubaoEmbeddingRequest = {
  input: string | string[];
  user?: string;
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

export class DoubaoEmbaddingService {
  static async createEmbedding(
    request: DoubaoEmbeddingRequest,
  ): Promise<DoubaoEmbeddingResult> {
    const startTime = Date.now();
    const modelName = config.doubao.embeddingModel;
    const requestPayload: Record<string, unknown> = {
      model: modelName,
      input: normalizeInput(request.input),
      user: request.user,
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
        throw new Error(`doubao embedding 请求失败(${response.status}): ${raw}`);
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
        requestPayload,
        responsePayload: data as unknown as Record<string, unknown>,
        durationMs: Date.now() - startTime,
        success: true,
      });
      return result;
    } catch (error) {
      await DoubaoCallLog.writeLog({
        apiType: "embedding",
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

  static async embedText(text: string): Promise<number[]> {
    const result = await this.createEmbedding({ input: text });
    const first = result.vectors[0]?.embedding;
    if (!first || first.length === 0) {
      throw new Error("doubao embedding 返回空向量");
    }
    return first;
  }
}
