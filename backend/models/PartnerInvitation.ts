import crypto from 'node:crypto';
import mongoose, { Document, Schema } from 'mongoose';

export type PartnerInvitationStatus = 'pending' | 'accepted' | 'revoked';

export interface IPartnerInvitation extends Document {
  token: string;
  inviterUserId: string;
  inviterName: string;
  inviterAvatarUrl: string;
  status: PartnerInvitationStatus;
  expiresAt: Date;
  acceptedByUserId?: string;
  acceptedMobile?: string;
  acceptedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const partnerInvitationSchema = new Schema<IPartnerInvitation>(
  {
    token: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    inviterUserId: {
      type: String,
      required: true,
      index: true,
    },
    inviterName: {
      type: String,
      required: true,
      trim: true,
    },
    inviterAvatarUrl: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'revoked'],
      default: 'pending',
      index: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: true,
    },
    acceptedByUserId: {
      type: String,
      index: true,
    },
    acceptedMobile: {
      type: String,
      trim: true,
    },
    acceptedAt: Date,
  },
  {
    timestamps: true,
  },
);

export class PartnerInvitation {
  static buildToken(): string {
    return crypto.randomBytes(18).toString('base64url');
  }

  static createInvitation(data: {
    inviterUserId: string;
    inviterName: string;
    inviterAvatarUrl: string;
    expiresAt: Date;
  }): Promise<IPartnerInvitation> {
    return PartnerInvitationModel.create({
      token: PartnerInvitation.buildToken(),
      inviterUserId: data.inviterUserId,
      inviterName: data.inviterName,
      inviterAvatarUrl: data.inviterAvatarUrl,
      expiresAt: data.expiresAt,
    });
  }

  static findByToken(token: string): Promise<IPartnerInvitation | null> {
    return PartnerInvitationModel.findOne({ token });
  }

  static async markAccepted(args: {
    token: string;
    acceptedByUserId: string;
    acceptedMobile: string;
  }): Promise<IPartnerInvitation | null> {
    return PartnerInvitationModel.findOneAndUpdate(
      { token: args.token, status: 'pending' },
      {
        status: 'accepted',
        acceptedByUserId: args.acceptedByUserId,
        acceptedMobile: args.acceptedMobile,
        acceptedAt: new Date(),
      },
      { new: true },
    );
  }
}

const PartnerInvitationModel = mongoose.model<IPartnerInvitation>(
  'PartnerInvitation',
  partnerInvitationSchema,
);

export default PartnerInvitationModel;
