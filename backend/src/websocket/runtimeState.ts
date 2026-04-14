export type WsStatus = 'up' | 'down' | 'disabled';

export const wsRuntimeState: {
  ws: WsStatus;
  wss: WsStatus;
  wsClients: number;
  wssClients: number;
  wssError?: string;
  wssCertNotAfter?: string;
} = {
  ws: 'down',
  wss: 'down',
  wsClients: 0,
  wssClients: 0,
};
