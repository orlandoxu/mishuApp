import type { FastifyInstance } from 'fastify';
import { HealthController } from '../controller/healthController';
import { AuthController } from '../controller/authController';

export function registerRoutes(app: FastifyInstance): void {
  app.get('/health', { config: { noAuth: true } }, HealthController.health);
  app.post('/auth/mock-login', { config: { noAuth: true } }, AuthController.mockLogin);
  app.get('/auth/me', AuthController.me);
}
