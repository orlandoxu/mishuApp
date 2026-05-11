import { MoneyRecord, type LedgerDirection } from "../models/MoneyRecord";
import { MoneyCategoryService } from "./moneyCategoryService";

type RecordLedgerInput = {
  userId: string;
  requestKey: string;
  direction: LedgerDirection;
  amount: number;
  category: string;
  note?: string;
  occurredAt: number;
};

type QueryPeriod = "day" | "week" | "month";

export type LedgerListItem = {
  id: string;
  direction: LedgerDirection;
  amount: number;
  category: string;
  note?: string;
  occurredAt: number;
};

export class LedgerService {
  static async record(input: RecordLedgerInput): Promise<{
    item: LedgerListItem;
    isRepeat: boolean;
  }> {
    const existed = await MoneyRecord.findOne({
      userId: input.userId,
      requestKey: input.requestKey,
    }).lean();
    if (existed) {
      return {
        isRepeat: true,
        item: toListItem(existed),
      };
    }

    const category = await MoneyCategoryService.resolveCategory({
      userId: input.userId,
      direction: input.direction,
      suggested: input.category,
      originalText: input.note,
    });

    const created = await MoneyRecord.create({
      userId: input.userId,
      requestKey: input.requestKey,
      direction: input.direction,
      amount: input.amount,
      category,
      note: input.note,
      occurredAt: new Date(input.occurredAt),
    });
    return {
      isRepeat: false,
      item: toListItem(created.toObject()),
    };
  }

  static async query(args: {
    userId: string;
    startAtMs: number;
    endAtMs: number;
    limit?: number;
  }): Promise<{ items: LedgerListItem[] }> {
    await MoneyCategoryService.ensureDefaults(args.userId);
    const limit = Math.max(1, Math.min(500, args.limit ?? 200));
    const docs = await MoneyRecord.find({
      userId: args.userId,
      occurredAt: {
        $gte: new Date(args.startAtMs),
        $lte: new Date(args.endAtMs),
      },
    })
      .sort({ occurredAt: -1 })
      .limit(limit)
      .lean();
    return { items: docs.map(toListItem) };
  }

  static async summary(args: {
    userId: string;
    period: QueryPeriod;
    timezone?: string;
  }): Promise<{
    period: QueryPeriod;
    startAtMs: number;
    endAtMs: number;
    incomeTotal: number;
    expenseTotal: number;
    byCategory: Record<string, number>;
  }> {
    await MoneyCategoryService.ensureDefaults(args.userId);
    const range = resolveRange(args.period);
    const docs = await MoneyRecord.find({
      userId: args.userId,
      occurredAt: { $gte: new Date(range.startAtMs), $lte: new Date(range.endAtMs) },
    }).lean();

    let incomeTotal = 0;
    let expenseTotal = 0;
    const byCategory: Record<string, number> = {};
    for (const item of docs) {
      if (item.direction === "income") {
        incomeTotal += item.amount;
      } else {
        expenseTotal += item.amount;
        byCategory[item.category] = (byCategory[item.category] ?? 0) + item.amount;
      }
    }
    return {
      period: args.period,
      startAtMs: range.startAtMs,
      endAtMs: range.endAtMs,
      incomeTotal: round2(incomeTotal),
      expenseTotal: round2(expenseTotal),
      byCategory: Object.fromEntries(Object.entries(byCategory).map(([k, v]) => [k, round2(v)])),
    };
  }
}

function toListItem(doc: {
  _id: unknown;
  direction: LedgerDirection;
  amount: number;
  category: string;
  note?: string;
  occurredAt: Date;
}): LedgerListItem {
  return {
    id: String(doc._id),
    direction: doc.direction,
    amount: round2(doc.amount),
    category: doc.category,
    note: doc.note,
    occurredAt: new Date(doc.occurredAt).getTime(),
  };
}

function resolveRange(period: QueryPeriod): { startAtMs: number; endAtMs: number } {
  const now = new Date();
  const start = new Date(now);
  if (period === "month") {
    start.setDate(1);
  } else if (period === "week") {
    const day = start.getDay() || 7;
    start.setDate(start.getDate() - day + 1);
  }
  start.setHours(0, 0, 0, 0);
  const end = new Date(now);
  end.setHours(23, 59, 59, 999);
  return { startAtMs: start.getTime(), endAtMs: end.getTime() };
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
