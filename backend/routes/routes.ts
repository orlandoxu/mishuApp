import type { FastifyInstance } from "fastify";
import { HealthController } from "../controller/healthController";
import { AuthController } from "../controller/authController";
import { PartnerInvitationController } from "../controller/partnerInvitationController";
import { AdminController } from "../controller/adminController";
import { LedgerController } from "../controller/ledgerController";
import { FriendController } from "../controller/friendController";
import { FoodMemoryController } from "../controller/foodMemoryController";
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
  post("/ledger/record", userAuth, LedgerController.record);
  post("/ledger/query", userAuth, LedgerController.query);
  get("/ledger/summary", userAuth, LedgerController.summary);
  get("/ledger/categories", userAuth, LedgerController.categories);
  post("/ledger/categories/save", userAuth, LedgerController.saveCategories);

  // ==================== 我的朋友 ====================
  post("/friend/list", userAuth, FriendController.list);
  post("/friend/detail", userAuth, FriendController.detail);
  post("/friend/create", userAuth, FriendController.create);
  post("/friend/update", userAuth, FriendController.update);
  post("/friend/delete", userAuth, FriendController.remove);

  post("/friend/interactions/list", userAuth, FriendController.listInteractions);
  post("/friend/interactions/create", userAuth, FriendController.createInteraction);
  post("/friend/interactions/update", userAuth, FriendController.updateInteraction);
  post("/friend/interactions/delete", userAuth, FriendController.removeInteraction);

  // ==================== 美食记忆 ====================
  post("/food-memory/list", userAuth, FoodMemoryController.list);
  post("/food-memory/detail", userAuth, FoodMemoryController.detail);
  post("/food-memory/create", userAuth, FoodMemoryController.create);
  post("/food-memory/update", userAuth, FoodMemoryController.update);
  post("/food-memory/delete", userAuth, FoodMemoryController.remove);
  get("/food-memory/categories", userAuth, FoodMemoryController.categories);
  get("/food-memory/months", userAuth, FoodMemoryController.months);

  // ==================== Admin 后台接口 ====================
  post("/admin/login", AdminController.login);
  post("/admin/users", adminAuth, AdminController.users);
  post("/admin/users/summary", adminAuth, AdminController.usersSummary);
  post("/admin/users/status", adminAuth, AdminController.userStatus);
  post("/admin/orders", adminAuth, AdminController.orders);
  post("/admin/doubao/logs", adminAuth, AdminController.doubaoLogs);
  get("/admin/dashboard", adminAuth, AdminController.dashboard);

  // ==================== TA 邀请绑定 ====================
  post("/partner/invitations", userAuth, PartnerInvitationController.create);
  get("/partner/invitations/:token", PartnerInvitationController.detail);
  post("/partner/invitations/:token/code", PartnerInvitationController.code);
  post("/partner/invitations/:token/accept", PartnerInvitationController.accept);
  get("/partner/relationship", userAuth, PartnerInvitationController.relationship);
}
