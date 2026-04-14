export type SocketMessage = {
  type: string;
  requestId?: string;
  token?: string;
  data?: unknown;
  [key: string]: unknown;
};
