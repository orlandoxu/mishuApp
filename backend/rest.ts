import './common/globals';
import './common/fastifyType';

import Fastify from 'fastify';
import cors from '@fastify/cors';

import { RestError } from './common/error';
import { config } from './config/config';
import registerRoutes from './routes/routes';

export async function bootstrap(): Promise<void> {
  const app = Fastify({ logger: false });

  await app.register(cors, {
    maxAge: 5 * 60,
  });

  app.addHook('onRequest', (request: FastifyRequest, _reply: FastifyReply, done) => {
    request.logStart = process.hrtime.bigint();
    console.log(`Request: ${request.method} ${request.raw.url ?? ''}`);
    done();
  });

  app.addHook('onSend', (request: FastifyRequest, reply: FastifyReply, payload: unknown, done) => {
    const start = request.logStart;
    if (start) {
      const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;
      const logs = [
        `Response: ${request.method} ${request.raw.url ?? ''} ${durationMs.toFixed(1)}ms ${reply.statusCode}`,
      ];

      if (config.app.nodeEnv !== 'production') {
        logs.push(typeof payload === 'string' ? payload : JSON.stringify(payload));
      }

      console.log(...logs);
    }

    done();
  });

  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof RestError) {
      reply.status(200).send({ ret: error.code ?? 10000, msg: error.message ?? '系统内部错误，请稍后重试' });
      return;
    }

    console.error(error);
    reply.status(500).send({ ret: 500, msg: 'internal server error' });
  });

  await registerRoutes(app);

  await app.listen({
    port: config.app.port,
    host: config.app.host,
  });

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
