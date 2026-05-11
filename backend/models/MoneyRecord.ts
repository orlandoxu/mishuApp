import mongoose, { Document, Model, Schema, Types } from "mongoose";

export type LedgerDirection = "income" | "expense";

export interface IMoneyRecord extends Document {
  _id: Types.ObjectId;
  userId: string;
  requestKey: string;
  direction: LedgerDirection;
  amount: number;
  category: string;
  note?: string;
  occurredAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IMoneyRecordModel extends Model<IMoneyRecord> {}

const moneyRecordSchema = new Schema<IMoneyRecord, IMoneyRecordModel>(
  {
    userId: { type: String, required: true, trim: true },
    requestKey: { type: String, required: true, trim: true },
    direction: { type: String, enum: ["income", "expense"], required: true },
    amount: { type: Number, required: true, min: 0 },
    category: { type: String, required: true, trim: true, default: "其他" },
    note: { type: String, trim: true },
    occurredAt: { type: Date, required: true },
  },
  { timestamps: true },
);

moneyRecordSchema.index({ userId: 1, occurredAt: -1 });
moneyRecordSchema.index({ userId: 1, direction: 1, occurredAt: -1 });
moneyRecordSchema.index({ userId: 1, category: 1, occurredAt: -1 });
moneyRecordSchema.index({ userId: 1, requestKey: 1 }, { unique: true });

export const MoneyRecord = mongoose.model<IMoneyRecord, IMoneyRecordModel>(
  "MoneyRecord",
  moneyRecordSchema,
  "money_records",
);
