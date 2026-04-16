import type { AuthUser } from '../config/config';

export type SocketMessage = {
  type: string;
  requestId?: string;
  token?: string;
  payload?: unknown;
  data?: unknown;
  [key: string]: unknown;
};

export type SocketHandlerContext = {
  message: SocketMessage;
  getUser: () => AuthUser | null;
  setUser: (user: AuthUser) => void;
  ensureUserByToken: (token: string) => Promise<AuthUser | null>;
};

export class SocketError {
  constructor(
    public readonly code: string,
    public readonly msg: string,
  ) {}
}

export type SocketBusinessData = Record<string, unknown>;

export type SocketHandlerResult = SocketError | SocketBusinessData;

export type SocketBusinessPayload = {
  code: string | number;
  msg?: string;
  data?: SocketBusinessData;
};

export type SocketMessageHandler = (
  context: SocketHandlerContext,
) => Promise<SocketHandlerResult>;
