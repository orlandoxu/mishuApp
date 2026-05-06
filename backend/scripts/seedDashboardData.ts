import { connectMongoDB, disconnectMongoDB } from '../utils/database';
import { User } from '../models/User';
import { DoubaoCallLog, type DoubaoApiType } from '../models/DoubaoCallLog';

const DAY_MS = 24 * 60 * 60 * 1000;

function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick<T>(items: T[]): T {
  return items[randInt(0, items.length - 1)];
}

function randomDateInLastDays(days: number): Date {
  const now = Date.now();
  const start = now - days * DAY_MS;
  const skew = Math.pow(Math.random(), 1.6);
  return new Date(start + skew * (now - start));
}

function randomRecentLogin(createdAt: Date): Date | undefined {
  const silent = Math.random() < 0.15;
  if (silent) {
    return undefined;
  }

  const isHeavy = Math.random() < 0.32;
  const maxDays = isHeavy ? 5 : 45;
  const lastLogin = new Date(Date.now() - randInt(0, maxDays) * DAY_MS - randInt(0, 22) * 3600 * 1000);
  return lastLogin < createdAt ? createdAt : lastLogin;
}

function generateNonSequentialPhones(count: number): string[] {
  const prefixes = ['130', '131', '132', '133', '135', '136', '137', '138', '139', '147', '150', '151', '152', '155', '156', '157', '158', '159', '166', '171', '172', '173', '175', '176', '177', '178', '180', '181', '182', '183', '185', '186', '187', '188', '189', '191', '193', '195', '196', '197', '198', '199'];
  const set = new Set<string>();

  while (set.size < count) {
    const prefix = pick(prefixes);
    const tail = `${randInt(0, 99_999_999)}`.padStart(8, '0');
    set.add(`${prefix}${tail}`);
  }

  return Array.from(set);
}

function buildDoubaoLogTime(baseDate: Date): Date {
  const hour = randInt(7, 23);
  const minute = randInt(0, 59);
  const second = randInt(0, 59);
  const date = new Date(baseDate);
  date.setHours(hour, minute, second, randInt(0, 999));
  return date;
}

async function seedUsers(targetCount: number): Promise<void> {
  const phones = generateNonSequentialPhones(targetCount);
  const now = new Date();
  const existingUsers = await User.find({ phoneNumber: { $in: phones } })
    .select({ phoneNumber: 1, _id: 0 })
    .lean();
  const existingSet = new Set(existingUsers.map((item) => item.phoneNumber));
  const newDocs = phones
    .filter((phoneNumber) => !existingSet.has(phoneNumber))
    .map((phoneNumber) => {
      const createdAt = randomDateInLastDays(60);
      const lastLoginAt = randomRecentLogin(createdAt);
      const isActive = Math.random() > 0.04;
      return {
        phoneNumber,
        role: 'user',
        isActive,
        createdAt,
        updatedAt: now,
        ...(lastLoginAt ? { lastLoginAt } : {}),
      };
    });

  if (newDocs.length > 0) {
    await User.collection.insertMany(newDocs, { ordered: false });
  }

  const rebalanceOps = phones.map((phoneNumber) => {
    const createdAt = randomDateInLastDays(60);
    const lastLoginAt = randomRecentLogin(createdAt);
    const isActive = Math.random() > 0.04;

    return {
      updateOne: {
        filter: { phoneNumber },
        update: {
          $set: {
            isActive,
            createdAt,
            updatedAt: now,
            ...(lastLoginAt ? { lastLoginAt } : {}),
          },
        },
      },
    };
  });

  if (rebalanceOps.length > 0) {
    await User.collection.bulkWrite(rebalanceOps, { ordered: false });
  }
}

async function seedDoubaoLogs(targetCount: number): Promise<void> {
  const apiTypes: DoubaoApiType[] = ['chat_completion', 'chat_completion_stream', 'chat_completion_json', 'embedding'];
  const models = ['doubao-seed-2-0-mini-260215', 'doubao-pro-32k', 'doubao-lite-4k', 'doubao-embedding'];

  const docs = Array.from({ length: targetCount }).map(() => {
    const baseDate = randomDateInLastDays(60);
    const createdAt = buildDoubaoLogTime(baseDate);
    const apiType = pick(apiTypes);
    const success = Math.random() > 0.08;
    const durationBase = apiType === 'embedding' ? randInt(40, 260) : randInt(180, 1800);
    const durationMs = Math.max(20, Math.round(durationBase * (0.8 + Math.random() * 0.7)));

    return {
      apiType,
      modelId: pick(models),
      requestPayload: {
        traceId: `trace_${Math.random().toString(36).slice(2, 10)}`,
        tokens: randInt(40, 2200),
      },
      responsePayload: success ? { finishReason: 'stop', score: Math.random() } : undefined,
      responseText: success ? 'ok' : undefined,
      errorMessage: success ? undefined : pick(['timeout', 'rate_limited', 'upstream_500']),
      durationMs,
      success,
      createdAt,
      updatedAt: createdAt,
    };
  });

  if (docs.length > 0) {
    await DoubaoCallLog.insertMany(docs, { ordered: false });
  }
}

async function rebalanceTodaySpike(maxUsers: number): Promise<void> {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const users = await User.find({ role: 'user', createdAt: { $gte: todayStart } })
    .select({ _id: 1 })
    .limit(maxUsers)
    .lean();

  if (users.length === 0) {
    return;
  }

  const tasks = users.map(async (user) => {
    const createdAt = randomDateInLastDays(60);
    const lastLoginAt = randomRecentLogin(createdAt);
    await User.updateOne(
      { _id: user._id },
      {
        $set: {
          createdAt,
          ...(lastLoginAt ? { lastLoginAt } : { lastLoginAt: null }),
        },
      },
      {
        overwriteImmutable: true,
        timestamps: false,
      },
    );
  });
  await Promise.all(tasks);
}

async function main() {
  const userCount = Number(process.argv[2] ?? 1800);
  const doubaoCount = Number(process.argv[3] ?? 12000);

  if (!Number.isFinite(userCount) || userCount < 1000 || userCount > 50000) {
    throw new Error('userCount 必须在 1000-50000 之间');
  }
  if (!Number.isFinite(doubaoCount) || doubaoCount < 1000 || doubaoCount > 200000) {
    throw new Error('doubaoCount 必须在 1000-200000 之间');
  }

  await connectMongoDB();

  try {
    await seedUsers(userCount);
    await seedDoubaoLogs(doubaoCount);
    await rebalanceTodaySpike(userCount * 2);

    const [users, logs] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      DoubaoCallLog.countDocuments({}),
    ]);

    console.log(`Seed completed. users=${users}, doubaoLogs=${logs}`);
  } finally {
    await disconnectMongoDB();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
