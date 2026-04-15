/**
 * 服务端向客户端请求的数据类型。
 */
export type ClientDataRequestKind = 'vector_memory_search' | 'contact_candidates' | 'device_snapshot';

/**
 * 服务端请求客户端补充数据（例如端侧向量检索）时的协议结构。
 */
export type ClientDataRequest = {
  requestId: string;
  kind: ClientDataRequestKind;
  query: string;
  topK?: number;
  namespace?: string;
  reason?: string;
};

/**
 * 客户端回传数据项。
 */
export type ClientDataItem = {
  id?: string;
  text: string;
  score?: number;
  metadata?: Record<string, unknown>;
};

/**
 * 客户端对数据请求的响应。
 */
export type ClientDataResponsePayload = {
  requestId: string;
  kind: ClientDataRequestKind;
  items: ClientDataItem[];
  error?: string;
};

/**
 * 客户端发起 turn 请求时可携带的交互动作。
 */
export type ClientInteraction =
  | {
      kind: 'user_text';
      text: string;
    }
  | {
      kind: 'confirm';
      decision: 'confirm' | 'deny';
      reason?: string;
    }
  | {
      kind: 'slot_update';
      slots: Record<string, string>;
      overwrite?: boolean;
    }
  | {
      kind: 'candidate_select';
      slotKey: string;
      value: string;
    }
  | {
      kind: 'client_data_response';
      payload: ClientDataResponsePayload;
    }
  | {
      kind: 'cancel';
      reason?: string;
    }
  | {
      kind: 'retry';
      actionId?: string;
    };

/**
 * 客户端 -> 服务端：单轮请求协议。
 */
export type ClientTurnRequest = {
  protocolVersion?: string;
  sessionId: string;
  turnId: string;
  messageId: string;
  text: string;
  interaction?: ClientInteraction;
  timestamp?: number;
  clientSessionVersion?: number;
  history?: Array<{
    id: string;
    turnId: string;
    actor: 'user' | 'assistant' | 'system';
    text: string;
    createdAt: number;
  }>;
  clientContext?: {
    locale?: string;
    timezone?: string;
    platform?: 'ios' | 'android' | 'web';
    appVersion?: string;
    deviceId?: string;
  };
};
