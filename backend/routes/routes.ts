import type { FastifyInstance } from "fastify";
import { HealthController } from "../controller/healthController";
import { AuthController } from "../controller/authController";
import { createRouter } from "../lib/fastify/routeHelper";
import { userAuth } from "../middleware/loginMiddleware";

export default async function registerRoutes(
  fastify: FastifyInstance,
): Promise<void> {
  const { get, post } = createRouter(fastify);

  // ==================== 系统接口 ====================
  get("/health", HealthController.health);

  // ==================== 认证接口 ====================
  get("/auth/me", userAuth, AuthController.me);

  // 保留 iOS App 现有路径，平滑对接新的 JWT 鉴权链路。
  post("/v4/u/user/getCode", AuthController.requestCode);
  post("/v4/u/user/appVerifyCode", AuthController.loginByCode);
  post("/v4/u/user/getInfo", userAuth, AuthController.appGetInfo);
  post("/v4/u/user/logout", userAuth, AuthController.appLogout);
}
