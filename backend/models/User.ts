import mongoose, { Document, Model, Schema, Types } from "mongoose";

export interface IUser extends Document {
  _id: Types.ObjectId;
  phoneNumber: string;
  role: 'admin' | 'user';
  isActive: boolean;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

type CreateUserInput = {
  phoneNumber: string;
  role?: "admin" | "user";
};

export interface IUserModel extends Model<IUser> {
  findByPhoneNumber(phoneNumber: string): Promise<IUser | null>;
  createUser(userData: CreateUserInput): Promise<IUser>;
  updateLastLogin(userId: Types.ObjectId): Promise<IUser | null>;
}

const userSchema = new Schema<IUser, IUserModel>(
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
    statics: {
      findByPhoneNumber(phoneNumber: string) {
        return this.findOne({ phoneNumber });
      },
      createUser(userData: CreateUserInput) {
        return this.create({
          phoneNumber: userData.phoneNumber,
          role: userData.role || "user",
          isActive: true,
          lastLoginAt: new Date(),
        });
      },
      updateLastLogin(userId: Types.ObjectId) {
        return this.findByIdAndUpdate(
          userId,
          { lastLoginAt: new Date() },
          { new: true },
        );
      },
    },
  },
);

userSchema.index({ phoneNumber: 1 }, { unique: true });
userSchema.index({ role: 1, isActive: 1 });
userSchema.index({ lastLoginAt: -1 });
userSchema.index({ createdAt: -1 });

export const User = mongoose.model<IUser, IUserModel>("User", userSchema);
