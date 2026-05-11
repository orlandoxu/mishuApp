import type { LedgerDirection } from "../models/MoneyRecord";
import { MoneyCategory } from "../models/MoneyCategory";

const DEFAULT_EXPENSE = ["餐饮", "交通", "购物", "娱乐", "居住", "教育", "医疗", "其他"];
const DEFAULT_INCOME = ["工资", "兼职", "理财", "红包", "其他"];

type CategoryItem = {
  id: string;
  direction: LedgerDirection;
  name: string;
  canEdit: boolean;
  deleted: boolean;
  sort: number;
};

type CategoryDocShape = {
  _id: unknown;
  direction: LedgerDirection;
  name: string;
  canEdit?: boolean;
  deleted?: boolean;
  sort?: number;
};

export class MoneyCategoryService {
  static async ensureDefaults(userId: string): Promise<void> {
    await this.ensureDirectionDefaults(userId, "expense", DEFAULT_EXPENSE);
    await this.ensureDirectionDefaults(userId, "income", DEFAULT_INCOME);
  }

  static async listActive(userId: string): Promise<{ expense: CategoryItem[]; income: CategoryItem[] }> {
    await this.ensureDefaults(userId);
    const docs = await MoneyCategory.find({ userId, deleted: false }).sort({ direction: 1, sort: 1, createdAt: 1 }).lean();
    const expense: CategoryItem[] = [];
    const income: CategoryItem[] = [];
    for (const doc of docs) {
      const item = toItem(doc);
      if (item.direction === "expense") expense.push(item);
      else income.push(item);
    }
    return { expense, income };
  }

  static async replaceDirectionCategories(args: {
    userId: string;
    direction: LedgerDirection;
    names: string[];
  }): Promise<CategoryItem[]> {
    await this.ensureDefaults(args.userId);
    const normalizedNames = normalizeNames(args.names);
    const keepNames = new Set(normalizedNames);

    const defaults = args.direction === "expense" ? DEFAULT_EXPENSE : DEFAULT_INCOME;
    const all = await MoneyCategory.find({ userId: args.userId, direction: args.direction }).lean();

    for (const defaultName of defaults) {
      if (!keepNames.has(defaultName)) {
        keepNames.add(defaultName);
      }
    }

    const canDeleteDocs = all.filter((x) => x.canEdit);
    const lockedDocs = all.filter((x) => !x.canEdit);

    for (const doc of canDeleteDocs) {
      if (!keepNames.has(doc.name) && doc.name !== "其他") {
        await MoneyCategory.updateOne({ _id: doc._id }, { $set: { deleted: true } });
      }
    }

    let sort = 1;
    for (const name of normalizedNames) {
      if (name === "其他") continue;
      const existed = all.find((x) => x.name === name);
      if (existed) {
        await MoneyCategory.updateOne({ _id: existed._id }, { $set: { deleted: false, sort } });
      } else {
        await MoneyCategory.create({
          userId: args.userId,
          direction: args.direction,
          name,
          canEdit: true,
          deleted: false,
          sort,
        });
      }
      sort += 1;
    }

    // 兜底把“其他”放最后，且不可编辑
    const other = all.find((x) => x.name === "其他") ?? lockedDocs.find((x) => x.name === "其他");
    if (other) {
      await MoneyCategory.updateOne({ _id: other._id }, { $set: { deleted: false, sort: 9_999, canEdit: false } });
    } else {
      await MoneyCategory.create({
        userId: args.userId,
        direction: args.direction,
        name: "其他",
        canEdit: false,
        deleted: false,
        sort: 9_999,
      });
    }

    const next = await MoneyCategory.find({ userId: args.userId, direction: args.direction, deleted: false }).sort({ sort: 1, createdAt: 1 }).lean();
    return next.map(toItem);
  }

  static async resolveCategory(args: {
    userId: string;
    direction: LedgerDirection;
    suggested?: string;
    originalText?: string;
  }): Promise<string> {
    const active = await this.listActive(args.userId);
    const names = (args.direction === "expense" ? active.expense : active.income).map((x) => x.name);
    if (names.length === 0) return "其他";

    const cleanedSuggested = (args.suggested ?? "").trim();
    if (cleanedSuggested && names.includes(cleanedSuggested)) return cleanedSuggested;

    const text = (args.originalText ?? "").toLowerCase();
    for (const name of names) {
      if (text.includes(name.toLowerCase())) return name;
    }

    if (args.direction === "expense") {
      if (hasAny(text, ["打车", "出租", "公交", "地铁", "taxi", "bus", "subway", "transport"])) {
        return names.includes("交通") ? "交通" : fallbackName(names);
      }
      if (hasAny(text, ["吃", "饭", "餐", "外卖", "food", "meal", "coffee"])) {
        return names.includes("餐饮") ? "餐饮" : fallbackName(names);
      }
      if (hasAny(text, ["房租", "租", "水电", "居住", "rent", "house"])) {
        return names.includes("居住") ? "居住" : fallbackName(names);
      }
      if (hasAny(text, ["学习", "课程", "教育", "school", "course"])) {
        return names.includes("教育") ? "教育" : fallbackName(names);
      }
      if (hasAny(text, ["医院", "药", "医疗", "doctor", "medical"])) {
        return names.includes("医疗") ? "医疗" : fallbackName(names);
      }
    } else {
      if (hasAny(text, ["工资", "salary"])) return names.includes("工资") ? "工资" : fallbackName(names);
      if (hasAny(text, ["兼职", "part", "freelance"])) return names.includes("兼职") ? "兼职" : fallbackName(names);
    }

    return fallbackName(names);
  }

  private static async ensureDirectionDefaults(userId: string, direction: LedgerDirection, defaults: string[]): Promise<void> {
    const existing = await MoneyCategory.find({ userId, direction }).lean();
    const existingNames = new Set(existing.map((x) => x.name));
    let sort = 1;
    for (const name of defaults) {
      const canEdit = name !== "其他";
      if (!existingNames.has(name)) {
        await MoneyCategory.create({ userId, direction, name, canEdit, deleted: false, sort: canEdit ? sort : 9_999 });
      } else {
        await MoneyCategory.updateOne(
          { userId, direction, name },
          { $set: { deleted: false, canEdit, sort: canEdit ? sort : 9_999 } },
        );
      }
      sort += 1;
    }
  }
}

function normalizeNames(names: string[]): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const raw of names) {
    const name = raw.trim();
    if (!name || name.length > 12) continue;
    if (seen.has(name)) continue;
    seen.add(name);
    out.push(name);
  }
  return out;
}

function fallbackName(names: string[]): string {
  if (names.includes("其他")) return "其他";
  return names[0] ?? "其他";
}

function hasAny(text: string, words: string[]): boolean {
  return words.some((w) => text.includes(w));
}

function toItem(doc: CategoryDocShape): CategoryItem {
  return {
    id: String(doc._id),
    direction: doc.direction,
    name: doc.name,
    canEdit: Boolean(doc.canEdit),
    deleted: Boolean(doc.deleted),
    sort: Number(doc.sort ?? 0),
  };
}
