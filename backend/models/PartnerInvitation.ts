import crypto from "node:crypto";
import mongoose, { Document, Model, Schema } from "mongoose";

export type PartnerInvitationStatus = "pending" | "accepted" | "revoked";

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

type CreateInvitationInput = {
  inviterUserId: string;
  inviterName: string;
  inviterAvatarUrl: string;
  expiresAt: Date;
};

type MarkAcceptedInput = {
  token: string;
  acceptedByUserId: string;
  acceptedMobile: string;
};

export interface IPartnerInvitationModel extends Model<IPartnerInvitation> {
  buildToken(): string;
  createInvitation(data: CreateInvitationInput): Promise<IPartnerInvitation>;
  findByToken(token: string): Promise<IPartnerInvitation | null>;
  markAccepted(args: MarkAcceptedInput): Promise<IPartnerInvitation | null>;
}

const partnerInvitationSchema = new Schema<
  IPartnerInvitation,
  IPartnerInvitationModel
>(
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
      default: "",
      trim: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "revoked"],
      default: "pending",
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
    statics: {
      buildToken() {
        return crypto.randomBytes(18).toString("base64url");
      },
      createInvitation(data: CreateInvitationInput) {
        return this.create({
          token: this.buildToken(),
          inviterUserId: data.inviterUserId,
          inviterName: data.inviterName,
          inviterAvatarUrl: data.inviterAvatarUrl,
          expiresAt: data.expiresAt,
        });
      },
      findByToken(token: string) {
        return this.findOne({ token });
      },
      markAccepted(args: MarkAcceptedInput) {
        return this.findOneAndUpdate(
          { token: args.token, status: "pending" },
          {
            status: "accepted",
            acceptedByUserId: args.acceptedByUserId,
            acceptedMobile: args.acceptedMobile,
            acceptedAt: new Date(),
          },
          { new: true },
        );
      },
    },
  },
);

export const PartnerInvitation = mongoose.model<
  IPartnerInvitation,
  IPartnerInvitationModel
>(
  "PartnerInvitation",
  partnerInvitationSchema,
);
