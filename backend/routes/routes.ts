import type { FastifyInstance } from "fastify";
import { HealthController } from "../controller/healthController";
import { AuthController } from "../controller/authController";
import { PartnerInvitationController } from "../controller/partnerInvitationController";
import { AdminController } from "../controller/adminController";
import { createRouter } from "../lib/fastify/routeHelper";
import { userAuth } from "../middleware/loginMiddleware";
import { adminAuth } from "../middleware/adminMiddleware";

export default async function registerRoutes(
  fastify: FastifyInstance,
): Promise<void> {
  const { get, post } = createRouter(fastify);

  // ==================== 系统接口 ====================
  get("/health", HealthController.health);

  // ==================== 认证接口 ====================
  get("/auth/me", userAuth, AuthController.me);

  // 保留 iOS App 现有路径，平滑对接新的 JWT 鉴权链路。
  post("/user/getCode", AuthController.requestCode);
  post("/user/appVerifyCode", AuthController.loginByCode);
  post("/user/getInfo", userAuth, AuthController.appGetInfo);
  post("/user/logout", userAuth, AuthController.appLogout);

  // ==================== Admin 后台接口 ====================
  post("/admin/login", AdminController.login);
  post("/admin/users", adminAuth, AdminController.users);
  post("/admin/doubao/logs", adminAuth, AdminController.doubaoLogs);

  // ==================== TA 邀请绑定 ====================
  post("/partner/invitations", userAuth, PartnerInvitationController.create);
  get("/partner/invitations/:token", PartnerInvitationController.detail);
  post("/partner/invitations/:token/code", PartnerInvitationController.code);
  post("/partner/invitations/:token/accept", PartnerInvitationController.accept);
  get("/partner/relationship", userAuth, PartnerInvitationController.relationship);
}
