import type { SocketHandlerContext } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

export async function handleSocketLogin(
  context: SocketHandlerContext,
): Promise<void> {
  const { message, send, setUser, ensureUserByToken } = context;
  const token = typeof message.token === "string" ? message.token : "";
  if (!token) {
    send({
      type: "loginFail",
      requestId: message.requestId,
      error: "token required",
    });
    return;
  }

  const user = await ensureUserByToken(token);
  if (!user?.id) {
    send({
      type: "loginFail",
      requestId: message.requestId,
      error: "invalid token",
    });
    return;
  }

  setUser(user);
  send({
    type: "loginSuccess",
    requestId: message.requestId,
    userId: user.id,
  });
}
