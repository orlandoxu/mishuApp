import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export type FoodMemoryStatus = 'active' | 'deleted';

export interface IFoodMemory extends Document {
  _id: Types.ObjectId;
  userId: string;
  name: string;
  category: string;
  pricePerPerson: number;
  visitedAt: Date;
  rating: number;
  features: string[];
  signatureDishes: string[];
  avoidDishes: string[];
  review: string;
  photos: string[];
  lat: number;
  lng: number;
  address: string;
  sort: number;
  status: FoodMemoryStatus;
  deletedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IFoodMemoryModel extends Model<IFoodMemory> {}

const foodMemorySchema = new Schema<IFoodMemory, IFoodMemoryModel>(
  {
    userId: { type: String, required: true, trim: true, index: true },
    name: { type: String, required: true, trim: true },
    category: { type: String, required: true, trim: true },
    pricePerPerson: { type: Number, required: true, min: 0 },
    visitedAt: { type: Date, required: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    features: { type: [String], default: [] },
    signatureDishes: { type: [String], default: [] },
    avoidDishes: { type: [String], default: [] },
    review: { type: String, trim: true, default: '' },
    photos: { type: [String], default: [] },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    address: { type: String, trim: true, default: '' },
    sort: { type: Number, default: 0 },
    status: { type: String, enum: ['active', 'deleted'], default: 'active', index: true },
    deletedAt: { type: Date },
  },
  { timestamps: true },
);

foodMemorySchema.index({ userId: 1, status: 1, updatedAt: -1 });
foodMemorySchema.index({ userId: 1, visitedAt: -1 });
foodMemorySchema.index({ userId: 1, category: 1, visitedAt: -1 });
foodMemorySchema.index({ userId: 1, lat: 1, lng: 1 });

export const FoodMemory = mongoose.model<IFoodMemory, IFoodMemoryModel>(
  'FoodMemory',
  foodMemorySchema,
  'food_memories',
);
