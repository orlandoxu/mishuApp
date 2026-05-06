import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export interface IDashboardDailyStat extends Document {
  _id: Types.ObjectId;
  dateKey: string;
  activeUsers: number;
  newUsers: number;
  doubaoCalls: number;
  generatedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IDashboardDailyStatModel extends Model<IDashboardDailyStat> {}

const dashboardDailyStatSchema = new Schema<IDashboardDailyStat, IDashboardDailyStatModel>(
  {
    dateKey: { type: String, required: true, unique: true, index: true },
    activeUsers: { type: Number, required: true, min: 0 },
    newUsers: { type: Number, required: true, min: 0 },
    doubaoCalls: { type: Number, required: true, min: 0 },
    generatedAt: { type: Date, required: true },
  },
  {
    timestamps: true,
  },
);

export const DashboardDailyStat = mongoose.model<IDashboardDailyStat, IDashboardDailyStatModel>(
  'DashboardDailyStat',
  dashboardDailyStatSchema,
);
