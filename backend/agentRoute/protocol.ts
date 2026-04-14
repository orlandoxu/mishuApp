/**
 * AgentRoute 前后端交互协议版本号。
 * 约定：字段发生不兼容变更时必须升级版本。
 */
export const AGENT_ROUTE_PROTOCOL_VERSION = '2026-04-14.v1';

/**
 * 客户端发起 turn 请求时可携带的交互动作。
 * 说明：不是只有纯文本输入，还支持确认、候选选择、取消、重试等协议动作。
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

/**
 * 服务端推荐给客户端的下一步输入类型。
 */
export type RecommendedClientInput =
  | 'user_text'
  | 'confirm_or_deny'
  | 'slot_update'
  | 'candidate_select'
  | 'none';

/**
 * 服务端 -> 客户端：可驱动 UI 的交互指令。
 */
export type InteractionDirective =
  | {
      type: 'assistant_message';
      text: string;
    }
  | {
      type: 'ask_slots';
      prompt: string;
      missingSlots: string[];
    }
  | {
      type: 'show_candidates';
      prompt: string;
      candidates: Record<string, Array<{ value: string; confidence: number; reason?: string }>>;
    }
  | {
      type: 'confirm';
      prompt: string;
      summary: string;
      confirmLabel?: string;
      denyLabel?: string;
    }
  | {
      type: 'execution_status';
      status: 'ready_to_execute' | 'executing';
      actionLabel?: string;
    }
  | {
      type: 'completed';
      summary: string;
    }
  | {
      type: 'failed';
      code: string;
      message: string;
      retryable: boolean;
    }
  | {
      type: 'sync_required';
      reason: string;
    };

/**
 * 服务端协议包（响应中的独立协议对象）。
 */
export type ServerProtocolEnvelope = {
  version: string;
  recommendedInput: RecommendedClientInput;
  directives: InteractionDirective[];
};

/**
 * 服务端 -> 客户端：单轮响应协议。
 * 说明：保留当前业务字段，同时增加 protocol 独立协议对象，便于客户端按指令渲染。
 */
export type ServerTurnResponse = {
  sessionId: string;
  sessionVersion: number;
  turnId: string;
  messageId: string;
  route: 'chat' | 'reminder' | 'contact' | 'task' | 'fallback';
  phase:
    | 'intent_detected'
    | 'collecting_slots'
    | 'awaiting_confirmation'
    | 'ready_to_execute'
    | 'executing'
    | 'completed'
    | 'failed'
    | 'fallback'
    | 'cancelled';
  message: string;
  missingSlots: string[];
  filledSlots: Record<string, string>;
  askUser?: {
    prompt: string;
    expectedSlots?: string[];
    candidates?: Record<string, Array<{ value: string; confidence: number; reason?: string }>>;
  };
  confirmation?: {
    prompt: string;
    summary: string;
    confirmLabel?: string;
    denyLabel?: string;
  };
  executable: boolean;
  needsUserInput: boolean;
  uiHints: {
    display: 'text' | 'slot_prompt' | 'candidate_list' | 'confirmation_sheet' | 'loading' | 'success' | 'error';
    emphasizeSlots?: string[];
    allowCancel: boolean;
  };
  actions: Array<{
    type: 'execute' | 'retry' | 'cancel' | 'switch_route' | 'none';
    route?: 'chat' | 'reminder' | 'contact' | 'task' | 'fallback';
    payload?: Record<string, unknown>;
  }>;
  error?: {
    code: string;
    message: string;
    retryable: boolean;
  };
  deduped?: boolean;
  protocol: ServerProtocolEnvelope;
};
