import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export interface IDashboardDailyApiStat extends Document {
  _id: Types.ObjectId;
  dateKey: string;
  apiType: string;
  calls: number;
  successCalls: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface IDashboardDailyApiStatModel extends Model<IDashboardDailyApiStat> {}

const dashboardDailyApiStatSchema = new Schema<IDashboardDailyApiStat, IDashboardDailyApiStatModel>(
  {
    dateKey: { type: String, required: true, index: true },
    apiType: { type: String, required: true, index: true },
    calls: { type: Number, required: true, min: 0 },
    successCalls: { type: Number, required: true, min: 0, default: 0 },
  },
  {
    timestamps: true,
  },
);

dashboardDailyApiStatSchema.index({ dateKey: 1, apiType: 1 }, { unique: true });
dashboardDailyApiStatSchema.index({ dateKey: 1, calls: -1 });

export const DashboardDailyApiStat = mongoose.model<IDashboardDailyApiStat, IDashboardDailyApiStatModel>(
  'DashboardDailyApiStat',
  dashboardDailyApiStatSchema,
);
