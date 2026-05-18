import type { ClientCapabilityRequest } from './client';

export type RecommendedClientInput =
  | 'user_text'
  | 'confirm_or_deny'
  | 'slot_update'
  | 'candidate_select'
  | 'client_capability_response'
  | 'client_data_response'
  | 'client_action_response'
  | 'none';

export type RenderComponent =
  | { componentType: 'text'; id: string; text: string }
  | { componentType: 'kv_grid'; id: string; title: string; items: Array<{ key: string; value: string }> }
  | { componentType: 'status_badge'; id: string; status: 'running' | 'success' | 'error'; text: string }
  | { componentType: 'button_group'; id: string; buttons: Array<{ id: string; label: string; action: string }> }
  | { componentType: 'timeline'; id: string; events: Array<{ title: string; at?: string; detail?: string }> }
  | { componentType: 'list'; id: string; title: string; rows: Array<{ label: string; value?: string }> };

export type PresentationPayload = {
  template: 'chat_bubble' | 'result_card' | 'confirm_sheet' | 'error_banner' | 'loading_card';
  components: RenderComponent[];
};

export type InteractionDirective =
  | { type: 'assistant_message'; text: string }
  | { type: 'ask_slots'; prompt: string; missingSlots: string[] }
  | {
      type: 'show_candidates';
      prompt: string;
      candidates: Record<string, Array<{ value: string; confidence: number; reason?: string }>>;
    }
  | { type: 'confirm'; prompt: string; summary: string; confirmLabel?: string; denyLabel?: string }
  | { type: 'request_client_capability'; request: ClientCapabilityRequest }
  | { type: 'request_client_data'; request: ClientCapabilityRequest }
  | {
      type: 'request_client_action';
      requestId: string;
      action: string;
      payload: Record<string, unknown>;
      reason?: string;
    }
  | { type: 'execution_status'; status: 'ready_to_execute' | 'executing'; actionLabel?: string }
  | { type: 'completed'; summary: string }
  | { type: 'failed'; code: string; message: string; retryable: boolean }
  | { type: 'sync_required'; reason: string };

export type ServerProtocolEnvelope = {
  version: string;
  recommendedInput: RecommendedClientInput;
  directives: InteractionDirective[];
};

export type ServerTurnResponse = {
  sessionId: string;
  sessionVersion: number;
  turnId: string;
  messageId: string;
  route: 'chat' | 'money' | 'reminder' | 'contact' | 'task' | 'food' | 'fallback';
  intent?: string;
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
    route?: 'chat' | 'money' | 'reminder' | 'contact' | 'task' | 'food' | 'fallback';
    payload?: Record<string, unknown>;
  }>;
  error?: { code: string; message: string; retryable: boolean };
  deduped?: boolean;
  resultData?: Record<string, unknown>;
  protocol: ServerProtocolEnvelope;
};
