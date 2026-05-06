import { ASSERT, Ret } from '../common/error';
import { config } from '../config/config';
import { issueToken } from '../lib/tokenStore';
import { hashPassword, verifyPassword } from '../lib/password';
import { AdminUser } from '../models/AdminUser';
import { User } from '../models/User';
import { DoubaoCallLog } from '../models/DoubaoCallLog';
import { DashboardDailyStatService } from './dashboardDailyStatService';

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

function calcPercentChange(current: number, previous: number): number | null {
  if (previous <= 0) {
    return current > 0 ? 100 : null;
  }
  return Number((((current - previous) / previous) * 100).toFixed(1));
}

function isMongoObjectIdLike(value: string): boolean {
  return /^[a-fA-F0-9]{24}$/.test(value);
}

function extractLogUserId(item: {
  userId?: string;
  requestPayload?: Record<string, unknown>;
}): string {
  const direct = typeof item.userId === 'string' ? item.userId.trim() : '';
  if (direct) return direct;

  const payload = item.requestPayload ?? {};
  const candidates = [payload.userId, payload.user];
  for (const candidate of candidates) {
    if (typeof candidate === 'string' && candidate.trim()) {
      return candidate.trim();
    }
  }
  return '';
}

function resolveLogUserDisplayName(userId: string, userPhone: string): string {
  if (userPhone) {
    return `用户${userPhone.slice(-4)}`;
  }
  if (userId) {
    return userId === 'system' ? '系统' : userId;
  }
  return '系统';
}

function resolveVipStatusById(id: string): '普通' | 'VIP' | 'SVIP' {
  const lastNum = Number.parseInt(id.slice(-1), 16);
  if (lastNum % 4 === 0) return 'SVIP';
  if (lastNum % 3 === 0) return 'VIP';
  return '普通';
}

