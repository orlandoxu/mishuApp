import type { FastifyInstance } from 'fastify';
import { HealthController } from '../controller/healthController';
import { AuthController } from '../controller/authController';

export function registerRoutes(app: FastifyInstance): void {
  app.get('/health', { config: { noAuth: true } }, HealthController.health);
  app.post('/auth/register', { config: { noAuth: true } }, AuthController.register);
  app.post('/auth/login', { config: { noAuth: true } }, AuthController.login);
  app.post('/auth/mock-login', { config: { noAuth: true } }, AuthController.mockLogin);
  app.get('/auth/me', AuthController.me);

  // 保留 iOS App 现有路径，平滑对接新的 JWT 鉴权链路。
  app.post('/v4/u/user/getCode', { config: { noAuth: true } }, AuthController.requestCode);
  app.post('/v4/u/user/appVerifyCode', { config: { noAuth: true } }, AuthController.loginByCode);
  app.post('/v4/u/user/loginByAcountAndPwd', { config: { noAuth: true } }, AuthController.login);
  app.post('/v4/u/user/registerByAcountAndPwd', { config: { noAuth: true } }, AuthController.register);
  app.post('/v4/u/user/getInfo', AuthController.appGetInfo);
  app.post('/v4/u/user/logout', AuthController.appLogout);
}
