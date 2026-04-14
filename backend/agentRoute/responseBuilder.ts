import { projectFilledSlots } from './slotCollector';
import { AGENT_ROUTE_PROTOCOL_VERSION, type InteractionDirective, type RecommendedClientInput } from './protocol';
import type {
  AgentAction,
  AgentRouteError,
  AgentRouteInput,
  AgentRouteOutput,
  AskUserPayload,
  ConfirmationPayload,
  RoutePlugin,
  SessionState,
  UiDisplayType,
} from './types';

type BuildResponseParams = {
  input: AgentRouteInput;
  state: SessionState;
  route: RoutePlugin;
  message: string;
  askUser?: AskUserPayload;
  confirmation?: ConfirmationPayload;
  executable?: boolean;
  display?: UiDisplayType;
  actions?: AgentAction[];
  error?: AgentRouteError;
  deduped?: boolean;
};

/**
 * 构建返回给移动端的结构化响应。
 * 作用：统一 message/phase/slots/uiHints/actions 输出契约。
 */
export function buildResponse(params: BuildResponseParams): AgentRouteOutput {
  const display = params.display ?? inferDisplayByPhase(params.state.phase);
  const directives = buildDirectives(params);
  const recommendedInput = inferRecommendedInput(params.state.phase);

  return {
    sessionId: params.state.sessionId,
    sessionVersion: params.state.version,
    turnId: params.input.turnId,
    messageId: params.input.messageId,
    route: params.route.id,
    phase: params.state.phase,
    message: params.message,
    missingSlots: params.state.missingSlots,
    filledSlots: projectFilledSlots(params.state),
    askUser: params.askUser,
    confirmation: params.confirmation,
    executable: params.executable ?? false,
    needsUserInput: params.state.phase === 'collecting_slots' || params.state.phase === 'awaiting_confirmation',
    uiHints: {
      display,
      emphasizeSlots: params.state.missingSlots,
      allowCancel: !['completed', 'failed', 'cancelled'].includes(params.state.phase),
    },
    actions: params.actions ?? [],
    error: params.error,
    deduped: params.deduped,
    protocol: {
      version: AGENT_ROUTE_PROTOCOL_VERSION,
      recommendedInput,
      directives,
    },
  };
}

/**
 * 根据 phase 推断默认 UI 展示形态。
 */
function inferDisplayByPhase(phase: SessionState['phase']): UiDisplayType {
  if (phase === 'collecting_slots') {
    return 'slot_prompt';
  }

  if (phase === 'awaiting_confirmation') {
    return 'confirmation_sheet';
  }

  if (phase === 'executing') {
    return 'loading';
  }

  if (phase === 'completed') {
    return 'success';
  }

  if (phase === 'failed' || phase === 'fallback') {
    return 'error';
  }

  return 'text';
}

/**
 * 将运行时状态映射为前端可消费的交互指令序列。
 */
function buildDirectives(params: BuildResponseParams): InteractionDirective[] {
  const directives: InteractionDirective[] = [
    {
      type: 'assistant_message',
      text: params.message,
    },
  ];

  if (params.askUser?.candidates && Object.keys(params.askUser.candidates).length > 0) {
    directives.push({
      type: 'show_candidates',
      prompt: params.askUser.prompt,
      candidates: params.askUser.candidates,
    });
  } else if (params.askUser) {
    directives.push({
      type: 'ask_slots',
      prompt: params.askUser.prompt,
      missingSlots: params.askUser.expectedSlots ?? [],
    });
  }

  if (params.confirmation) {
    directives.push({
      type: 'confirm',
      prompt: params.confirmation.prompt,
      summary: params.confirmation.summary,
      confirmLabel: params.confirmation.confirmLabel,
      denyLabel: params.confirmation.denyLabel,
    });
  }

  if (params.state.phase === 'ready_to_execute' || params.state.phase === 'executing') {
    directives.push({
      type: 'execution_status',
      status: params.state.phase,
      actionLabel: params.actions?.[0]?.type,
    });
  }

  if (params.state.phase === 'completed') {
    directives.push({
      type: 'completed',
      summary: params.message,
    });
  }

  if ((params.state.phase === 'failed' || params.state.phase === 'fallback') && params.error) {
    directives.push({
      type: 'failed',
      code: params.error.code,
      message: params.error.message,
      retryable: params.error.retryable,
    });
  }

  if (params.error?.code === 'SESSION_VERSION_CONFLICT' || params.error?.code === 'SESSION_SAVE_CONFLICT') {
    directives.push({
      type: 'sync_required',
      reason: params.error.message,
    });
  }

  return directives;
}

/**
 * 根据当前 phase 推断客户端推荐回传输入类型。
 */
function inferRecommendedInput(phase: SessionState['phase']): RecommendedClientInput {
  if (phase === 'collecting_slots') {
    return 'slot_update';
  }
  if (phase === 'awaiting_confirmation') {
    return 'confirm_or_deny';
  }
  if (phase === 'completed' || phase === 'failed' || phase === 'fallback' || phase === 'cancelled') {
    return 'user_text';
  }
  if (phase === 'executing') {
    return 'none';
  }
  return 'user_text';
}
