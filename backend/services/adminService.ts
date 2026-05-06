import { ASSERT, Ret } from '../common/error';
import { config } from '../config/config';
import { issueToken } from '../lib/tokenStore';
import { hashPassword, verifyPassword } from '../lib/password';
import { AdminUser } from '../models/AdminUser';
import { User } from '../models/User';
import { DoubaoCallLog } from '../models/DoubaoCallLog';

type PageArgs = {
  page: number;
  pageSize: number;
};

function normalizePage(rawPage?: number, rawPageSize?: number): PageArgs {
  const page = Number.isFinite(rawPage) && (rawPage as number) > 0 ? Math.floor(rawPage as number) : 1;
  const pageSize = Number.isFinite(rawPageSize) && (rawPageSize as number) > 0
    ? Math.min(100, Math.floor(rawPageSize as number))
    : 20;

  return { page, pageSize };
}

function normalizeUsername(value: string | undefined): string {
  return (value ?? '').trim().toLowerCase();
}

export class AdminService {
  static async ensureBootstrapAdmin(): Promise<void> {
    const username = normalizeUsername(config.admin.bootstrapUsername);
    const exists = await AdminUser.findByUsername(username);
    if (exists) {
      return;
    }

    const passwordHash = await hashPassword(config.admin.bootstrapPassword);
    await AdminUser.createAdmin({ username, passwordHash, role: 'super_admin' });
  }

  static async login(args: { username?: string; password?: string }): Promise<{ token: string; username: string }> {
    await this.ensureBootstrapAdmin();

    const username = normalizeUsername(args.username);
    const password = args.password ?? '';
    const admin = await AdminUser.findByUsername(username);

    ASSERT(admin, '账号或密码错误', Ret.ERROR);
    ASSERT(admin.isActive, '账号已禁用', Ret.ERROR);

    const passwordOk = await verifyPassword(password, admin.passwordHash);
    ASSERT(passwordOk, '账号或密码错误', Ret.ERROR);

    await AdminUser.findByIdAndUpdate(admin._id, { lastLoginAt: new Date() });

    const token = await issueToken(`admin:${admin._id.toString()}`);
    return { token, username: admin.username };
  }

  static async getUsers(args: { page?: number; pageSize?: number; keyword?: string }) {
    const { page, pageSize } = normalizePage(args.page, args.pageSize);
    const keyword = (args.keyword ?? '').trim();
    const filter = keyword ? { phoneNumber: { $regex: keyword, $options: 'i' } } : {};

    const [total, records] = await Promise.all([
      User.countDocuments(filter),
      User.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .lean(),
    ]);

    return {
      page,
      pageSize,
      total,
      records: records.map((item) => ({
        id: item._id.toString(),
        phoneNumber: item.phoneNumber,
        role: item.role,
        status: item.isActive ? '正常' : '禁用',
        createdAt: item.createdAt,
        lastLoginAt: item.lastLoginAt ?? null,
      })),
    };
  }

  static async getDoubaoLogs(args: { page?: number; pageSize?: number; apiType?: string }) {
    const { page, pageSize } = normalizePage(args.page, args.pageSize);
    const apiType = (args.apiType ?? '').trim();
    const filter = apiType ? { apiType } : {};

    const [total, records] = await Promise.all([
      DoubaoCallLog.countDocuments(filter),
      DoubaoCallLog.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .lean(),
    ]);

    return {
      page,
      pageSize,
      total,
      records: records.map((item) => ({
        id: item._id.toString(),
        apiType: item.apiType,
        modelId: item.modelId,
        durationMs: item.durationMs,
        success: item.success,
        errorMessage: item.errorMessage ?? '',
        createdAt: item.createdAt,
      })),
    };
  }

  static isAdminUserId(userId: string): boolean {
    return userId.startsWith('admin:');
  }
}
