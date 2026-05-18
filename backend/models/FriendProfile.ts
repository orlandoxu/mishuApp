import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export type FriendStatus = 'active' | 'deleted';

export interface IFriendProfile extends Document {
  _id: Types.ObjectId;
  userId: string;
  name: string;
  shortName: string;
  age: number;
  gender: string;
  role: string;
  avatarText: string;
  isStarred: boolean;
  starredAt?: Date;
  tags: string[];
  birthday?: string;
  relationship?: string;
  preferences: string[];
  resources: string[];
  insight: string;
  sort: number;
  status: FriendStatus;
  deletedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IFriendProfileModel extends Model<IFriendProfile> {}

const friendProfileSchema = new Schema<IFriendProfile, IFriendProfileModel>(
  {
    userId: { type: String, required: true, trim: true, index: true },
    name: { type: String, required: true, trim: true },
    shortName: { type: String, required: true, trim: true },
    age: { type: Number, required: true, min: 0, max: 150 },
    gender: { type: String, required: true, trim: true, default: '未知' },
    role: { type: String, required: true, trim: true, default: '' },
    avatarText: { type: String, required: true, trim: true, default: '' },
    isStarred: { type: Boolean, required: true, default: false },
    starredAt: { type: Date },
    tags: { type: [String], default: [] },
    birthday: { type: String, trim: true },
    relationship: { type: String, trim: true },
    preferences: { type: [String], default: [] },
    resources: { type: [String], default: [] },
    insight: { type: String, trim: true, default: '' },
    sort: { type: Number, default: 0 },
    status: { type: String, enum: ['active', 'deleted'], default: 'active', index: true },
    deletedAt: { type: Date },
  },
  { timestamps: true },
);

friendProfileSchema.index({ userId: 1, status: 1, updatedAt: -1 });
friendProfileSchema.index({ userId: 1, isStarred: 1, starredAt: -1 });
friendProfileSchema.index({ userId: 1, name: 1 });

export const FriendProfile = mongoose.model<IFriendProfile, IFriendProfileModel>(
  'FriendProfile',
  friendProfileSchema,
  'friend_profiles',
);
