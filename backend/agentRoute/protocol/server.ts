import type { ClientDataRequest } from './client';

/**
 * 服务端推荐给客户端的下一步输入类型。
 */
export type RecommendedClientInput =
  | 'user_text'
  | 'confirm_or_deny'
  | 'slot_update'
  | 'candidate_select'
  | 'client_data_response'
  | 'none';

/**
 * 客户端渲染组件协议。
 * 说明：前端可直接根据 componentType 做组件映射，而不是解析自然语言。
 */
export type RenderComponent =
  | { componentType: 'text'; id: string; text: string }
  | { componentType: 'kv_grid'; id: string; title: string; items: Array<{ key: string; value: string }> }
  | { componentType: 'status_badge'; id: string; status: 'running' | 'success' | 'error'; text: string }
  | { componentType: 'button_group'; id: string; buttons: Array<{ id: string; label: string; action: string }> }
  | { componentType: 'timeline'; id: string; events: Array<{ title: string; at?: string; detail?: string }> }
  | { componentType: 'list'; id: string; title: string; rows: Array<{ label: string; value?: string }> };

/**
 * 服务端给客户端的呈现建议。
 */
export type PresentationPayload = {
  template: 'chat_bubble' | 'result_card' | 'confirm_sheet' | 'error_banner' | 'loading_card';
  components: RenderComponent[];
};

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
      type: 'request_client_data';
      request: ClientDataRequest;
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
  presentation: PresentationPayload;
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
