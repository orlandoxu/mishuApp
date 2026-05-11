import mongoose, { Document, Model, Schema, Types } from "mongoose";
import type { LedgerDirection } from "./MoneyRecord";

export interface IMoneyCategory extends Document {
  _id: Types.ObjectId;
  userId: string;
  direction: LedgerDirection;
  name: string;
  canEdit: boolean;
  deleted: boolean;
  sort: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface IMoneyCategoryModel extends Model<IMoneyCategory> {}

const moneyCategorySchema = new Schema<IMoneyCategory, IMoneyCategoryModel>(
  {
    userId: { type: String, required: true, trim: true },
    direction: { type: String, enum: ["income", "expense"], required: true },
    name: { type: String, required: true, trim: true },
    canEdit: { type: Boolean, required: true, default: true },
    deleted: { type: Boolean, required: true, default: false },
    sort: { type: Number, required: true, default: 0 },
  },
  { timestamps: true },
);

moneyCategorySchema.index({ userId: 1, direction: 1, name: 1 }, { unique: true });
moneyCategorySchema.index({ userId: 1, direction: 1, deleted: 1, sort: 1 });

export const MoneyCategory = mongoose.model<IMoneyCategory, IMoneyCategoryModel>(
  "MoneyCategory",
  moneyCategorySchema,
  "money_categories",
);
