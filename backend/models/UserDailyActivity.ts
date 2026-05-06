import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export interface IUserDailyActivity extends Document {
  _id: Types.ObjectId;
  userId: string;
  dateKey: string;
  firstActiveAt: Date;
  lastActiveAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IUserDailyActivityModel extends Model<IUserDailyActivity> {
  markActive(userId: string, dateKey: string, activeAt: Date): Promise<void>;
}

const userDailyActivitySchema = new Schema<IUserDailyActivity, IUserDailyActivityModel>(
  {
    userId: { type: String, required: true, index: true },
    dateKey: { type: String, required: true, index: true },
    firstActiveAt: { type: Date, required: true },
    lastActiveAt: { type: Date, required: true },
  },
  {
    timestamps: true,
    statics: {
      async markActive(userId: string, dateKey: string, activeAt: Date): Promise<void> {
        await this.updateOne(
          { userId, dateKey },
          {
            $setOnInsert: { firstActiveAt: activeAt },
            $max: { lastActiveAt: activeAt },
          },
          { upsert: true },
        );
      },
    },
  },
);

userDailyActivitySchema.index({ userId: 1, dateKey: 1 }, { unique: true });
userDailyActivitySchema.index({ dateKey: 1, userId: 1 });

export const UserDailyActivity = mongoose.model<IUserDailyActivity, IUserDailyActivityModel>(
  'UserDailyActivity',
  userDailyActivitySchema,
);
