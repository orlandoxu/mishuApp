import fs from "node:fs";
import { X509Certificate } from "node:crypto";

import { config } from "../config/config";
import { UserTokenService } from "../service/userTokenService";
import type { SocketMessage } from "./socketTypes";
import { wsRuntimeState } from "./runtimeState";

type SocketData = {
  userId?: string;
};

export async function bootstrapWebSocketServices(): Promise<void> {
  startWsServer();
  startWssServer();
}

function startWsServer(): void {
  if (!config.ws.wsEnabled) {
    wsRuntimeState.ws = "disabled";
    return;
  }

  Bun.serve<SocketData>({
    hostname: config.ws.wsHost,
    port: config.ws.wsPort,
    fetch(req, server) {
      if (new URL(req.url).pathname !== config.ws.path) {
        return new Response("Not Found", { status: 404 });
      }

      if (server.upgrade(req, { data: {} })) {
        return undefined;
      }

      return new Response("Upgrade failed", { status: 400 });
    },
    websocket: {
      open(ws) {
        wsRuntimeState.wsClients += 1;
        ws.send(
          JSON.stringify({ type: "connected", mode: "ws", ts: Date.now() }),
        );
      },
      async message(ws, raw) {
        await handleMessage(ws, raw);
      },
      close() {
        wsRuntimeState.wsClients = Math.max(0, wsRuntimeState.wsClients - 1);
      },
    },
  });

  wsRuntimeState.ws = "up";
  console.log(
    `[ws] ready at ws://${config.ws.wsHost}:${config.ws.wsPort}${config.ws.path}`,
  );
}

function startWssServer(): void {
  if (!config.ws.wssEnabled) {
    wsRuntimeState.wss = "disabled";
    return;
  }

  try {
    const key = fs.readFileSync(config.ws.wssKeyPath, "utf8");
    const cert = fs.readFileSync(config.ws.wssCertPath, "utf8");

    const certInfo = new X509Certificate(cert);
    wsRuntimeState.wssCertNotAfter = certInfo.validTo;
    if (new Date(certInfo.validTo).getTime() < Date.now()) {
      console.warn(
        `[wss] cert expired at ${certInfo.validTo}. Please replace certificate files.`,
      );
    }

    Bun.serve<SocketData>({
      hostname: config.ws.wssHost,
      port: config.ws.wssPort,
      tls: {
        key,
        cert,
      },
      fetch(req, server) {
        if (new URL(req.url).pathname !== config.ws.path) {
          return new Response("Not Found", { status: 404 });
        }

        if (server.upgrade(req, { data: {} })) {
          return undefined;
        }

        return new Response("Upgrade failed", { status: 400 });
      },
      websocket: {
        open(ws) {
          wsRuntimeState.wssClients += 1;
          ws.send(
            JSON.stringify({ type: "connected", mode: "wss", ts: Date.now() }),
          );
        },
        async message(ws, raw) {
          await handleMessage(ws, raw);
        },
        close() {
          wsRuntimeState.wssClients = Math.max(
            0,
            wsRuntimeState.wssClients - 1,
          );
        },
      },
    });

    wsRuntimeState.wss = "up";
    console.log(
      `[wss] ready at wss://${config.ws.wssHost}:${config.ws.wssPort}${config.ws.path}`,
    );
  } catch (error) {
    wsRuntimeState.wss = "down";
    wsRuntimeState.wssError =
      error instanceof Error ? error.message : String(error);
    console.error("[wss] startup failed", error);
  }
}

async function handleMessage(
  ws: Bun.ServerWebSocket<SocketData>,
  raw: string | Buffer,
): Promise<void> {
  const text = typeof raw === "string" ? raw : raw.toString();
  let message: SocketMessage;

  try {
    message = JSON.parse(text) as SocketMessage;
  } catch {
    ws.send(JSON.stringify({ type: "error", error: "Invalid JSON message" }));
    return;
  }

  switch (message.type) {
    case "login": {
      const token = typeof message.token === "string" ? message.token : "";
      if (!token) {
        ws.send(
          JSON.stringify({
            type: "loginFail",
            requestId: message.requestId,
            error: "token required",
          }),
        );
        return;
      }

      const user = await UserTokenService.ensureLastUserRedis(token);
      if (!user?.id) {
        ws.send(
          JSON.stringify({
            type: "loginFail",
            requestId: message.requestId,
            error: "invalid token",
          }),
        );
        return;
      }

      ws.data.userId = user.id;
      ws.send(
        JSON.stringify({
          type: "loginSuccess",
          requestId: message.requestId,
          userId: user.id,
          realName: user.realName,
        }),
      );
      return;
    }
    case "ping":
      ws.send(
        JSON.stringify({
          type: "pong",
          requestId: message.requestId,
          ts: Date.now(),
        }),
      );
      return;
    case "echo":
      ws.send(
        JSON.stringify({
          type: "echoResponse",
          requestId: message.requestId,
          data: message.data,
        }),
      );
      return;
    default:
      ws.send(
        JSON.stringify({
          type: "error",
          requestId: message.requestId,
          error: "Unknown message type",
        }),
      );
  }
}
