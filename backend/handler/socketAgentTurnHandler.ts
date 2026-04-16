import { AgentRoute } from "../agentRoute/AgentRoute";
import type { ClientTurnRequest } from "../agentRoute/protocol";
import {
  AGENT_ROUTE_PROTOCOL_VERSION,
} from "../agentRoute/protocol";
import type { SocketHandlerContext, SocketHandlerResult } from "./socketTypes";
import { SocketError } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

const agentRouteRuntime = new AgentRoute();

export class AgentSocketHandler {
  static async turn(context: SocketHandlerContext): Promise<SocketHandlerResult> {
    const user = context.getUser();
    if (!user?.id) {
      return new SocketError("UNAUTHORIZED", "unauthorized");
    }

    const payloadSource =
      asRecord(context.message.payload) ?? asRecord(context.message.data);
    if (!payloadSource) {
      return new SocketError("AGENT_TURN_PAYLOAD_REQUIRED", "agent_turn payload required");
    }

    const turnRequest = normalizeClientTurnRequest(payloadSource);
    if (!turnRequest) {
      return new SocketError("AGENT_TURN_PAYLOAD_INVALID", "invalid agent_turn payload");
    }

    try {
      return await agentRouteRuntime.handle(turnRequest);
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      return new SocketError("AGENT_TURN_INTERNAL_ERROR", detail);
    }
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
