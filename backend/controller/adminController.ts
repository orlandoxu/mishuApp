import { z } from 'zod';
import { BodySchema } from '../lib/fastify/bodySchema';
import type { TypedRequest } from '../lib/fastify/typeHelpers';
import { ok, type ApiResponse } from '../common/response';
import { AdminService } from '../services/adminService';

export class AdminController {
  static loginType = z.object({
    username: z.string().trim().min(1, '账号不能为空'),
    password: z.string().min(1, '密码不能为空'),
  });

  @BodySchema(AdminController.loginType)
  static async login(
    request: TypedRequest<typeof AdminController.loginType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.login>>>> {
    return ok(await AdminService.login(request.body));
  }

  static usersType = z.object({
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
    keyword: z.string().trim().optional(),
  });

  @BodySchema(AdminController.usersType)
  static async users(
    request: TypedRequest<typeof AdminController.usersType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getUsers>>>> {
    return ok(await AdminService.getUsers(request.body));
  }

  static usersSummaryType = z.object({
    keyword: z.string().trim().optional(),
  });

  @BodySchema(AdminController.usersSummaryType)
  static async usersSummary(
    request: TypedRequest<typeof AdminController.usersSummaryType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getUsersSummary>>>> {
    return ok(await AdminService.getUsersSummary(request.body));
  }

  static userStatusType = z.object({
    userId: z.string().trim().min(1, '用户ID不能为空'),
  });

  @BodySchema(AdminController.userStatusType)
  static async userStatus(
    request: TypedRequest<typeof AdminController.userStatusType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.toggleUserStatus>>>> {
    return ok(await AdminService.toggleUserStatus(request.body.userId));
  }

  static ordersType = z.object({
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
    userId: z.string().trim().optional(),
    phoneNumber: z.string().trim().optional(),
    orderId: z.string().trim().optional(),
    payMethod: z.enum(['alipay', 'wechat', 'apple']).optional(),
    planId: z.enum(['monthly', 'yearly']).optional(),
    orderStatus: z.enum(['paid', 'refunded', 'pending']).optional(),
    startAt: z.string().datetime().optional(),
    endAt: z.string().datetime().optional(),
  });

  @BodySchema(AdminController.ordersType)
  static async orders(
    request: TypedRequest<typeof AdminController.ordersType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getOrders>>>> {
    return ok(await AdminService.getOrders(request.body));
  }

  static doubaoLogsType = z.object({
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
    apiType: z.string().trim().optional(),
    userKeyword: z.string().trim().optional(),
  });

  @BodySchema(AdminController.doubaoLogsType)
  static async doubaoLogs(
    request: TypedRequest<typeof AdminController.doubaoLogsType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getDoubaoLogs>>>> {
    return ok(await AdminService.getDoubaoLogs(request.body));
  }

  static async dashboard(): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getDashboard>>>> {
    return ok(await AdminService.getDashboard());
  }
}
