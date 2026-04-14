import './common/fastifyType.js';

import Fastify, { type FastifyInstance, type FastifyReply, type FastifyRequest } from 'fastify';
import cors from '@fastify/cors';
import chalk from 'chalk';

import { RestError, RestErrorWithData } from './common/error.js';
import { config } from './config/config.js';
import { loginMiddleware } from './middleware/loginMiddleware.js';
import { registerRoutes } from './routes/routes.js';

export async function createApp(): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });

  await app.register(cors, {
    maxAge: 5 * 60,
  });

  app.addHook('onRequest', (request: FastifyRequest, _reply: FastifyReply, done) => {
    request.logStart = process.hrtime.bigint();
    console.log(chalk.yellow(`Request: ${request.method} ${request.raw.url ?? ''}`));
    done();
  });

  app.addHook('onSend', (request: FastifyRequest, reply: FastifyReply, payload: unknown, done) => {
    const start = request.logStart;
    if (start) {
      const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;
      const logs = [
        chalk.green(
          `Response: ${request.method} ${request.raw.url ?? ''} ${durationMs.toFixed(1)}ms ${reply.statusCode}`
        ),
      ];

      if (config.app.nodeEnv !== 'production') {
        logs.push(chalk.white(typeof payload === 'string' ? payload : JSON.stringify(payload)));
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

    if (error instanceof RestErrorWithData) {
      reply.status(200).send({ ret: error.code ?? 0, msg: error.message ?? '', data: error.data });
      return;
    }

    console.error(error);
    reply.status(500).send({ ret: 500, msg: 'internal server error' });
  });

  app.addHook('preHandler', loginMiddleware);
  registerRoutes(app);

  return app;
}
