import { DashboardDailyStat } from '../models/DashboardDailyStat';
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

export class DashboardDailyStatService {
  static currentDateKey(): string {
    return todayDateKey();
  }

  static async markUserActive(userId: string, activeAt: Date = new Date()): Promise<void> {
    await UserDailyActivity.markActive(userId, toDateKey(activeAt), activeAt);
  }

  static async generateSnapshot(dateKey: string): Promise<void> {
    const { start, end } = dateKeyToRange(dateKey);

    const [activeUsers, newUsers, doubaoCalls] = await Promise.all([
      UserDailyActivity.countDocuments({ dateKey }),
      User.countDocuments({ role: 'user', createdAt: { $gte: start, $lt: end } }),
      DoubaoCallLog.countDocuments({ createdAt: { $gte: start, $lt: end } }),
    ]);

    await DashboardDailyStat.updateOne(
      { dateKey },
      {
        $set: {
          activeUsers,
          newUsers,
          doubaoCalls,
          generatedAt: new Date(),
        },
      },
      { upsert: true },
    );
  }

  static async generateYesterdaySnapshot(): Promise<void> {
    const yesterdayKey = shiftDateKey(todayDateKey(), -1);
    await this.generateSnapshot(yesterdayKey);
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

  static async getDailyStats(days: number): Promise<Array<{ dateKey: string; activeUsers: number; newUsers: number; doubaoCalls: number }>> {
    const endKey = todayDateKey();
    const startKey = shiftDateKey(endKey, -(days - 1));

    const docs = await DashboardDailyStat.find({
      dateKey: { $gte: startKey, $lte: endKey },
    })
      .sort({ dateKey: 1 })
      .lean();

    const map = new Map(docs.map((d) => [d.dateKey, d]));
    const list: Array<{ dateKey: string; activeUsers: number; newUsers: number; doubaoCalls: number }> = [];

    for (let i = 0; i < days; i += 1) {
      const key = shiftDateKey(startKey, i);
      const item = map.get(key);
      list.push({
        dateKey: key,
        activeUsers: item?.activeUsers ?? 0,
        newUsers: item?.newUsers ?? 0,
        doubaoCalls: item?.doubaoCalls ?? 0,
      });
    }

    return list;
  }
}
