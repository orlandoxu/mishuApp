import type { SocketHandlerContext, SocketHandlerResult } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

export class CommonSocketHandler {
  static async ping(_context: SocketHandlerContext): Promise<SocketHandlerResult> {
    return {
      ts: Date.now(),
    };
  }

  static async echo(context: SocketHandlerContext): Promise<SocketHandlerResult> {
    return {
      data: context.message.data,
    };
  }
}