function buildMockOrderRecord(item: {
  _id: { toString(): string };
  phoneNumber: string;
  createdAt: Date;
  lastLoginAt?: Date;
}) {
  const id = item._id.toString();
  const tailNum = Number.parseInt(id.slice(-4), 16);
  const amount = tailNum % 2 === 0 ? Number((tailNum % 2000 + 68).toFixed(2)) : 0;
  const planId = amount >= 168 ? 'yearly' : 'monthly';
  const planName = planId === 'yearly' ? '年度会员' : '月度会员';
  const payMethod = tailNum % 5 === 0 ? 'apple' : tailNum % 3 === 0 ? 'alipay' : 'wechat';
  const orderStatus = amount > 0 ? 'paid' : 'pending';
  const paidAt = item.lastLoginAt ?? item.createdAt;
  const expireAt = new Date(new Date(paidAt).getTime() + (planId === 'yearly' ? 365 : 30) * 24 * 60 * 60 * 1000);

  return {
    orderId: `ODR-${id.slice(-10).toUpperCase()}`,
    thirdPartyOrderId: `TP-${id.slice(-12).toUpperCase()}`,
    mongoOrderId: id,
    userId: id,
    userName: `用户${item.phoneNumber.slice(-4)}`,
    phoneNumber: item.phoneNumber,
    vipStatus: resolveVipStatusById(id),
    planId,
    planName,
    amountCny: amount,
    payMethod,
    orderStatus,
    paidAt,
    expireAt,
  };
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
        displayName: `用户${item.phoneNumber.slice(-4)}`,
        role: item.role,
        status: item.isActive ? '正常' : '禁用',
        vipStatus: resolveVipStatusById(item._id.toString()),
        ltvCny:
          Number.parseInt(item._id.toString().slice(-4), 16) % 2 === 0
            ? Number(
                (
                  Number.parseInt(item._id.toString().slice(-4), 16) % 2000 +
                  68
                ).toFixed(2),
              )
            : 0,
        createdAt: item.createdAt,
        lastLoginAt: item.lastLoginAt ?? null,
      })),
    };
  }

  static async getUsersSummary(args: { keyword?: string }) {
    const keyword = (args.keyword ?? '').trim();
    const filter = keyword ? { phoneNumber: { $regex: keyword, $options: 'i' } } : {};
    const summaryRows = await User.find(filter).select({ _id: 1, isActive: 1 }).lean();

    const summary = summaryRows.reduce(
      (acc, item) => {
        const id = item._id.toString();
        const tailNum = Number.parseInt(id.slice(-4), 16);
        const lastNum = Number.parseInt(id.slice(-1), 16);
        const ltv = tailNum % 2 === 0 ? Number((tailNum % 2000 + 68).toFixed(2)) : 0;
        if (ltv > 0) {
          acc.paidUsers += 1;
          acc.totalLtvCny += ltv;
        }
        if (lastNum % 4 === 0) acc.svipUsers += 1;
        else if (lastNum % 3 === 0) acc.vipUsers += 1;
        if (!item.isActive) acc.disabledUsers += 1;
        return acc;
      },
      { totalLtvCny: 0, paidUsers: 0, vipUsers: 0, svipUsers: 0, disabledUsers: 0 },
    );

    return {
      totalUsers: summaryRows.length,
      totalLtvCny: Number(summary.totalLtvCny.toFixed(2)),
      paidUsers: summary.paidUsers,
      vipUsers: summary.vipUsers,
      svipUsers: summary.svipUsers,
      disabledUsers: summary.disabledUsers,
    };
  }

  static async toggleUserStatus(userId: string) {
    const user = await User.findById(userId);
    ASSERT(user, '用户不存在', Ret.ERROR);
    user.isActive = !user.isActive;
    await user.save();
    return { userId: user._id.toString(), isActive: user.isActive };
  }

  static async getOrders(args: {
    page?: number;
    pageSize?: number;
    userId?: string;
    phoneNumber?: string;
    orderId?: string;
    payMethod?: 'alipay' | 'wechat' | 'apple';
    planId?: 'monthly' | 'yearly';
    orderStatus?: 'paid' | 'refunded' | 'pending';
    startAt?: string;
    endAt?: string;
  }) {
    const { page, pageSize } = normalizePage(args.page, args.pageSize);
    const userId = (args.userId ?? '').trim();
    const phoneNumber = (args.phoneNumber ?? '').trim();
    const orderIdKeyword = (args.orderId ?? '').trim().toUpperCase();
    const startAt = args.startAt ? new Date(args.startAt) : null;
    const endAt = args.endAt ? new Date(args.endAt) : null;
    const hasValidStartAt = !!startAt && Number.isFinite(startAt.getTime());
    const hasValidEndAt = !!endAt && Number.isFinite(endAt.getTime());
    const timeStart = hasValidStartAt ? startAt!.getTime() : null;
    const timeEnd = hasValidEndAt ? endAt!.getTime() : null;

    const userFilter: Record<string, unknown> = { role: 'user' };
    if (userId) {
      userFilter._id = userId;
    }
    if (phoneNumber) {
      userFilter.phoneNumber = { $regex: phoneNumber, $options: 'i' };
    }

    const offset = (page - 1) * pageSize;
    const records: Array<ReturnType<typeof buildMockOrderRecord>> = [];
    let total = 0;
    const summary = { totalAmount: 0, paidCount: 0, pendingCount: 0, yearlyCount: 0 };

    const cursor = User.find(userFilter)
      .select({ _id: 1, phoneNumber: 1, createdAt: 1, lastLoginAt: 1 })
      .sort({ createdAt: -1 })
      .lean()
      .cursor();

    for await (const user of cursor) {
      const item = buildMockOrderRecord(user);

      if (orderIdKeyword) {
        const matchedOrderId = item.orderId.toUpperCase().includes(orderIdKeyword);
        const matchedThirdPartyOrderId = item.thirdPartyOrderId.toUpperCase().includes(orderIdKeyword);
        const matchedMongoOrderId = item.mongoOrderId.toUpperCase().includes(orderIdKeyword);
        if (!matchedOrderId && !matchedThirdPartyOrderId && !matchedMongoOrderId) {
          continue;
        }
      }
      if (args.payMethod && item.payMethod !== args.payMethod) continue;
      if (args.planId && item.planId !== args.planId) continue;
      if (args.orderStatus && item.orderStatus !== args.orderStatus) continue;
      if (timeStart !== null || timeEnd !== null) {
        const paidAtMs = new Date(item.paidAt).getTime();
        if (timeStart !== null && paidAtMs < timeStart) continue;
        if (timeEnd !== null && paidAtMs > timeEnd) continue;
      }

      total += 1;
      summary.totalAmount += item.amountCny;
      if (item.orderStatus === 'paid') summary.paidCount += 1;
      if (item.orderStatus === 'pending') summary.pendingCount += 1;
      if (item.planId === 'yearly') summary.yearlyCount += 1;

      if (total > offset && records.length < pageSize) {
        records.push(item);
      }
    }

    return {
      page,
      pageSize,
      total,
      summary: {
        totalAmountCny: Number(summary.totalAmount.toFixed(2)),
        paidCount: summary.paidCount,
        pendingCount: summary.pendingCount,
        yearlyCount: summary.yearlyCount,
      },
      records,
    };
  }

  static async getDoubaoLogs(args: { page?: number; pageSize?: number; apiType?: string; userKeyword?: string }) {
    const { page, pageSize } = normalizePage(args.page, args.pageSize);
    const apiType = (args.apiType ?? '').trim();
    const userKeyword = (args.userKeyword ?? '').trim();
    const filter: Record<string, unknown> = {};
    if (apiType) {
      filter.apiType = apiType;
    }
    if (userKeyword) {
      const phoneMatchedUsers = await User.find({
        phoneNumber: { $regex: userKeyword, $options: 'i' },
      })
        .select({ _id: 1 })
        .limit(500)
        .lean();
      const ids = phoneMatchedUsers.map((item) => item._id.toString());
      filter.$or = [
        { userId: { $regex: userKeyword, $options: 'i' } },
        ...(ids.length > 0 ? [{ userId: { $in: ids } }] : []),
      ];
    }

    const [total, records] = await Promise.all([
      DoubaoCallLog.countDocuments(filter),
      DoubaoCallLog.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .lean(),
    ]);

    const normalizedUserIds = records.map((item) => extractLogUserId({
      userId: item.userId,
      requestPayload: item.requestPayload as Record<string, unknown> | undefined,
    }));
    const userIds = Array.from(new Set(normalizedUserIds.filter((id) => id && isMongoObjectIdLike(id))));
    const users = userIds.length > 0
      ? await User.find({ _id: { $in: userIds } }).select({ _id: 1, phoneNumber: 1 }).lean()
      : [];
    const userMap = new Map(users.map((item) => [item._id.toString(), item]));

    return {
      page,
      pageSize,
      total,
      records: records.map((item, index) => {
        const normalizedUserId = normalizedUserIds[index] ?? '';
        const matchedUser = normalizedUserId && isMongoObjectIdLike(normalizedUserId)
          ? userMap.get(normalizedUserId)
          : undefined;
        const userPhone = matchedUser?.phoneNumber ?? '';
        const vipStatus = normalizedUserId && isMongoObjectIdLike(normalizedUserId)
          ? resolveVipStatusById(normalizedUserId)
          : '普通';
        return ({
        id: item._id.toString(),
        apiType: item.apiType,
        modelId: item.modelId,
        userId: normalizedUserId,
        userPhone,
        userDisplayName: resolveLogUserDisplayName(normalizedUserId, userPhone),
        vipStatus,
        durationMs: item.durationMs,
        inputTokens: item.inputTokens ?? 0,
        outputTokens: item.outputTokens ?? 0,
        totalTokens: item.totalTokens ?? 0,
        tokenSource: item.tokenSource ?? 'estimated',
        success: item.success,
        requestPreview: item.requestPreview ?? '',
        responsePreview: item.responsePreview ?? '',
        requestPayload: item.requestPayload ?? {},
        responsePayload: item.responsePayload ?? {},
        responseText: item.responseText ?? '',
        errorMessage: item.errorMessage ?? '',
        createdAt: item.createdAt,
      });
      }),
    };
  }

  static async getDashboard() {
    const [
      totalUsers,
      dailyStats60,
      doubaoByApi,
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      DashboardDailyStatService.getDailyStats(60),
      DashboardDailyStatService.getApiMixInDays(30),
    ]);

    const todayStat = dailyStats60[dailyStats60.length - 1] ?? null;
    const yesterdayStat = dailyStats60[dailyStats60.length - 2] ?? null;
    const last7d = dailyStats60.slice(-7);
    const prev7d = dailyStats60.slice(-14, -7);
    const last30d = dailyStats60.slice(-30);

    const sumBy = (list: typeof dailyStats60, key: 'newUsers' | 'doubaoCalls' | 'doubaoSuccessCalls' | 'doubaoDurationTotalMs') =>
      list.reduce((acc, item) => acc + (item[key] ?? 0), 0);

    const newUsersToday = todayStat?.newUsers ?? 0;
    const newUsersYesterday = yesterdayStat?.newUsers ?? 0;
    const newUsers7d = sumBy(last7d, 'newUsers');
    const newUsersPrev7d = sumBy(prev7d, 'newUsers');
    const doubaoToday = todayStat?.doubaoCalls ?? 0;
    const doubaoYesterday = yesterdayStat?.doubaoCalls ?? 0;
    const doubao30d = sumBy(last30d, 'doubaoCalls');
    const doubaoSuccess30d = sumBy(last30d, 'doubaoSuccessCalls');
    const doubaoDurationTotal30d = sumBy(last30d, 'doubaoDurationTotalMs');
    const doubaoP95LatencyMs30d = doubao30d > 0
      ? Math.round(last30d.reduce((acc, item) => acc + item.doubaoP95LatencyMs * item.doubaoCalls, 0) / doubao30d)
      : 0;

    const growthSeries = dailyStats60.map((item) => ({
      date: item.dateKey,
      newUsers: item.newUsers,
      loginUsers: item.activeUsers,
      doubaoCalls: item.doubaoCalls,
      doubaoSuccessRate: Number(((item.doubaoSuccessCalls / Math.max(1, item.doubaoCalls)) * 100).toFixed(1)),
    }));

    return {
      snapshotAt: new Date(),
      metrics: {
        totalUsers,
        newUsersToday,
        newUsers7d,
        activeUsersToday: todayStat?.activeUsers ?? 0,
        activeUsers7d: todayStat?.activeUsers7dRolling ?? 0,
        activeUsers30d: todayStat?.activeUsers30dRolling ?? 0,
        doubaoCallsToday: doubaoToday,
        doubaoCalls30d: doubao30d,
        doubaoSuccessRate30d: Number(((doubaoSuccess30d / Math.max(1, doubao30d)) * 100).toFixed(1)),
        doubaoAvgLatencyMs30d: Math.round(doubaoDurationTotal30d / Math.max(1, doubao30d)),
        doubaoP95LatencyMs30d,
      },
      trends: {
        newUsersTodayVsYesterdayPct: calcPercentChange(newUsersToday, newUsersYesterday),
        newUsers7dVsPrev7dPct: calcPercentChange(newUsers7d, newUsersPrev7d),
        doubaoTodayVsYesterdayPct: calcPercentChange(doubaoToday, doubaoYesterday),
      },
      charts: {
        growth60d: growthSeries,
        doubaoApiMix30d: doubaoByApi.map((item) => ({ apiType: item.apiType, count: item.calls })),
      },
    };
  }

  static isAdminUserId(userId: string): boolean {
    return userId.startsWith('admin:');
  }
}
