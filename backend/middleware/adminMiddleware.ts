import type { FastifyReply, FastifyRequest } from 'fastify';
import { ASSERT, Ret } from '../common/error';
import { UserTokenService } from '../services/userTokenService';
import { AdminService } from '../services/adminService';

export async function adminAuth(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  const authHeader = request.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice('Bearer '.length) : authHeader;

  ASSERT(token, '未登录', Ret.NotLogin);

  const user = await UserTokenService.ensureUserByToken(token);
  ASSERT(user, '未登录', Ret.NotLogin);
  ASSERT(AdminService.isAdminUserId(user.id), '无权限访问', Ret.NotLogin);

  request.user = user;
}
