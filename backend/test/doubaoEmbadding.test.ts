import { afterEach, describe, expect, test } from "bun:test";
import { DoubaoEmbaddingService } from "../services/doubaoEmbadding";
import { DoubaoCallLog, type DoubaoCallLogEntry } from "../models/DoubaoCallLog";

const originalFetch = globalThis.fetch;
const callLogs: DoubaoCallLogEntry[] = [];
const originalWriteLog = DoubaoCallLog.writeLog;

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

afterEach(() => {
  globalThis.fetch = originalFetch;
  DoubaoCallLog.writeLog = originalWriteLog;
  callLogs.length = 0;
});

describe("DoubaoEmbaddingService", () => {
  test("createEmbedding should call /embeddings and map vectors", async () => {
    DoubaoCallLog.writeLog = (async (entry: DoubaoCallLogEntry) => {
      callLogs.push(entry);
    }) as typeof DoubaoCallLog.writeLog;
    let capturedUrl = "";
    let capturedBody: Record<string, unknown> | undefined;

    globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
      capturedUrl = String(input);
      capturedBody = JSON.parse(String(init?.body ?? "{}")) as Record<
        string,
        unknown
      >;
      return jsonResponse({
        model: "doubao-embedding",
        data: [
          { index: 0, embedding: [0.1, 0.2] },
          { index: 1, embedding: [0.3, 0.4] },
        ],
        usage: { prompt_tokens: 12, total_tokens: 12 },
      });
    }) as unknown as typeof fetch;

    const result = await DoubaoEmbaddingService.createEmbedding({
      input: ["你好", "世界"],
      userId: "kb-user",
    });

    expect(capturedUrl.endsWith("/embeddings")).toBe(true);
    expect(capturedBody?.model).toBe("doubao-embedding");
    expect(capturedBody?.input).toEqual(["你好", "世界"]);
    expect(result.vectors.length).toBe(2);
    expect(result.vectors[0]?.embedding).toEqual([0.1, 0.2]);
    expect(result.usage?.totalTokens).toBe(12);
    expect(callLogs.length).toBe(1);
    expect(callLogs[0]?.apiType).toBe("embedding");
    expect(callLogs[0]?.success).toBe(true);
  });

  test("embedText should return first vector", async () => {
    DoubaoCallLog.writeLog = (async (entry: DoubaoCallLogEntry) => {
      callLogs.push(entry);
    }) as typeof DoubaoCallLog.writeLog;
    globalThis.fetch = (async (_input: RequestInfo | URL, _init?: RequestInit) =>
      jsonResponse({
        model: "doubao-embedding",
        data: [{ index: 0, embedding: [0.6, 0.7, 0.8] }],
      })) as unknown as typeof fetch;

    const vector = await DoubaoEmbaddingService.embedText("知识库搜索文本");
    expect(vector).toEqual([0.6, 0.7, 0.8]);
    expect(callLogs.length).toBe(1);
    expect(callLogs[0]?.apiType).toBe("embedding");
  });
});
