import type { ClientTurnRequest, ServerTurnResponse } from './protocol';

export type RouteId = 'chat' | 'reminder' | 'contact' | 'task' | 'fallback';

export type AgentPhase =
  | 'intent_detected'
  | 'collecting_slots'
  | 'awaiting_confirmation'
  | 'ready_to_execute'
  | 'executing'
  | 'completed'
  | 'failed'
  | 'fallback'
  | 'cancelled';

export const TERMINAL_PHASES: ReadonlySet<AgentPhase> = new Set([
  'completed',
  'failed',
  'fallback',
  'cancelled',
]);

export type Actor = 'user' | 'assistant' | 'system';

export type MessageRecord = {
  id: string;
  turnId: string;
  actor: Actor;
  text: string;
  createdAt: number;
};

export type SlotValue = {
  key: string;
  value: string;
  confidence: number;
  sourceMessageId: string;
  updatedAt: number;
};

export type SlotCandidate = {
  value: string;
  confidence: number;
  reason?: string;
};

export type SlotExtraction = {
  filled: Record<string, SlotCandidate>;
  ambiguous?: Record<string, SlotCandidate[]>;
};

export type RouteIntentResult = {
  confidence: number;
  reason?: string;
};

export type ExecutionRequest = {
  idempotencyKey: string;
  route: RouteId;
  action: string;
  payload: Record<string, unknown>;
};

export type ExecutionResult = {
  success: boolean;
  summary: string;
  data?: Record<string, unknown>;
  retryable?: boolean;
  errorCode?: string;
};

export type ConfirmationState = {
  required: boolean;
  askedAt?: number;
  confirmedAt?: number;
  deniedAt?: number;
};

export type SessionExecutionState = {
  request?: ExecutionRequest;
  result?: ExecutionResult;
  retries: number;
  lastErrorAt?: number;
};

export type ProcessedTurnSnapshot = {
  messageId: string;
  turnId: string;
  output: AgentRouteOutput;
  processedAt: number;
};

export type SessionState = {
  sessionId: string;
  version: number;
  phase: AgentPhase;
  activeRoute: RouteId;
  slots: Record<string, SlotValue>;
  missingSlots: string[];
  ambiguousSlots: Record<string, SlotCandidate[]>;
  confirmation: ConfirmationState;
  execution: SessionExecutionState;
  history: MessageRecord[];
  processedTurns: Record<string, ProcessedTurnSnapshot>;
  currentTurnId?: string;
  updatedAt: number;
};

export type AgentRouteInput = ClientTurnRequest;

export type UiDisplayType =
  | 'text'
  | 'slot_prompt'
  | 'candidate_list'
  | 'confirmation_sheet'
  | 'loading'
  | 'success'
  | 'error';

export type AskUserPayload = {
  prompt: string;
  expectedSlots?: string[];
  candidates?: Record<string, SlotCandidate[]>;
};

export type ConfirmationPayload = {
  prompt: string;
  summary: string;
  confirmLabel?: string;
  denyLabel?: string;
};

export type AgentAction = {
  type: 'execute' | 'retry' | 'cancel' | 'switch_route' | 'none';
  route?: RouteId;
  payload?: Record<string, unknown>;
};

export type AgentRouteError = {
  code: string;
  message: string;
  retryable: boolean;
};

export type AgentRouteOutput = ServerTurnResponse;

export type RouteContext = {
  now: number;
  input: AgentRouteInput;
  state: SessionState;
};

export type RoutePlugin = {
  id: RouteId;
  description: string;
  requiredSlots: string[];
  detectIntent(input: AgentRouteInput, state: SessionState): RouteIntentResult;
  extractSlots(input: AgentRouteInput, state: SessionState): SlotExtraction;
  buildSlotPrompt(missingSlots: string[], state: SessionState): string;
  needsConfirmation(state: SessionState): boolean;
  buildConfirmation(state: SessionState): ConfirmationPayload;
  buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null;
  buildCompletedMessage(state: SessionState): string;
};

export type RouteDecision = {
  route: RouteId;
  confidence: number;
  reason: string;
  keepCurrentRoute: boolean;
};

export interface SessionStore {
  get(sessionId: string): Promise<SessionState | null>;
  save(state: SessionState, expectedVersion: number): Promise<SessionState>;
}

export type RouteExecutor = {
  execute(request: ExecutionRequest): Promise<ExecutionResult>;
};
