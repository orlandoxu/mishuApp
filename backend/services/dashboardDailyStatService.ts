import { DashboardDailyStat } from '../models/DashboardDailyStat';
import { DashboardDailyApiStat } from '../models/DashboardDailyApiStat';
import { DoubaoCallLog } from '../models/DoubaoCallLog';
import { User } from '../models/User';
import { UserDailyActivity } from '../models/UserDailyActivity';

const SHANGHAI_OFFSET_MS = 8 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

function toDateKey(date: Date): string {
  const utc = date.getTime() + SHANGHAI_OFFSET_MS;
  const d = new Date(utc);
  const y = d.getUTCFullYear();
  const m = `${d.getUTCMonth() + 1}`.padStart(2, '0');
  const day = `${d.getUTCDate()}`.padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function dateKeyToRange(dateKey: string): { start: Date; end: Date } {
  const [y, m, d] = dateKey.split('-').map(Number);
  const startUtc = Date.UTC(y, m - 1, d, 0, 0, 0, 0) - SHANGHAI_OFFSET_MS;
  return {
    start: new Date(startUtc),
    end: new Date(startUtc + DAY_MS),
  };
}

function shiftDateKey(dateKey: string, deltaDays: number): string {
  const { start } = dateKeyToRange(dateKey);
  return toDateKey(new Date(start.getTime() + deltaDays * DAY_MS));
}

function todayDateKey(): string {
  return toDateKey(new Date());
}

function isValidDateKey(dateKey: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(dateKey);
}

export class DashboardDailyStatService {
  private static async calculateDoubaoDailySummary(
    start: Date,
    end: Date,
  ): Promise<{ calls: number; successCalls: number; durationTotalMs: number; p95LatencyMs: number }> {
    const [rows, durations] = await Promise.all([
      DoubaoCallLog.aggregate<{ calls: number; successCalls: number; durationTotalMs: number }>([
        { $match: { createdAt: { $gte: start, $lt: end } } },
        {
          $group: {
            _id: null,
            calls: { $sum: 1 },
            successCalls: { $sum: { $cond: ['$success', 1, 0] } },
            durationTotalMs: { $sum: '$durationMs' },
          },
        },
      ]),
      DoubaoCallLog.find({ createdAt: { $gte: start, $lt: end } }).select({ durationMs: 1, _id: 0 }).lean(),
    ]);

    const sorted = durations.map((item) => Number(item.durationMs) || 0).sort((a, b) => a - b);
    const p95Index = Math.max(0, Math.ceil(sorted.length * 0.95) - 1);
    return {
      calls: rows[0]?.calls ?? 0,
      successCalls: rows[0]?.successCalls ?? 0,
      durationTotalMs: Math.round(Number(rows[0]?.durationTotalMs ?? 0)),
      p95LatencyMs: Math.round(Number(sorted[p95Index] ?? 0)),
    };
  }

  static currentDateKey(): string {
    return todayDateKey();
  }

  static async markUserActive(userId: string, activeAt: Date = new Date()): Promise<void> {
    await UserDailyActivity.markActive(userId, toDateKey(activeAt), activeAt);
  }

  static async generateSnapshot(dateKey: string): Promise<void> {
    const { start, end } = dateKeyToRange(dateKey);

    const active7dStartKey = shiftDateKey(dateKey, -6);
    const active30dStartKey = shiftDateKey(dateKey, -29);

    const [activeUsers, newUsers, doubaoDaily, doubaoApiRows, activeUsers7dRolling, activeUsers30dRolling] = await Promise.all([
      UserDailyActivity.countDocuments({ dateKey }),
      User.countDocuments({ role: 'user', createdAt: { $gte: start, $lt: end } }),
      this.calculateDoubaoDailySummary(start, end),
      DoubaoCallLog.aggregate<{ _id: string; calls: number; successCalls: number }>([
        { $match: { createdAt: { $gte: start, $lt: end } } },
        {
          $group: {
            _id: '$apiType',
            calls: { $sum: 1 },
            successCalls: { $sum: { $cond: ['$success', 1, 0] } },
          },
        },
      ]),
      UserDailyActivity.distinct('userId', { dateKey: { $gte: active7dStartKey, $lte: dateKey } }).then((rows) => rows.length),
      UserDailyActivity.distinct('userId', { dateKey: { $gte: active30dStartKey, $lte: dateKey } }).then((rows) => rows.length),
    ]);

    const doubaoCalls = doubaoDaily.calls;
    const doubaoSuccessCalls = doubaoDaily.successCalls;
    const doubaoDurationTotalMs = doubaoDaily.durationTotalMs;
    const doubaoP95LatencyMs = doubaoDaily.p95LatencyMs;

    await DashboardDailyStat.updateOne(
      { dateKey },
      {
        $set: {
          activeUsers,
          activeUsers7dRolling,
          activeUsers30dRolling,
          newUsers,
          doubaoCalls,
          doubaoSuccessCalls,
          doubaoDurationTotalMs,
          doubaoP95LatencyMs,
          generatedAt: new Date(),
        },
      },
      { upsert: true },
    );

    await DashboardDailyApiStat.deleteMany({ dateKey });
    if (doubaoApiRows.length > 0) {
      await DashboardDailyApiStat.insertMany(
        doubaoApiRows.map((row) => ({
          dateKey,
          apiType: row._id,
          calls: row.calls,
          successCalls: row.successCalls,
        })),
      );
    }
  }

  static async generateYesterdaySnapshot(): Promise<void> {
    const yesterdayKey = shiftDateKey(todayDateKey(), -1);
    await this.generateSnapshot(yesterdayKey);
  }

  static async generateTodaySnapshot(): Promise<void> {
    await this.generateSnapshot(todayDateKey());
  }

  static async generateSnapshotsInRange(startDateKey: string, endDateKey: string): Promise<number> {
    if (!isValidDateKey(startDateKey) || !isValidDateKey(endDateKey)) {
      throw new Error('dateKey 必须是 YYYY-MM-DD 格式');
    }
    if (startDateKey > endDateKey) {
      return 0;
    }

    let count = 0;
    let current = startDateKey;
    while (current <= endDateKey) {
      await this.generateSnapshot(current);
      count += 1;
      current = shiftDateKey(current, 1);
    }
    return count;
  }

  static async generateRecentSnapshots(days: number): Promise<number> {
    const totalDays = Math.max(1, Math.floor(days));
    const endKey = todayDateKey();
    const startKey = shiftDateKey(endKey, -(totalDays - 1));
    return this.generateSnapshotsInRange(startKey, endKey);
  }

  static recentDateKeys(days: number): string[] {
    const endKey = todayDateKey();
    const startKey = shiftDateKey(endKey, -(days - 1));
    const list: string[] = [];
    for (let i = 0; i < days; i += 1) {
      list.push(shiftDateKey(startKey, i));
    }
    return list;
  }

  static async countActiveUsersByDateKey(dateKey: string): Promise<number> {
    return UserDailyActivity.countDocuments({ dateKey });
  }

  static async countDistinctActiveUsersInDays(days: number): Promise<number> {
    const keys = this.recentDateKeys(days);
    const users = await UserDailyActivity.distinct('userId', { dateKey: { $in: keys } });
    return users.length;
  }

  static async getDailyStats(days: number): Promise<Array<{
    dateKey: string;
    activeUsers: number;
    activeUsers7dRolling: number;
    activeUsers30dRolling: number;
    newUsers: number;
    doubaoCalls: number;
    doubaoSuccessCalls: number;
    doubaoDurationTotalMs: number;
    doubaoP95LatencyMs: number;
  }>> {
    const endKey = todayDateKey();
    const startKey = shiftDateKey(endKey, -(days - 1));

    const docs = await DashboardDailyStat.find({
      dateKey: { $gte: startKey, $lte: endKey },
    })
      .sort({ dateKey: 1 })
      .lean();

    const map = new Map(docs.map((d) => [d.dateKey, d]));
    const list: Array<{
      dateKey: string;
      activeUsers: number;
      activeUsers7dRolling: number;
      activeUsers30dRolling: number;
      newUsers: number;
      doubaoCalls: number;
      doubaoSuccessCalls: number;
      doubaoDurationTotalMs: number;
      doubaoP95LatencyMs: number;
    }> = [];

    for (let i = 0; i < days; i += 1) {
      const key = shiftDateKey(startKey, i);
      const item = map.get(key);
      list.push({
        dateKey: key,
        activeUsers: item?.activeUsers ?? 0,
        activeUsers7dRolling: item?.activeUsers7dRolling ?? 0,
        activeUsers30dRolling: item?.activeUsers30dRolling ?? 0,
        newUsers: item?.newUsers ?? 0,
        doubaoCalls: item?.doubaoCalls ?? 0,
        doubaoSuccessCalls: item?.doubaoSuccessCalls ?? 0,
        doubaoDurationTotalMs: item?.doubaoDurationTotalMs ?? 0,
        doubaoP95LatencyMs: item?.doubaoP95LatencyMs ?? 0,
      });
    }

    return list;
  }

  static async getApiMixInDays(days: number): Promise<Array<{ apiType: string; calls: number }>> {
    const keys = this.recentDateKeys(days);
    const rows = await DashboardDailyApiStat.aggregate<{ _id: string; calls: number }>([
      { $match: { dateKey: { $in: keys } } },
      { $group: { _id: '$apiType', calls: { $sum: '$calls' } } },
      { $sort: { calls: -1 } },
    ]);
    return rows.map((row) => ({ apiType: row._id, calls: row.calls }));
  }
}
