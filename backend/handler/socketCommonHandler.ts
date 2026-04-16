import type { SocketHandlerContext } from "./socketTypes";
// DONE-AI: 已按当前结构迁移到 handler，目录已扁平化。

export async function handleSocketPing(
  context: SocketHandlerContext,
): Promise<void> {
  context.send({
    type: "pong",
    requestId: context.message.requestId,
    ts: Date.now(),
  });
}

export async function handleSocketEcho(
  context: SocketHandlerContext,
): Promise<void> {
  context.send({
    type: "echoResponse",
    requestId: context.message.requestId,
    data: context.message.data,
  });
}
