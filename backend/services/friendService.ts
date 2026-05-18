import { FriendInteraction } from '../models/FriendInteraction';
import { FriendProfile } from '../models/FriendProfile';

export type FriendInteractionDTO = {
  id: string;
  date: string;
  type: string;
  desc: string;
};

export type FriendDTO = {
  id: string;
  name: string;
  shortName: string;
  age: number;
  gender: string;
  role: string;
  avatarText: string;
  isStarred: boolean;
  starredAt?: string;
  tags: string[];
  birthday?: string;
  relationship?: string;
  preferences: string[];
  resources: string[];
  insight: string;
  interactions: FriendInteractionDTO[];
};

function toInteraction(item: any): FriendInteractionDTO {
  return {
    id: String(item._id),
    date: item.date,
    type: item.type,
    desc: item.desc,
  };
}

function toFriend(item: any, interactions: FriendInteractionDTO[]): FriendDTO {
  return {
    id: String(item._id),
    name: item.name,
    shortName: item.shortName,
    age: item.age,
    gender: item.gender,
    role: item.role,
    avatarText: item.avatarText,
    isStarred: item.isStarred,
    starredAt: item.starredAt ? new Date(item.starredAt).toISOString() : undefined,
    tags: item.tags ?? [],
    birthday: item.birthday || undefined,
    relationship: item.relationship || undefined,
    preferences: item.preferences ?? [],
    resources: item.resources ?? [],
    insight: item.insight ?? '',
    interactions,
  };
}

