import mongoose, { Document, Model, Schema } from "mongoose";

export type DoubaoApiType =
  | "chat_completion"
  | "chat_completion_stream"
  | "chat_completion_json"
  | "embedding";

export interface IDoubaoCallLog extends Document {
  apiType: DoubaoApiType;
  modelId: string;
  requestPayload: Record<string, unknown>;
  responsePayload?: Record<string, unknown>;
  responseText?: string;
  errorMessage?: string;
  durationMs: number;
  success: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type DoubaoCallLogEntry = {
  apiType: DoubaoApiType;
  modelId: string;
  requestPayload: Record<string, unknown>;
  responsePayload?: Record<string, unknown>;
  responseText?: string;
  errorMessage?: string;
  durationMs: number;
  success: boolean;
};

export interface IDoubaoCallLogModel extends Model<IDoubaoCallLog> {
  writeLog(entry: DoubaoCallLogEntry): Promise<void>;
}

const doubaoCallLogSchema = new Schema<IDoubaoCallLog, IDoubaoCallLogModel>(
  {
    apiType: {
      type: String,
      required: true,
      index: true,
      enum: [
        "chat_completion",
        "chat_completion_stream",
        "chat_completion_json",
        "embedding",
      ],
    },
    modelId: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    requestPayload: {
      type: Schema.Types.Mixed,
      required: true,
    },
    responsePayload: {
      type: Schema.Types.Mixed,
    },
    responseText: {
      type: String,
      trim: true,
    },
    errorMessage: {
      type: String,
      trim: true,
    },
    durationMs: {
      type: Number,
      required: true,
      min: 0,
    },
    success: {
      type: Boolean,
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
    statics: {
      async writeLog(entry: DoubaoCallLogEntry) {
        try {
          await this.create(entry);
        } catch {
          // 日志写库失败不能影响业务主流程
        }
      },
    },
  },
);

doubaoCallLogSchema.index({ createdAt: -1 });
doubaoCallLogSchema.index({ apiType: 1, createdAt: -1 });
doubaoCallLogSchema.index({ modelId: 1, createdAt: -1 });

export const DoubaoCallLog = mongoose.model<
  IDoubaoCallLog,
  IDoubaoCallLogModel
>(
  "DoubaoCallLog",
  doubaoCallLogSchema,
);
