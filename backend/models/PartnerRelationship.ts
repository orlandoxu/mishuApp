import mongoose, { Document, Schema } from 'mongoose';

export type PartnerRelationshipStatus = 'active' | 'archived';

export interface IPartnerRelationship extends Document {
  inviterUserId: string;
  partnerUserId: string;
  participantIds: string[];
  pairKey: string;
  invitationToken: string;
  status: PartnerRelationshipStatus;
  createdAt: Date;
  updatedAt: Date;
}

function buildPairKey(userA: string, userB: string): string {
  return [userA, userB].sort().join(':');
}

const partnerRelationshipSchema = new Schema<IPartnerRelationship>(
  {
    inviterUserId: {
      type: String,
      required: true,
      index: true,
    },
    partnerUserId: {
      type: String,
      required: true,
      index: true,
    },
    participantIds: {
      type: [String],
      required: true,
      index: true,
    },
    pairKey: {
      type: String,
      required: true,
    },
    invitationToken: {
      type: String,
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['active', 'archived'],
      default: 'active',
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

partnerRelationshipSchema.index(
  { participantIds: 1 },
  { unique: true, partialFilterExpression: { status: 'active' } },
);
partnerRelationshipSchema.index(
  { pairKey: 1 },
  { unique: true, partialFilterExpression: { status: 'active' } },
);

export class PartnerRelationship {
  static buildPairKey = buildPairKey;

  static findActiveByUserId(userId: string): Promise<IPartnerRelationship | null> {
    return PartnerRelationshipModel.findOne({
      participantIds: userId,
      status: 'active',
    });
  }

  static async createActive(args: {
    inviterUserId: string;
    partnerUserId: string;
    invitationToken: string;
  }): Promise<IPartnerRelationship> {
    const participantIds = [args.inviterUserId, args.partnerUserId].sort();
    return PartnerRelationshipModel.create({
      inviterUserId: args.inviterUserId,
      partnerUserId: args.partnerUserId,
      participantIds,
      pairKey: buildPairKey(args.inviterUserId, args.partnerUserId),
      invitationToken: args.invitationToken,
      status: 'active',
    });
  }
}

const PartnerRelationshipModel = mongoose.model<IPartnerRelationship>(
  'PartnerRelationship',
  partnerRelationshipSchema,
);

export default PartnerRelationshipModel;
