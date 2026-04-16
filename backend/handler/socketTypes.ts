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
  send: (payload: unknown) => void;
  getUser: () => AuthUser | null;
  setUser: (user: AuthUser) => void;
  ensureUserByToken: (token: string) => Promise<AuthUser | null>;
};
