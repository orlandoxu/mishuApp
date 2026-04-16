import { UserSocketHandler } from "../handler/socketAuthHandler";
import { CommonSocketHandler } from "../handler/socketCommonHandler";
import { AgentSocketHandler } from "../handler/socketAgentTurnHandler";
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

type SocketRoute = {
  handler: SocketMessageHandler;
  successType: string;
  errorType?: string;
  requestIdOf?: (message: SocketMessage, result: SocketHandlerResult) => string | undefined;
};

const SOCKET_OK_CODE = 0;

const routesByDomain = {
  user: {
    login: {
      handler: UserSocketHandler.login,
      successType: "loginSuccess",
      errorType: "loginFail",
    },
  },
  common: {
    ping: {
      handler: CommonSocketHandler.ping,
      successType: "pong",
    },
    echo: {
      handler: CommonSocketHandler.echo,
      successType: "echoResponse",
    },
  },
  agent: {
    agent_turn: {
      handler: AgentSocketHandler.turn,
      successType: "agent_turn_result",
      requestIdOf(message: SocketMessage, result: SocketHandlerResult) {
        if (isSocketError(result)) {
          return message.requestId;
        }
        const fallbackRequestId =
          typeof result.messageId === "string" ? result.messageId : undefined;
        return message.requestId ?? fallbackRequestId;
      },
    },
  },
} as const;

const routes: Record<string, SocketRoute> = {
  ...routesByDomain.user,
  ...routesByDomain.common,
  ...routesByDomain.agent,
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

  const route = routes[message.type];
  if (!route) {
    send({
      type: "error",
      requestId: message.requestId,
      error: "Unknown message type",
    });
    return;
  }

  let result: SocketHandlerResult;
  try {
    result = await route.handler({
      message,
      getUser,
      setUser,
      ensureUserByToken,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    result = new SocketError("INTERNAL_ERROR", detail);
  }

  send(buildSocketResponse(route, message, result));
}

function buildSocketResponse(
  route: SocketRoute,
  message: SocketMessage,
  result: SocketHandlerResult,
): Record<string, unknown> {
  const requestId = route.requestIdOf?.(message, result) ?? message.requestId;
  return {
    type: isSocketError(result) ? (route.errorType ?? "error") : route.successType,
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
