import { handleSocketLogin } from "../handler/socketAuthHandler";
import {
  handleSocketPing,
  handleSocketEcho,
} from "../handler/socketCommonHandler";
import { handleAgentTurn } from "../handler/socketAgentTurnHandler";
import type { SocketMessage } from "../handler/socketTypes";
import type { AuthUser } from "../config/config";

type HandleSocketMessageArgs = {
  raw: string | Buffer;
  send: (payload: unknown) => void;
  getUser: () => AuthUser | null;
  setUser: (user: AuthUser) => void;
  ensureUserByToken: (token: string) => Promise<AuthUser | null>;
};

type Handler = (args: {
  message: SocketMessage;
  send: (payload: unknown) => void;
  getUser: () => AuthUser | null;
  setUser: (user: AuthUser) => void;
  ensureUserByToken: (token: string) => Promise<AuthUser | null>;
}) => Promise<void>;

// 这儿才是指令对应的路由函数
const handlers: Record<string, Handler> = {
  login: handleSocketLogin,
  ping: handleSocketPing,
  echo: handleSocketEcho,
  agent_turn: handleAgentTurn,
};

// 下面是分发逻辑
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

  const handler = handlers[message.type];
  if (!handler) {
    send({
      type: "error",
      requestId: message.requestId,
      error: "Unknown message type",
    });
    return;
  }

  await handler({
    message,
    send,
    getUser,
    setUser,
    ensureUserByToken,
  });
}
