import { FoodMemory } from '../models/FoodMemory';

export type FoodMemoryDTO = {
  id: string;
  name: string;
  category: string;
  pricePerPerson: number;
  visitedAt: number;
  rating: number;
  features: string[];
  signatureDishes: string[];
  avoidDishes: string[];
  review: string;
  photos: string[];
  lat: number;
  lng: number;
  address: string;
};

function toDTO(doc: any): FoodMemoryDTO {
  return {
    id: String(doc._id),
    name: doc.name,
    category: doc.category,
    pricePerPerson: doc.pricePerPerson,
    visitedAt: new Date(doc.visitedAt).getTime(),
    rating: doc.rating,
    features: doc.features ?? [],
    signatureDishes: doc.signatureDishes ?? [],
    avoidDishes: doc.avoidDishes ?? [],
    review: doc.review ?? '',
    photos: doc.photos ?? [],
    lat: doc.lat,
    lng: doc.lng,
    address: doc.address ?? '',
  };
}

export class FoodMemoryService {
  static async list(args: {
    userId: string;
    category?: string;
    month?: string;
    page?: number;
    pageSize?: number;
    minLat?: number;
    maxLat?: number;
    minLng?: number;
    maxLng?: number;
  }): Promise<{ items: FoodMemoryDTO[]; total: number; page: number; pageSize: number }> {
    const page = Math.max(1, args.page ?? 1);
    const pageSize = Math.max(1, Math.min(100, args.pageSize ?? 100));
    const filter: any = { userId: args.userId, status: 'active' };
    if (args.category && args.category !== '全部') {
      filter.category = args.category;
    }
    if (args.month) {
      const [y, m] = args.month.split('/').map((n) => Number(n));
      if (y > 0 && m > 0) {
        const start = new Date(Date.UTC(y, m - 1, 1));
        const end = new Date(Date.UTC(y, m, 1));
        filter.visitedAt = { $gte: start, $lt: end };
      }
    }
    if (args.minLat !== undefined && args.maxLat !== undefined && args.minLng !== undefined && args.maxLng !== undefined) {
      filter.lat = { $gte: args.minLat, $lte: args.maxLat };
      filter.lng = { $gte: args.minLng, $lte: args.maxLng };
    }

    const [docs, total] = await Promise.all([
      FoodMemory.find(filter).sort({ visitedAt: -1, updatedAt: -1 }).skip((page - 1) * pageSize).limit(pageSize).lean(),
      FoodMemory.countDocuments(filter),
    ]);

    return { items: docs.map(toDTO), total, page, pageSize };
  }

  static async detail(userId: string, id: string): Promise<FoodMemoryDTO | null> {
    const doc = await FoodMemory.findOne({ _id: id, userId }).lean();
    return doc ? toDTO(doc) : null;
  }

  static async create(args: {
    userId: string;
    name: string;
    category: string;
    pricePerPerson: number;
    visitedAt: number;
    rating: number;
    features?: string[];
    signatureDishes?: string[];
    avoidDishes?: string[];
    review?: string;
    photos?: string[];
    lat: number;
    lng: number;
    address?: string;
  }): Promise<FoodMemoryDTO> {
    const created = await FoodMemory.create({
      userId: args.userId,
      name: args.name,
      category: args.category,
      pricePerPerson: args.pricePerPerson,
      visitedAt: new Date(args.visitedAt),
      rating: args.rating,
      features: args.features ?? [],
      signatureDishes: args.signatureDishes ?? [],
      avoidDishes: args.avoidDishes ?? [],
      review: args.review ?? '',
      photos: args.photos ?? [],
      lat: args.lat,
      lng: args.lng,
      address: args.address ?? '',
    });
    return toDTO(created.toObject());
  }

  static async update(args: {
    userId: string;
    id: string;
    name?: string;
    category?: string;
    pricePerPerson?: number;
    visitedAt?: number;
    rating?: number;
    features?: string[];
    signatureDishes?: string[];
    avoidDishes?: string[];
    review?: string;
    photos?: string[];
    lat?: number;
    lng?: number;
    address?: string;
  }): Promise<FoodMemoryDTO | null> {
    const setData: any = {};
    const keys = ['name', 'category', 'pricePerPerson', 'rating', 'features', 'signatureDishes', 'avoidDishes', 'review', 'photos', 'lat', 'lng', 'address'];
    for (const key of keys) {
      const value = (args as any)[key];
      if (value !== undefined) setData[key] = value;
    }
    if (args.visitedAt !== undefined) setData.visitedAt = new Date(args.visitedAt);

    const updated = await FoodMemory.findOneAndUpdate(
      { _id: args.id, userId: args.userId, status: 'active' },
      { $set: setData },
      { new: true },
    ).lean();
    return updated ? toDTO(updated) : null;
  }

  static async remove(userId: string, id: string): Promise<boolean> {
    const result = await FoodMemory.updateOne(
      { _id: id, userId, status: 'active' },
      { $set: { status: 'deleted', deletedAt: new Date() } },
    );
    return result.modifiedCount > 0;
  }

  static async categories(userId: string): Promise<string[]> {
    const rows = await FoodMemory.aggregate<{ _id: string }>([
      { $match: { userId, status: 'active' } },
      { $group: { _id: '$category' } },
      { $sort: { _id: 1 } },
    ]);
    return rows.map((r) => r._id).filter(Boolean);
  }

  static async months(userId: string): Promise<Array<{ month: string; count: number }>> {
    const rows = await FoodMemory.aggregate<{ _id: { y: number; m: number }; count: number }>([
      { $match: { userId, status: 'active' } },
      {
        $group: {
          _id: {
            y: { $year: '$visitedAt' },
            m: { $month: '$visitedAt' },
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.y': -1, '_id.m': -1 } },
    ]);

    return rows.map((row) => ({
      month: `${row._id.y}/${String(row._id.m).padStart(2, '0')}`,
      count: row.count,
    }));
  }
}
