import { CommonHandler } from "../handler/commonHandler";
import { AgentHandler } from "../handler/agentHandler";
import type {
  SocketBusinessData,
  SocketBusinessPayload,
  SocketHandlerResult,
  SocketMessage,
  SocketMessageHandler,
} from "../handler/socketTypes";
import { SocketError } from "../handler/socketTypes";
import type { AuthUser } from "../config/config";

type HandleSocketMessageArgs = {
  raw: string | Buffer;
  send: (payload: unknown) => void;
  getUser: () => AuthUser | null;
};

const SOCKET_OK_CODE = 0;
const RPC_TYPE = "rpc";

const routes: Record<string, SocketMessageHandler> = {
  "common.ping": CommonHandler.ping,
  "common.echo": CommonHandler.echo,
  "agent.turn": AgentHandler.turn,
};

export async function handleSocketMessage(
  args: HandleSocketMessageArgs,
): Promise<void> {
  const { raw, send, getUser } = args;
  const text = typeof raw === "string" ? raw : raw.toString();
  console.log(`[ws][inbound][raw] ${text}`);

  let message: SocketMessage;
  try {
    message = JSON.parse(text) as SocketMessage;
  } catch {
    send({ type: "error", error: "Invalid JSON message" });
    return;
  }

  const routeKey = getRouteKey(message);
  if (routeKey) {
    const payload = asRecord(message.payload) ?? asRecord(message.data) ?? {};
    const textPreview =
      typeof payload.text === "string" ? payload.text.slice(0, 80) : "";
    console.log(
      `[ws][rpc] route=${routeKey} req=${message.requestId ?? "-"} user=${getUser()?.id ?? "-"} text="${textPreview}"`,
    );
  }

  const handler = routeKey ? routes[routeKey] : undefined;
  if (!handler) {
    send(
      buildRpcResponse(
        message.requestId,
        new SocketError("RPC_METHOD_NOT_FOUND", "Unknown rpc method"),
      ),
    );
    return;
  }

  let result: SocketHandlerResult;
  try {
    result = await handler({
      message,
      getUser,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    result = new SocketError("INTERNAL_ERROR", detail);
  }

  const responsePayload = buildRpcResponse(resolveRequestId(message, result), result);
  console.log(`[ws][outbound][raw] ${safeJson(responsePayload)}`);
  send(responsePayload);
  logRpcResult(message, routeKey, result);
}

function buildRpcResponse(
  requestId: string | undefined,
  result: SocketHandlerResult,
): Record<string, unknown> {
  return {
    type: RPC_TYPE,
    requestId,
    payload: buildBusinessPayload(result),
  };
}

function buildBusinessPayload(result: SocketHandlerResult): SocketBusinessPayload {
  if (isSocketError(result)) {
    return {
      code: result.code,
      msg: result.msg,
    };
  }

  return {
    code: SOCKET_OK_CODE,
    data: result as SocketBusinessData,
  };
}

function isSocketError(result: SocketHandlerResult): result is SocketError {
  return result instanceof SocketError;
}

function getRouteKey(message: SocketMessage): string | null {
  if (message.type !== RPC_TYPE) {
    return null;
  }

  if (typeof message.method === "string" && message.method.trim().length > 0) {
    return message.method.trim();
  }
  return null;
}

function resolveRequestId(
  message: SocketMessage,
  result: SocketHandlerResult,
): string | undefined {
  if (message.requestId) {
    return message.requestId;
  }
  if (isSocketError(result)) {
    return undefined;
  }
  return typeof result.messageId === "string" ? result.messageId : undefined;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

function safeJson(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch (error) {
    return `{"serializationError":"${error instanceof Error ? error.message : String(error)}"}`;
  }
}

function logRpcResult(
  message: SocketMessage,
  routeKey: string | null,
  result: SocketHandlerResult,
): void {
  if (!routeKey) {
    return;
  }
  const req = message.requestId ?? "-";
  if (isSocketError(result)) {
    console.log(`[ws][rpc] route=${routeKey} req=${req} error=${result.code} msg=${result.msg}`);
    return;
  }
  const phase = typeof result.phase === "string" ? result.phase : "-";
  const sid = typeof result.sessionId === "string" ? result.sessionId : "-";
  const ver = typeof result.sessionVersion === "number" ? String(result.sessionVersion) : "-";
  console.log(`[ws][rpc] route=${routeKey} req=${req} ok phase=${phase} sid=${sid} ver=${ver}`);

  const protocol = asRecord(result.protocol);
  if (protocol) {
    const recommendedInput = typeof protocol.recommendedInput === "string" ? protocol.recommendedInput : "-";
    const directives = Array.isArray(protocol.directives) ? protocol.directives : [];
    const directiveTypes = directives
      .map((item) => asRecord(item))
      .filter((item): item is Record<string, unknown> => Boolean(item))
      .map((item) => (typeof item.type === "string" ? item.type : "unknown"))
      .join(",");
    console.log(
      `[ws][rpc][protocol] route=${routeKey} req=${req} recommendedInput=${recommendedInput} directives=${directiveTypes}`,
    );
  }
}
