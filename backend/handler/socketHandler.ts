export type SocketMessage = {
  type: string;
  requestId?: string;
  token?: string;
  data?: unknown;
  [key: string]: unknown;
};

type SocketUser = {
  id: string;
  realName: string;
};

type HandleSocketMessageArgs = {
  raw: string | Buffer;
  send: (payload: unknown) => void;
  setUserId: (userId: string) => void;
  ensureUserByToken: (token: string) => Promise<SocketUser | null>;
};

export async function handleSocketMessage(args: HandleSocketMessageArgs): Promise<void> {
  const { raw, send, setUserId, ensureUserByToken } = args;
  const text = typeof raw === 'string' ? raw : raw.toString();

  let message: SocketMessage;
  try {
    message = JSON.parse(text) as SocketMessage;
  } catch {
    send({ type: 'error', error: 'Invalid JSON message' });
    return;
  }

  switch (message.type) {
    case 'login': {
      const token = typeof message.token === 'string' ? message.token : '';
      if (!token) {
        send({ type: 'loginFail', requestId: message.requestId, error: 'token required' });
        return;
      }

      const user = await ensureUserByToken(token);
      if (!user?.id) {
        send({ type: 'loginFail', requestId: message.requestId, error: 'invalid token' });
        return;
      }

      setUserId(user.id);
      send({
        type: 'loginSuccess',
        requestId: message.requestId,
        userId: user.id,
        realName: user.realName,
      });
      return;
    }
    case 'ping':
      send({ type: 'pong', requestId: message.requestId, ts: Date.now() });
      return;
    case 'echo':
      send({ type: 'echoResponse', requestId: message.requestId, data: message.data });
      return;
    default:
      send({ type: 'error', requestId: message.requestId, error: 'Unknown message type' });
  }
}
