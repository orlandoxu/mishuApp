import { AgentRoute } from "../agentRoute/AgentRoute";
import {
  AGENT_ROUTE_PROTOCOL_VERSION,
  type ClientTurnRequest,
} from "../agentRoute/protocol";
import type { SocketHandlerContext } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

const agentRouteRuntime = new AgentRoute();

export async function handleAgentTurn(
  context: SocketHandlerContext,
): Promise<void> {
  const user = context.getUser();
  if (!user?.id) {
    context.send({
      type: "error",
      requestId: context.message.requestId,
      error: "unauthorized",
    });
    return;
  }

  const payloadSource =
    asRecord(context.message.payload) ?? asRecord(context.message.data);
  if (!payloadSource) {
    context.send({
      type: "error",
      requestId: context.message.requestId,
      error: "agent_turn payload required",
    });
    return;
  }

  const turnRequest = normalizeClientTurnRequest(payloadSource);
  if (!turnRequest) {
    context.send({
      type: "error",
      requestId: context.message.requestId,
      error: "invalid agent_turn payload",
    });
    return;
  }

  try {
    const response = await agentRouteRuntime.handle(turnRequest);
    context.send({
      type: "agent_turn_result",
      requestId: context.message.requestId ?? turnRequest.messageId,
      payload: response,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    context.send({
      type: "agent_turn_result",
      requestId: context.message.requestId ?? turnRequest.messageId,
      payload: {
        sessionId: turnRequest.sessionId,
        sessionVersion: turnRequest.clientSessionVersion ?? 0,
        turnId: turnRequest.turnId,
        messageId: turnRequest.messageId,
        route: "fallback",
        phase: "failed",
        message: "服务端执行失败，请稍后重试。",
        missingSlots: [],
        filledSlots: {},
        executable: false,
        needsUserInput: false,
        uiHints: {
          display: "error",
          allowCancel: false,
        },
        presentation: {
          template: "error_banner",
          blocks: [{ type: "status_chip", status: "error", text: detail }],
        },
        actions: [{ type: "none" }],
        error: {
          code: "AGENT_TURN_INTERNAL_ERROR",
          message: detail,
          retryable: true,
        },
        protocol: {
          version: AGENT_ROUTE_PROTOCOL_VERSION,
          recommendedInput: "user_text",
          directives: [
            {
              type: "failed",
              code: "AGENT_TURN_INTERNAL_ERROR",
              message: detail,
              retryable: true,
            },
          ],
        },
      },
    });
  }
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

function readString(
  record: Record<string, unknown>,
  key: string,
): string | null {
  const value = record[key];
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeClientTurnRequest(
  payload: Record<string, unknown>,
): ClientTurnRequest | null {
  const sessionId = readString(payload, "sessionId");
  const turnId = readString(payload, "turnId");
  const messageId = readString(payload, "messageId");
  const text = readString(payload, "text");

  if (!sessionId || !turnId || !messageId || !text) {
    return null;
  }

  const interaction = payload.interaction;
  const history = payload.history;
  const clientContext = payload.clientContext;
  const timestamp = payload.timestamp;
  const clientSessionVersion = payload.clientSessionVersion;
  const protocolVersion =
    readString(payload, "protocolVersion") ?? AGENT_ROUTE_PROTOCOL_VERSION;

  const request: ClientTurnRequest = {
    protocolVersion,
    sessionId,
    turnId,
    messageId,
    text,
  };

  if (interaction && typeof interaction === "object") {
    request.interaction = interaction as ClientTurnRequest["interaction"];
  }
  if (Array.isArray(history)) {
    request.history = history as ClientTurnRequest["history"];
  }
  if (clientContext && typeof clientContext === "object") {
    request.clientContext = clientContext as ClientTurnRequest["clientContext"];
  }
  if (typeof timestamp === "number" && Number.isFinite(timestamp)) {
    request.timestamp = Math.floor(timestamp);
  }
  if (
    typeof clientSessionVersion === "number" &&
    Number.isFinite(clientSessionVersion)
  ) {
    request.clientSessionVersion = Math.floor(clientSessionVersion);
  }

  return request;
}
