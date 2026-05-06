import { afterEach, describe, expect, test } from "bun:test";
import { DoubaoService } from "../services/doubaoService";
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

function sseResponse(events: string[]): Response {
  const body = events.map((event) => `data: ${event}\n\n`).join("");
  return new Response(body, {
    status: 200,
    headers: { "Content-Type": "text/event-stream" },
  });
}

afterEach(() => {
  globalThis.fetch = originalFetch;
  DoubaoCallLog.writeLog = originalWriteLog;
  callLogs.length = 0;
});

describe("DoubaoService", () => {
  test("chatCompletion should return non-stream text result", async () => {
    DoubaoCallLog.writeLog = (async (entry: DoubaoCallLogEntry) => {
      callLogs.push(entry);
    }) as typeof DoubaoCallLog.writeLog;
    globalThis.fetch = (async (_input: RequestInfo | URL, _init?: RequestInit) =>
      jsonResponse({
        model: "doubao-seed-2-0-mini",
        choices: [
          {
            index: 0,
            finish_reason: "stop",
            message: { role: "assistant", content: "你好，我在。" },
          },
        ],
        usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
      })) as unknown as typeof fetch;

    const result = await DoubaoService.chatCompletion({
      messages: [{ role: "user", content: "你好" }],
    });

    expect(result.content).toBe("你好，我在。");
    expect(result.finishReason).toBe("stop");
    expect(result.usage?.totalTokens).toBe(15);
    expect(callLogs.length).toBe(1);
    expect(callLogs[0]?.apiType).toBe("chat_completion");
    expect(callLogs[0]?.success).toBe(true);
  });

  test("chatCompletionStream should stream deltas and return final aggregate", async () => {
    DoubaoCallLog.writeLog = (async (entry: DoubaoCallLogEntry) => {
      callLogs.push(entry);
    }) as typeof DoubaoCallLog.writeLog;
    globalThis.fetch = (async (_input: RequestInfo | URL, _init?: RequestInit) =>
      sseResponse([
        JSON.stringify({
          model: "doubao-seed-2-0-mini",
          choices: [{ index: 0, finish_reason: null, delta: { content: "你" } }],
        }),
        JSON.stringify({
          model: "doubao-seed-2-0-mini",
          choices: [{ index: 0, finish_reason: null, delta: { content: "好" } }],
        }),
        JSON.stringify({
          model: "doubao-seed-2-0-mini",
          choices: [{ index: 0, finish_reason: "stop", delta: {} }],
          usage: { prompt_tokens: 4, completion_tokens: 2, total_tokens: 6 },
        }),
        "[DONE]",
      ])) as unknown as typeof fetch;

    const stream = DoubaoService.chatCompletionStream({
      messages: [{ role: "user", content: "问候" }],
    });
    const pieces: string[] = [];

    while (true) {
      const next = await stream.next();
      if (next.done) {
        expect(pieces.join("")).toBe("你好");
        expect(next.value.content).toBe("你好");
        expect(next.value.finishReason).toBe("stop");
        expect(next.value.usage?.totalTokens).toBe(6);
        expect(callLogs.length).toBe(1);
        expect(callLogs[0]?.apiType).toBe("chat_completion_stream");
        expect(callLogs[0]?.responseText).toBe("你好");
        break;
      }
      pieces.push(next.value);
    }
  });

  test("jsonCompletion should parse json object payload", async () => {
    DoubaoCallLog.writeLog = (async (entry: DoubaoCallLogEntry) => {
      callLogs.push(entry);
    }) as typeof DoubaoCallLog.writeLog;
    globalThis.fetch = (async (_input: RequestInfo | URL, _init?: RequestInit) =>
      jsonResponse({
        model: "doubao-seed-2-0-mini",
        choices: [
          {
            index: 0,
            finish_reason: "stop",
            message: {
              role: "assistant",
              content: '{"intent":"kb_search","keywords":["净化器","滤芯"]}',
            },
          },
        ],
      })) as unknown as typeof fetch;

    const result = await DoubaoService.jsonCompletion<{
      intent: string;
      keywords: string[];
    }>({
      messages: [{ role: "user", content: "分析用户要查什么" }],
      jsonSchemaHint: "必须包含 intent(string) 和 keywords(string[])",
    });

    expect(result.data.intent).toBe("kb_search");
    expect(result.data.keywords).toEqual(["净化器", "滤芯"]);
    expect(callLogs.some((item) => item.apiType === "chat_completion")).toBe(true);
    expect(callLogs.some((item) => item.apiType === "chat_completion_json")).toBe(
      true,
    );
  });
});
