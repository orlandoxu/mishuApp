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

function startOfToday(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function daysAgo(days: number): Date {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000);
}

function toDateLabel(date: Date): string {
  const y = date.getFullYear();
  const m = `${date.getMonth() + 1}`.padStart(2, '0');
  const d = `${date.getDate()}`.padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function buildDateSeries(days: number): string[] {
  const list: string[] = [];
  const start = daysAgo(days - 1);
  for (let i = 0; i < days; i += 1) {
    const day = new Date(start.getTime() + i * 24 * 60 * 60 * 1000);
    list.push(toDateLabel(day));
  }
  return list;
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

    const users = await User.find(userFilter).sort({ createdAt: -1 }).lean();
    const allRecords = users.map((item) => {
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
    });

    const filteredRecords = allRecords.filter((item) => {
      if (orderIdKeyword) {
        const matchedOrderId = item.orderId.toUpperCase().includes(orderIdKeyword);
        const matchedThirdPartyOrderId = item.thirdPartyOrderId.toUpperCase().includes(orderIdKeyword);
        const matchedMongoOrderId = item.mongoOrderId.toUpperCase().includes(orderIdKeyword);
        if (!matchedOrderId && !matchedThirdPartyOrderId && !matchedMongoOrderId) {
          return false;
        }
      }
      if (args.payMethod && item.payMethod !== args.payMethod) return false;
      if (args.planId && item.planId !== args.planId) return false;
      if (args.orderStatus && item.orderStatus !== args.orderStatus) return false;
      if (timeStart !== null || timeEnd !== null) {
        const paidAtMs = new Date(item.paidAt).getTime();
        if (timeStart !== null && paidAtMs < timeStart) return false;
        if (timeEnd !== null && paidAtMs > timeEnd) return false;
      }
      return true;
    });

    const total = filteredRecords.length;
    const records = filteredRecords.slice((page - 1) * pageSize, page * pageSize);

    const summary = filteredRecords.reduce(
      (acc, item) => {
        acc.totalAmount += item.amountCny;
        if (item.orderStatus === 'paid') acc.paidCount += 1;
        if (item.orderStatus === 'pending') acc.pendingCount += 1;
        if (item.planId === 'yearly') acc.yearlyCount += 1;
        return acc;
      },
      { totalAmount: 0, paidCount: 0, pendingCount: 0, yearlyCount: 0 },
    );

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
    const todayStart = startOfToday();
    const yesterdayStart = new Date(todayStart.getTime() - 24 * 60 * 60 * 1000);
    const last7dStart = daysAgo(7);
    const prev7dStart = daysAgo(14);
    const last30dStart = daysAgo(30);

    const [
      totalUsers,
      newUsersToday,
      newUsersYesterday,
      newUsers7d,
      newUsersPrev7d,
      activeUsersToday,
      activeUsers7d,
      activeUsers30d,
      doubao30d,
      doubaoToday,
      doubaoYesterday,
      userGrowthDaily,
      dailyStats60,
      doubaoDaily,
      doubaoByApi,
      latencyAgg,
      durations30d,
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      User.countDocuments({ role: 'user', createdAt: { $gte: todayStart } }),
      User.countDocuments({ role: 'user', createdAt: { $gte: yesterdayStart, $lt: todayStart } }),
      User.countDocuments({ role: 'user', createdAt: { $gte: last7dStart } }),
      User.countDocuments({ role: 'user', createdAt: { $gte: prev7dStart, $lt: last7dStart } }),
      DashboardDailyStatService.countActiveUsersByDateKey(DashboardDailyStatService.currentDateKey()),
      DashboardDailyStatService.countDistinctActiveUsersInDays(7),
      DashboardDailyStatService.countDistinctActiveUsersInDays(30),
      DoubaoCallLog.countDocuments({ createdAt: { $gte: last30dStart } }),
      DoubaoCallLog.countDocuments({ createdAt: { $gte: todayStart } }),
      DoubaoCallLog.countDocuments({ createdAt: { $gte: yesterdayStart, $lt: todayStart } }),
      User.aggregate<{ _id: string; count: number }>([
        { $match: { role: 'user', createdAt: { $gte: daysAgo(60) } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
      ]),
      DashboardDailyStatService.getDailyStats(60),
      DoubaoCallLog.aggregate<{ _id: string; count: number; successCount: number }>([
        { $match: { createdAt: { $gte: daysAgo(60) } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
            successCount: { $sum: { $cond: ['$success', 1, 0] } },
          },
        },
      ]),
      DoubaoCallLog.aggregate<{ _id: string; count: number }>([
        { $match: { createdAt: { $gte: last30dStart } } },
        { $group: { _id: '$apiType', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
      DoubaoCallLog.aggregate<{ avgDuration: number; successRate: number }>([
        { $match: { createdAt: { $gte: last30dStart } } },
        {
          $group: {
            _id: null,
            avgDuration: { $avg: '$durationMs' },
            successRate: {
              $avg: {
                $cond: ['$success', 1, 0],
              },
            },
          },
        },
      ]),
      DoubaoCallLog.find({ createdAt: { $gte: last30dStart } })
        .select({ durationMs: 1, _id: 0 })
        .lean(),
    ]);

    const days60 = buildDateSeries(60);
    const userGrowthMap = new Map(userGrowthDaily.map((item) => [item._id, item.count]));
    const loginMap = new Map(dailyStats60.map((item) => [item.dateKey, item.activeUsers]));
    const doubaoDailyMap = new Map(doubaoDaily.map((item) => [item._id, item]));

    const growthSeries = days60.map((date) => ({
      date,
      newUsers: userGrowthMap.get(date) ?? 0,
      loginUsers: loginMap.get(date) ?? 0,
      doubaoCalls: doubaoDailyMap.get(date)?.count ?? 0,
      doubaoSuccessRate: Number((((doubaoDailyMap.get(date)?.successCount ?? 0) / Math.max(1, doubaoDailyMap.get(date)?.count ?? 0)) * 100).toFixed(1)),
    }));

    const latency = latencyAgg[0];
    const sortedDurations = durations30d
      .map((item) => Number(item.durationMs) || 0)
      .sort((a, b) => a - b);
    const p95Index = Math.max(0, Math.ceil(sortedDurations.length * 0.95) - 1);
    const p95Raw = sortedDurations[p95Index] ?? 0;

    return {
      snapshotAt: new Date(),
      metrics: {
        totalUsers,
        newUsersToday,
        newUsers7d,
        activeUsersToday,
        activeUsers7d,
        activeUsers30d,
        doubaoCallsToday: doubaoToday,
        doubaoCalls30d: doubao30d,
        doubaoSuccessRate30d: Number((((latency?.successRate ?? 0) * 100)).toFixed(1)),
        doubaoAvgLatencyMs30d: Math.round(latency?.avgDuration ?? 0),
        doubaoP95LatencyMs30d: Math.round(Number(p95Raw ?? 0)),
      },
      trends: {
        newUsersTodayVsYesterdayPct: calcPercentChange(newUsersToday, newUsersYesterday),
        newUsers7dVsPrev7dPct: calcPercentChange(newUsers7d, newUsersPrev7d),
        doubaoTodayVsYesterdayPct: calcPercentChange(doubaoToday, doubaoYesterday),
      },
      charts: {
        growth60d: growthSeries,
        doubaoApiMix30d: doubaoByApi.map((item) => ({ apiType: item._id, count: item.count })),
      },
    };
  }

  static isAdminUserId(userId: string): boolean {
    return userId.startsWith('admin:');
  }
}
