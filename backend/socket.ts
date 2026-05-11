import { config } from "./config/config";
import { UserTokenService } from "./services/userTokenService";
import { handleSocketMessage } from "./routes/socketRoutes";
import type { AuthUser } from "./config/config";
import { connectMongoDB } from "./utils/database";

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
  await connectMongoDB();
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
        if (!user?.id && config.app.nodeEnv !== "production") {
          user = decodeDevUserFromToken(token);
          if (user?.id) {
            console.log(`[ws] dev token fallback user=${user.id}`);
          }
        }
        if (!user?.id) {
          console.log("[ws] upgrade unauthorized");
          return new Response("Unauthorized", { status: 401 });
        }
      }

      if (server.upgrade(req, { data: { user } })) {
        console.log(`[ws] upgrade ok user=${user?.id ?? "-"}`);
        return undefined;
      }

      console.log("[ws] upgrade failed");
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

function decodeDevUserFromToken(rawToken: string): AuthUser | null {
  const token = rawToken.startsWith("Bearer ") ? rawToken.slice(7) : rawToken;
  const jwt = token.startsWith(config.auth.tokenPrefix) ? token.slice(config.auth.tokenPrefix.length) : token;
  const parts = jwt.split(".");
  if (parts.length < 2) {
    return null;
  }
  try {
    const payloadRaw = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = payloadRaw.padEnd(Math.ceil(payloadRaw.length / 4) * 4, "=");
    const payloadJson = Buffer.from(padded, "base64").toString("utf8");
    const payload = JSON.parse(payloadJson) as { sub?: unknown };
    if (typeof payload.sub === "string" && payload.sub.trim().length > 0) {
      return { id: payload.sub.trim() };
    }
  } catch {
    return null;
  }
  return null;
}
if (import.meta.main) {
  bootstrapWebSocketServices().catch((error) => {
    console.error("socket startup failed", error);
    process.exit(1);
  });
}
