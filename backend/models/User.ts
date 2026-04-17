import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IUser extends Document {
  _id: Types.ObjectId;
  phoneNumber: string;
  role: 'admin' | 'user';
  isActive: boolean;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    phoneNumber: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
      match: [/^1[3-9]\d{9}$/, 'Please enter a valid Chinese phone number'],
    },
    role: {
      type: String,
      enum: ['admin', 'user'],
      default: 'user',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLoginAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  },
);

userSchema.index({ phoneNumber: 1 }, { unique: true });
userSchema.index({ role: 1, isActive: 1 });
userSchema.index({ lastLoginAt: -1 });
userSchema.index({ createdAt: -1 });

export class User {
  static async findByPhoneNumber(phoneNumber: string): Promise<IUser | null> {
    return UserModel.findOne({ phoneNumber });
  }

  static async createUser(userData: {
    phoneNumber: string;
    role?: 'admin' | 'user';
  }): Promise<IUser> {
    const user = new UserModel({
      phoneNumber: userData.phoneNumber,
      role: userData.role || 'user',
      isActive: true,
      lastLoginAt: new Date(),
    });
    return user.save();
  }

  static async updateLastLogin(userId: Types.ObjectId): Promise<IUser | null> {
    return UserModel.findByIdAndUpdate(
      userId,
      { lastLoginAt: new Date() },
      { new: true },
    );
  }
}

const UserModel = mongoose.model<IUser>('User', userSchema);
export default UserModel;
