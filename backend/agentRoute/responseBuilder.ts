import { projectFilledSlots } from './slotCollector';
import {
  AGENT_ROUTE_PROTOCOL_VERSION,
  buildPresentation,
  buildProtocolDirectives,
  inferRecommendedInput,
} from './protocol';
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
  const filledSlots = projectFilledSlots(params.state);
  const directives = buildProtocolDirectives({
    message: params.message,
    askUser: params.askUser,
    confirmation: params.confirmation,
    phase: params.state.phase,
    actions: params.actions ?? [],
    error: params.error,
    clientDataRequest: params.state.pendingClientDataRequest,
  });
  const recommendedInput = inferRecommendedInput(
    params.state.phase,
    Boolean(params.state.pendingClientDataRequest),
  );
  const presentation = buildPresentation({
    phase: params.state.phase,
    message: params.message,
    filledSlots,
    error: params.error,
  });

  return {
    sessionId: params.state.sessionId,
    sessionVersion: params.state.version,
    turnId: params.input.turnId,
    messageId: params.input.messageId,
    route: params.route.id,
    phase: params.state.phase,
    message: params.message,
    missingSlots: params.state.missingSlots,
    filledSlots,
    askUser: params.askUser,
    confirmation: params.confirmation,
    executable: params.executable ?? false,
    needsUserInput:
      !params.state.pendingClientDataRequest &&
      (params.state.phase === 'collecting_slots' || params.state.phase === 'awaiting_confirmation'),
    uiHints: {
      display,
      emphasizeSlots: params.state.missingSlots,
      allowCancel: !['completed', 'failed', 'cancelled'].includes(params.state.phase),
    },
    actions: params.actions ?? [],
    presentation,
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
