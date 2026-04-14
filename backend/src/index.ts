import { createApp } from './app';
import { config } from './config/config';
import { bootstrapWebSocketServices } from './websocket/bootstrap';

export async function bootstrap(): Promise<void> {
  const app = await createApp();

  await app.listen({
    port: config.app.port,
    host: config.app.host,
  });

  await bootstrapWebSocketServices(app.server);

  console.log(`backend listening on http://${config.app.host}:${config.app.port}`);
}

bootstrap().catch((error) => {
  console.error('backend startup failed', error);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('There was an uncaught error', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
