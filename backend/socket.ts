import { config } from "./config/config";
import { UserTokenService } from "./services/userTokenService";
import { handleSocketMessage } from "./routes/socketRoutes";
import type { AuthUser } from "./config/config";

export type WsStatus = "up" | "down" | "disabled";

export const wsRuntimeState: {
  ws: WsStatus;
  wsClients: number;
} = {
  ws: "down",
  wsClients: 0,
};

type SocketData = {
  user?: AuthUser | null;
};

export async function bootstrapWebSocketServices(): Promise<void> {
  startWsServer();
}

function startWsServer(): void {
  if (!config.ws.wsEnabled) {
    wsRuntimeState.ws = "disabled";
    return;
  }

  Bun.serve<SocketData>({
    hostname: config.ws.wsHost,
    port: config.ws.wsPort,
    async fetch(req, server) {
      const url = new URL(req.url);
      if (url.pathname !== config.ws.path) {
        return new Response("Not Found", { status: 404 });
      }

      const headerToken = req.headers.get("authorization");
      const queryToken = url.searchParams.get("token");
      const token = headerToken ?? queryToken;
      let user: AuthUser | null = null;

      if (token) {
        user = await UserTokenService.ensureUserByToken(token);
        if (!user?.id) {
          return new Response("Unauthorized", { status: 401 });
        }
      }

      if (server.upgrade(req, { data: { user } })) {
        return undefined;
      }

      return new Response("Upgrade failed", { status: 400 });
    },
    websocket: {
      open(ws) {
        wsRuntimeState.wsClients += 1;
        ws.send(
          JSON.stringify({
            type: "connected",
            mode: "ws",
            ts: Date.now(),
            payload: {
              uid: ws.data.user?.id ?? "",
              devices: [],
            },
          }),
        );
      },
      async message(ws, raw) {
        await handleSocketMessage({
          raw,
          send(payload) {
            ws.send(JSON.stringify(payload));
          },
          getUser() {
            return ws.data.user ?? null;
          },
        });
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
if (import.meta.main) {
  bootstrapWebSocketServices().catch((error) => {
    console.error("socket startup failed", error);
    process.exit(1);
  });
}
