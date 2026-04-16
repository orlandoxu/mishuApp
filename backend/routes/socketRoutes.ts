import { UserHandler } from "../handler/userHandler";
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
  setUser: (user: AuthUser) => void;
  ensureUserByToken: (token: string) => Promise<AuthUser | null>;
};

const SOCKET_OK_CODE = 0;
const RPC_TYPE = "rpc";

const routes: Record<string, SocketMessageHandler> = {
  "user.login": UserHandler.login,
  "common.ping": CommonHandler.ping,
  "common.echo": CommonHandler.echo,
  "agent.turn": AgentHandler.turn,
};

export async function handleSocketMessage(
  args: HandleSocketMessageArgs,
): Promise<void> {
  const { raw, send, getUser, setUser, ensureUserByToken } = args;
  const text = typeof raw === "string" ? raw : raw.toString();

  let message: SocketMessage;
  try {
    message = JSON.parse(text) as SocketMessage;
  } catch {
    send({ type: "error", error: "Invalid JSON message" });
    return;
  }

  const routeKey = getRouteKey(message);
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
      setUser,
      ensureUserByToken,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    result = new SocketError("INTERNAL_ERROR", detail);
  }

  send(buildRpcResponse(resolveRequestId(message, result), result));
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
