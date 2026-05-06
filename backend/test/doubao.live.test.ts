import { describe, expect, test } from "bun:test";
import { DoubaoService } from "../services/doubaoService";
import { DoubaoEmbaddingService } from "../services/doubaoEmbadding";

const runLive = process.env.RUN_DOUBAO_LIVE_TEST === "1";
const testIfLive = runLive ? test : test.skip;
const runEmbeddingLive =
  runLive && Boolean(process.env.BACKEND_DOUBAO_EMBEDDING_MODEL);
const testIfEmbeddingLive = runEmbeddingLive ? test : test.skip;

describe("Doubao live integration", () => {
  testIfLive(
    "chatCompletion should call real doubao service",
    async () => {
      const result = await DoubaoService.chatCompletion({
        messages: [{ role: "user", content: "请只回复：OK" }],
        temperature: 0,
      });

      expect(typeof result.content).toBe("string");
      expect(result.content.length).toBeGreaterThan(0);
      expect(typeof result.model).toBe("string");
    },
    30_000,
  );

  testIfLive(
    "jsonCompletion should return real parsable JSON",
    async () => {
      const result = await DoubaoService.jsonCompletion<{
        intent: string;
        score: number;
      }>({
        messages: [{ role: "user", content: "返回一个最简意图识别JSON" }],
        jsonSchemaHint: "必须包含 intent(string) 与 score(number,0到1)",
        temperature: 0,
      });

      expect(typeof result.data.intent).toBe("string");
      expect(typeof result.data.score).toBe("number");
    },
    60_000,
  );

  testIfEmbeddingLive(
    "createEmbedding should call real embedding model",
    async () => {
      const result = await DoubaoEmbaddingService.createEmbedding({
        input: "空气净化器滤芯多久更换",
      });

      expect(result.vectors.length).toBeGreaterThan(0);
      expect(result.vectors[0]?.embedding.length ?? 0).toBeGreaterThan(0);
      expect(typeof result.model).toBe("string");
    },
    30_000,
  );
});
