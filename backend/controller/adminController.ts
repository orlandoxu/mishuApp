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

  static doubaoLogsType = z.object({
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
    apiType: z.string().trim().optional(),
  });

  @BodySchema(AdminController.doubaoLogsType)
  static async doubaoLogs(
    request: TypedRequest<typeof AdminController.doubaoLogsType>,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof AdminService.getDoubaoLogs>>>> {
    return ok(await AdminService.getDoubaoLogs(request.body));
  }
}
