import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export interface IDashboardDailyStat extends Document {
  _id: Types.ObjectId;
  dateKey: string;
  activeUsers: number;
  activeUsers7dRolling: number;
  activeUsers30dRolling: number;
  newUsers: number;
  doubaoCalls: number;
  doubaoSuccessCalls: number;
  doubaoDurationTotalMs: number;
  doubaoP95LatencyMs: number;
  generatedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IDashboardDailyStatModel extends Model<IDashboardDailyStat> {}

const dashboardDailyStatSchema = new Schema<IDashboardDailyStat, IDashboardDailyStatModel>(
  {
    dateKey: { type: String, required: true, unique: true, index: true },
    activeUsers: { type: Number, required: true, min: 0 },
    activeUsers7dRolling: { type: Number, required: true, min: 0, default: 0 },
    activeUsers30dRolling: { type: Number, required: true, min: 0, default: 0 },
    newUsers: { type: Number, required: true, min: 0 },
    doubaoCalls: { type: Number, required: true, min: 0 },
    doubaoSuccessCalls: { type: Number, required: true, min: 0, default: 0 },
    doubaoDurationTotalMs: { type: Number, required: true, min: 0, default: 0 },
    doubaoP95LatencyMs: { type: Number, required: true, min: 0, default: 0 },
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
