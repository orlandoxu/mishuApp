import { AgentRoute } from "../agentRoute/AgentRoute";
import { IntentRouterService } from "../agentRoute/intentRouterService";
import type { ClientTurnRequest } from "../agentRoute/protocol";
import {
  AGENT_ROUTE_PROTOCOL_VERSION,
} from "../agentRoute/protocol";
import { buildPresentation } from "../agentRoute/protocol/directiveBuilder";
import { createInitialSessionState } from "../agentRoute/sessionState";
import type { SocketHandlerContext, SocketHandlerResult } from "./socketTypes";
import { SocketError } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

const agentRouteRuntime = new AgentRoute();
const intentRouter = new IntentRouterService();

export class AgentHandler {
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
    turnRequest.clientContext = {
      ...(turnRequest.clientContext ?? {}),
      userId: user.id,
    };

    if (await shouldUseTwoPhaseFoodReply(turnRequest)) {
      void processFoodTurnAsync(turnRequest, context);
      return buildImmediateFoodAck(turnRequest);
    }

    try {
      return await agentRouteRuntime.handle(turnRequest);
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      return new SocketError("AGENT_TURN_INTERNAL_ERROR", detail);
    }
  }
}

async function shouldUseTwoPhaseFoodReply(request: ClientTurnRequest): Promise<boolean> {
  if (request.interaction) return false;
  const probeState = createInitialSessionState(request.sessionId, request.timestamp ?? Date.now());
  const llmIntent = await intentRouter.detect(request, probeState);
  return llmIntent?.domain === "food" && llmIntent.intent === "food.create" && llmIntent.confidence >= 0.6;
}

function buildImmediateFoodAck(request: ClientTurnRequest): SocketHandlerResult {
  const message = "好呀！告诉我餐厅的名字、人均消费、特色菜，点评一下呗。我会帮你记录下来的哦。";
  return {
    sessionId: request.sessionId,
    sessionVersion: request.clientSessionVersion ?? 0,
    turnId: request.turnId,
    messageId: request.messageId,
    route: "food",
    phase: "executing",
    message,
    missingSlots: [],
    filledSlots: {},
    executable: false,
    needsUserInput: false,
    uiHints: {
      display: "loading",
      allowCancel: true,
    },
    presentation: buildPresentation({
      phase: "executing",
      message,
      filledSlots: {},
    }),
    actions: [{ type: "none" }],
    protocol: {
      version: AGENT_ROUTE_PROTOCOL_VERSION,
      recommendedInput: "none",
      directives: [
        { type: "assistant_message", text: message },
        { type: "execution_status", status: "executing", actionLabel: "food.create" },
      ],
    },
  };
}

async function processFoodTurnAsync(
  turnRequest: ClientTurnRequest,
  context: SocketHandlerContext,
): Promise<void> {
  try {
    const result = await agentRouteRuntime.handle(turnRequest);
    context.emit({
      type: "agent_turn_update",
      payload: {
        targetMessageId: turnRequest.messageId,
        status: result.phase,
        ...result,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    context.emit({
      type: "agent_turn_update",
      payload: {
        targetMessageId: turnRequest.messageId,
        status: "failed",
        sessionId: turnRequest.sessionId,
        sessionVersion: turnRequest.clientSessionVersion ?? 0,
        turnId: turnRequest.turnId,
        messageId: turnRequest.messageId,
        phase: "failed",
        message: `本次解析失败了，我们继续来：请告诉我店名、人均消费和点评。我会继续帮你记。(${message})`,
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
