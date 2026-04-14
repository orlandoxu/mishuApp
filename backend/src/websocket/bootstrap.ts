import fs from 'node:fs';
import https from 'node:https';
import type { Server as HttpServer } from 'node:http';
import { X509Certificate } from 'node:crypto';
import { WebSocketServer } from 'ws';

import { config } from '../config/config';
import { wsRuntimeState } from './runtimeState';
import { SocketServer } from './socketServer';

export async function bootstrapWebSocketServices(httpServer: HttpServer): Promise<void> {
  startWsServer(httpServer);
  await startWssServer();
}

function startWsServer(httpServer: HttpServer): void {
  const wsServer = new WebSocketServer({ server: httpServer, path: config.ws.path });
  const socketServer = new SocketServer(wsServer, 'ws');
  wsRuntimeState.ws = 'up';

  setInterval(() => {
    wsRuntimeState.wsClients = socketServer.getClientCount();
  }, 2_000);

  console.log(`[ws] ready at ws://${config.app.host}:${config.app.port}${config.ws.path}`);
}

async function startWssServer(): Promise<void> {
  if (!config.ws.wssEnabled) {
    wsRuntimeState.wss = 'disabled';
    return;
  }

  try {
    const key = fs.readFileSync(config.ws.wssKeyPath, 'utf8');
    const cert = fs.readFileSync(config.ws.wssCertPath, 'utf8');

    const certInfo = new X509Certificate(cert);
    wsRuntimeState.wssCertNotAfter = certInfo.validTo;
    if (new Date(certInfo.validTo).getTime() < Date.now()) {
      console.warn(`[wss] cert expired at ${certInfo.validTo}. Please replace certificate files.`);
    }

    const httpsServer = https.createServer({ key, cert }, (_req, res) => {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('wss ready');
    });

    const wssServer = new WebSocketServer({ server: httpsServer, path: config.ws.path });
    const socketServer = new SocketServer(wssServer, 'wss');

    await new Promise<void>((resolve, reject) => {
      httpsServer.once('error', reject);
      httpsServer.listen(config.ws.wssPort, config.ws.wssHost, () => resolve());
    });

    wsRuntimeState.wss = 'up';
    setInterval(() => {
      wsRuntimeState.wssClients = socketServer.getClientCount();
    }, 2_000);

    console.log(`[wss] ready at wss://${config.ws.wssHost}:${config.ws.wssPort}${config.ws.path}`);
  } catch (error) {
    wsRuntimeState.wss = 'down';
    wsRuntimeState.wssError = error instanceof Error ? error.message : String(error);
    console.error('[wss] startup failed', error);
  }
}
