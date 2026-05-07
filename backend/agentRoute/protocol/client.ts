export type ClientCapabilityRequestKind =
  | 'vector_memory_search'
  | 'contact_candidates'
  | 'device_snapshot'
  | 'ledger_local_action';

export type ClientCapabilityRequest = {
  requestId: string;
  kind: ClientCapabilityRequestKind;
  query: string;
  topK?: number;
  namespace?: string;
  reason?: string;
  action?: string;
  payload?: Record<string, unknown>;
};

export type ClientCapabilityItem = {
  id?: string;
  text: string;
  score?: number;
  metadata?: Record<string, unknown>;
};

export type ClientCapabilityResponsePayload = {
  requestId: string;
  kind: ClientCapabilityRequestKind;
  items: ClientCapabilityItem[];
  result?: Record<string, unknown>;
  error?: string;
};

export type ClientActionResponsePayload = {
  requestId: string;
  action: string;
  success: boolean;
  result?: Record<string, unknown>;
  error?: string;
};

// compatibility aliases
export type ClientDataRequestKind = ClientCapabilityRequestKind;
export type ClientDataRequest = ClientCapabilityRequest;
export type ClientDataItem = ClientCapabilityItem;
export type ClientDataResponsePayload = ClientCapabilityResponsePayload;

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
      kind: 'client_capability_response';
      payload: ClientCapabilityResponsePayload;
    }
  | {
      kind: 'client_data_response';
      payload: ClientDataResponsePayload;
    }
  | {
      kind: 'client_action_response';
      payload: ClientActionResponsePayload;
    }
  | {
      kind: 'cancel';
      reason?: string;
    }
  | {
      kind: 'retry';
      actionId?: string;
    };

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
