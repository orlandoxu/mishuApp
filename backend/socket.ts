import { config } from './config/config';
import { UserTokenService } from './service/userTokenService';
import { handleSocketMessage } from './handler/socketHandler';

export type WsStatus = 'up' | 'down' | 'disabled';

export const wsRuntimeState: {
  ws: WsStatus;
  wsClients: number;
} = {
  ws: 'down',
  wsClients: 0,
};

type SocketData = {
  userId?: string;
};

export async function bootstrapWebSocketServices(): Promise<void> {
  startWsServer();
}

function startWsServer(): void {
  if (!config.ws.wsEnabled) {
    wsRuntimeState.ws = 'disabled';
    return;
  }

  Bun.serve<SocketData>({
    hostname: config.ws.wsHost,
    port: config.ws.wsPort,
    fetch(req, server) {
      if (new URL(req.url).pathname !== config.ws.path) {
        return new Response('Not Found', { status: 404 });
      }

      if (server.upgrade(req, { data: {} })) {
        return undefined;
      }

      return new Response('Upgrade failed', { status: 400 });
    },
    websocket: {
      open(ws) {
        wsRuntimeState.wsClients += 1;
        ws.send(JSON.stringify({ type: 'connected', mode: 'ws', ts: Date.now() }));
      },
      async message(ws, raw) {
        await handleSocketMessage({
          raw,
          send(payload) {
            ws.send(JSON.stringify(payload));
          },
          setUserId(userId) {
            ws.data.userId = userId;
          },
          ensureUserByToken: UserTokenService.ensureLastUserRedis,
        });
      },
      close() {
        wsRuntimeState.wsClients = Math.max(0, wsRuntimeState.wsClients - 1);
      },
    },
  });

  wsRuntimeState.ws = 'up';
  console.log(`[ws] ready at ws://${config.ws.wsHost}:${config.ws.wsPort}${config.ws.path}`);
}
if (import.meta.main) {
  bootstrapWebSocketServices().catch((error) => {
    console.error('socket startup failed', error);
    process.exit(1);
  });
}
