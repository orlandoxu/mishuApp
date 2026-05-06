import mongoose, { Document, Model, Schema, Types } from 'mongoose';

export interface IAdminUser extends Document {
  _id: Types.ObjectId;
  username: string;
  passwordHash: string;
  role: 'super_admin' | 'admin';
  isActive: boolean;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

type CreateAdminInput = {
  username: string;
  passwordHash: string;
  role?: 'super_admin' | 'admin';
};

export interface IAdminUserModel extends Model<IAdminUser> {
  findByUsername(username: string): Promise<IAdminUser | null>;
  createAdmin(input: CreateAdminInput): Promise<IAdminUser>;
}

const adminUserSchema = new Schema<IAdminUser, IAdminUserModel>(
  {
    username: {
      type: String,
      required: true,
      trim: true,
      minlength: 3,
      maxlength: 64,
    },
    passwordHash: {
      type: String,
      required: true,
      trim: true,
      minlength: 20,
    },
    role: {
      type: String,
      enum: ['super_admin', 'admin'],
      default: 'admin',
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
    collection: 'admin',
    timestamps: true,
    statics: {
      findByUsername(username: string) {
        return this.findOne({ username });
      },
      createAdmin(input: CreateAdminInput) {
        return this.create({
          username: input.username,
          passwordHash: input.passwordHash,
          role: input.role ?? 'admin',
          isActive: true,
          lastLoginAt: new Date(),
        });
      },
    },
  },
);

adminUserSchema.index({ username: 1 }, { unique: true });
adminUserSchema.index({ isActive: 1, role: 1 });
adminUserSchema.index({ createdAt: -1 });

export const AdminUser = mongoose.model<IAdminUser, IAdminUserModel>('AdminUser', adminUserSchema);