export class FriendService {
  static async list(args: {
    userId: string;
    keyword?: string;
    starredOnly?: boolean;
    page?: number;
    pageSize?: number;
  }): Promise<{ items: FriendDTO[]; total: number; page: number; pageSize: number }> {
    const page = Math.max(1, args.page ?? 1);
    const pageSize = Math.max(1, Math.min(100, args.pageSize ?? 100));
    const filter: any = { userId: args.userId, status: 'active' };
    if (args.starredOnly) {
      filter.isStarred = true;
    }
    const keyword = (args.keyword ?? '').trim();
    if (keyword) {
      filter.$or = [
        { name: { $regex: keyword, $options: 'i' } },
        { role: { $regex: keyword, $options: 'i' } },
        { tags: { $elemMatch: { $regex: keyword, $options: 'i' } } },
        { resources: { $elemMatch: { $regex: keyword, $options: 'i' } } },
      ];
    }

    const [docs, total] = await Promise.all([
      FriendProfile.find(filter)
        .sort({ isStarred: -1, starredAt: -1, updatedAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .lean(),
      FriendProfile.countDocuments(filter),
    ]);

    const friendIds = docs.map((d) => String(d._id));
    const interactionDocs = await FriendInteraction.find({
      userId: args.userId,
      friendId: { $in: friendIds },
      status: 'active',
    })
      .sort({ date: -1, createdAt: -1 })
      .lean();

    const interactionMap = new Map<string, FriendInteractionDTO[]>();
    for (const doc of interactionDocs) {
      const key = String(doc.friendId);
      const list = interactionMap.get(key) ?? [];
      list.push(toInteraction(doc));
      interactionMap.set(key, list);
    }

    return {
      items: docs.map((doc) => toFriend(doc, interactionMap.get(String(doc._id)) ?? [])),
      total,
      page,
      pageSize,
    };
  }

  static async detail(userId: string, friendId: string): Promise<FriendDTO | null> {
    const doc = await FriendProfile.findOne({ _id: friendId, userId }).lean();
    if (!doc) return null;
    const interactions = await FriendInteraction.find({ userId, friendId, status: 'active' })
      .sort({ date: -1, createdAt: -1 })
      .lean();
    return toFriend(doc, interactions.map(toInteraction));
  }

  static async create(args: {
    userId: string;
    name: string;
    shortName: string;
    age: number;
    gender: string;
    role: string;
    avatarText: string;
    tags?: string[];
    birthday?: string;
    relationship?: string;
    preferences?: string[];
    resources?: string[];
    insight?: string;
    isStarred?: boolean;
  }): Promise<FriendDTO> {
    const now = new Date();
    const created = await FriendProfile.create({
      userId: args.userId,
      name: args.name,
      shortName: args.shortName,
      age: args.age,
      gender: args.gender,
      role: args.role,
      avatarText: args.avatarText,
      tags: args.tags ?? [],
      birthday: args.birthday,
      relationship: args.relationship,
      preferences: args.preferences ?? [],
      resources: args.resources ?? [],
      insight: args.insight ?? '',
      isStarred: args.isStarred ?? false,
      starredAt: args.isStarred ? now : undefined,
    });
    return toFriend(created.toObject(), []);
  }

  static async update(args: {
    userId: string;
    friendId: string;
    name?: string;
    shortName?: string;
    age?: number;
    gender?: string;
    role?: string;
    avatarText?: string;
    tags?: string[];
    birthday?: string;
    relationship?: string;
    preferences?: string[];
    resources?: string[];
    insight?: string;
    isStarred?: boolean;
  }): Promise<FriendDTO | null> {
    const setData: any = {};
    const keys = ['name', 'shortName', 'age', 'gender', 'role', 'avatarText', 'tags', 'birthday', 'relationship', 'preferences', 'resources', 'insight'];
    for (const key of keys) {
      const value = (args as any)[key];
      if (value !== undefined) setData[key] = value;
    }
    if (args.isStarred !== undefined) {
      setData.isStarred = args.isStarred;
      setData.starredAt = args.isStarred ? new Date() : null;
    }
    const updated = await FriendProfile.findOneAndUpdate(
      { _id: args.friendId, userId: args.userId, status: 'active' },
      { $set: setData },
      { new: true },
    ).lean();
    if (!updated) return null;
    const interactions = await FriendInteraction.find({ userId: args.userId, friendId: args.friendId, status: 'active' })
      .sort({ date: -1, createdAt: -1 })
      .lean();
    return toFriend(updated, interactions.map(toInteraction));
  }

  static async remove(userId: string, friendId: string): Promise<boolean> {
    const result = await FriendProfile.updateOne(
      { _id: friendId, userId, status: 'active' },
      { $set: { status: 'deleted', deletedAt: new Date() } },
    );
    await FriendInteraction.updateMany(
      { userId, friendId, status: 'active' },
      { $set: { status: 'deleted', deletedAt: new Date() } },
    );
    return result.modifiedCount > 0;
  }

  static async createInteraction(args: {
    userId: string;
    friendId: string;
    date: string;
    type: string;
    desc: string;
  }): Promise<FriendInteractionDTO> {
    const created = await FriendInteraction.create({
      userId: args.userId,
      friendId: args.friendId,
      date: args.date,
      type: args.type,
      desc: args.desc,
    });
    return toInteraction(created.toObject());
  }

  static async listInteractions(userId: string, friendId: string): Promise<FriendInteractionDTO[]> {
    const docs = await FriendInteraction.find({ userId, friendId, status: 'active' })
      .sort({ date: -1, createdAt: -1 })
      .lean();
    return docs.map(toInteraction);
  }

  static async updateInteraction(args: {
    userId: string;
    interactionId: string;
    date?: string;
    type?: string;
    desc?: string;
  }): Promise<FriendInteractionDTO | null> {
    const setData: any = {};
    if (args.date !== undefined) setData.date = args.date;
    if (args.type !== undefined) setData.type = args.type;
    if (args.desc !== undefined) setData.desc = args.desc;

    const updated = await FriendInteraction.findOneAndUpdate(
      { _id: args.interactionId, userId: args.userId, status: 'active' },
      { $set: setData },
      { new: true },
    ).lean();
    return updated ? toInteraction(updated) : null;
  }

  static async removeInteraction(userId: string, interactionId: string): Promise<boolean> {
    const result = await FriendInteraction.updateOne(
      { _id: interactionId, userId, status: 'active' },
      { $set: { status: 'deleted', deletedAt: new Date() } },
    );
    return result.modifiedCount > 0;
  }
}
