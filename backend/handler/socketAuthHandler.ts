import type { SocketHandlerContext, SocketHandlerResult } from "./socketTypes";
import { SocketError } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

export class UserSocketHandler {
  static async login(context: SocketHandlerContext): Promise<SocketHandlerResult> {
    const { message, setUser, ensureUserByToken } = context;
    const token = typeof message.token === "string" ? message.token : "";
    if (!token) {
      return new SocketError("TOKEN_REQUIRED", "token required");
    }

    const user = await ensureUserByToken(token);
    if (!user?.id) {
      return new SocketError("INVALID_TOKEN", "invalid token");
    }

    setUser(user);
    return {
      userId: user.id,
    };
  }
}
