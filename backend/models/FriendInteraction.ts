import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export type FriendInteractionStatus = 'active' | 'deleted';

export interface IFriendInteraction extends Document {
  _id: Types.ObjectId;
  userId: string;
  friendId: string;
  date: string;
  type: string;
  desc: string;
  status: FriendInteractionStatus;
  deletedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IFriendInteractionModel extends Model<IFriendInteraction> {}

const friendInteractionSchema = new Schema<IFriendInteraction, IFriendInteractionModel>(
  {
    userId: { type: String, required: true, trim: true, index: true },
    friendId: { type: String, required: true, trim: true, index: true },
    date: { type: String, required: true, trim: true },
    type: { type: String, required: true, trim: true },
    desc: { type: String, required: true, trim: true },
    status: { type: String, enum: ['active', 'deleted'], default: 'active', index: true },
    deletedAt: { type: Date },
  },
  { timestamps: true },
);

friendInteractionSchema.index({ userId: 1, friendId: 1, status: 1, date: -1 });

export const FriendInteraction = mongoose.model<IFriendInteraction, IFriendInteractionModel>(
  'FriendInteraction',
  friendInteractionSchema,
  'friend_interactions',
);
