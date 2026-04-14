import WebSocket, { type RawData, WebSocketServer } from 'ws';
import { UserTokenService } from '../service/userTokenService';
import type { SocketMessage } from './socketTypes';

type Client = WebSocket & {
  userId?: string;
  isAlive?: boolean;
  sendJson?: (payload: unknown) => void;
};

export class SocketServer {
  private readonly clientsByUser = new Map<string, Client>();
  private heartbeatTimer?: ReturnType<typeof setInterval>;

  constructor(
    private readonly wss: WebSocketServer,
    private readonly mode: 'ws' | 'wss'
  ) {
    this.wss.on('connection', (client: WebSocket) => this.onConnection(client as Client));
    this.wss.on('close', () => this.stopHeartbeat());
    this.startHeartbeat();
  }

  getClientCount(): number {
    return this.wss.clients.size;
  }

  private onConnection(client: Client): void {
    client.isAlive = true;
    client.sendJson = (payload: unknown) => {
      client.send(JSON.stringify(payload));
    };

    client.on('pong', () => {
      client.isAlive = true;
    });

    client.on('message', async (data: RawData) => {
      await this.handleMessage(client, data.toString());
    });

    client.on('error', (error: Error) => {
      console.error(`[${this.mode}] websocket error`, error);
    });

    client.on('close', () => {
      if (client.userId && this.clientsByUser.get(client.userId) === client) {
        this.clientsByUser.delete(client.userId);
      }
    });

    client.sendJson({ type: 'connected', mode: this.mode, ts: Date.now() });
  }

  private async handleMessage(client: Client, rawMessage: string): Promise<void> {
    let message: SocketMessage;
    try {
      message = JSON.parse(rawMessage) as SocketMessage;
    } catch {
      client.sendJson?.({ type: 'error', error: 'Invalid JSON message' });
      return;
    }

    switch (message.type) {
      case 'login':
        await this.login(client, message);
        return;
      case 'ping':
        client.sendJson?.({ type: 'pong', requestId: message.requestId, ts: Date.now() });
        return;
      case 'echo':
        client.sendJson?.({ type: 'echoResponse', requestId: message.requestId, data: message.data });
        return;
      default:
        client.sendJson?.({ type: 'error', requestId: message.requestId, error: 'Unknown message type' });
    }
  }

  private async login(client: Client, message: SocketMessage): Promise<void> {
    const token = typeof message.token === 'string' ? message.token : '';
    if (!token) {
      client.sendJson?.({ type: 'loginFail', requestId: message.requestId, error: 'token required' });
      return;
    }

    const user = await UserTokenService.ensureLastUserRedis(token);
    if (!user?.id) {
      client.sendJson?.({ type: 'loginFail', requestId: message.requestId, error: 'invalid token' });
      return;
    }

    client.userId = user.id;
    this.clientsByUser.set(user.id, client);

    client.sendJson?.({
      type: 'loginSuccess',
      requestId: message.requestId,
      userId: user.id,
      realName: user.realName,
    });
  }

  private startHeartbeat(): void {
    this.heartbeatTimer = setInterval(() => {
      for (const socket of this.wss.clients) {
        const client = socket as Client;
        if (client.isAlive === false) {
          client.terminate();
          continue;
        }

        client.isAlive = false;
        client.ping();
      }
    }, 15_000);
  }

  private stopHeartbeat(): void {
    if (!this.heartbeatTimer) {
      return;
    }

    clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = undefined;
  }
}
