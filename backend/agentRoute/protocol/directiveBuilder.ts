import type { ClientDataRequest } from './client';
import type { InteractionDirective, PresentationPayload, RecommendedClientInput } from './server';
import type { AgentRouteOutput, AgentPhase } from '../types';

/**
 * 组装协议 directives。
 */
export function buildProtocolDirectives(params: {
  message: string;
  askUser?: AgentRouteOutput['askUser'];
  confirmation?: AgentRouteOutput['confirmation'];
  phase: AgentPhase;
  actions: AgentRouteOutput['actions'];
  error?: AgentRouteOutput['error'];
  clientDataRequest?: ClientDataRequest;
}): InteractionDirective[] {
  const directives: InteractionDirective[] = [{ type: 'assistant_message', text: params.message }];

  if (params.clientDataRequest) {
    directives.push({
      type: 'request_client_data',
      request: params.clientDataRequest,
    });
  }

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

  if (params.phase === 'ready_to_execute' || params.phase === 'executing') {
    directives.push({
      type: 'execution_status',
      status: params.phase,
      actionLabel: params.actions?.[0]?.type,
    });
  }

  if (params.phase === 'completed') {
    directives.push({ type: 'completed', summary: params.message });
  }

  if ((params.phase === 'failed' || params.phase === 'fallback') && params.error) {
    directives.push({
      type: 'failed',
      code: params.error.code,
      message: params.error.message,
      retryable: params.error.retryable,
    });
  }

  if (params.error?.code === 'SESSION_VERSION_CONFLICT' || params.error?.code === 'SESSION_SAVE_CONFLICT') {
    directives.push({ type: 'sync_required', reason: params.error.message });
  }

  return directives;
}

/**
 * 推断客户端下一步建议输入类型。
 */
export function inferRecommendedInput(phase: AgentPhase, hasClientDataRequest: boolean): RecommendedClientInput {
  if (hasClientDataRequest) {
    return 'client_data_response';
  }
  if (phase === 'collecting_slots') {
    return 'slot_update';
  }
  if (phase === 'awaiting_confirmation') {
    return 'confirm_or_deny';
  }
  if (phase === 'executing') {
    return 'none';
  }
  return 'user_text';
}

/**
 * 构建客户端呈现建议。
 */
export function buildPresentation(params: {
  phase: AgentPhase;
  message: string;
  filledSlots: Record<string, string>;
  error?: AgentRouteOutput['error'];
}): PresentationPayload {
  const kvItems = Object.entries(params.filledSlots).map(([key, value]) => ({ key, value }));

  if (params.phase === 'awaiting_confirmation') {
    return {
      template: 'confirm_sheet',
      components: [
        { componentType: 'text', id: 'confirm-text', text: params.message },
        { componentType: 'kv_grid', id: 'confirm-kv', title: '待确认信息', items: kvItems },
      ],
    };
  }

  if (params.phase === 'executing') {
    return {
      template: 'loading_card',
      components: [
        { componentType: 'status_badge', id: 'loading-status', status: 'running', text: '执行中，请稍候' },
        {
          componentType: 'timeline',
          id: 'loading-timeline',
          events: [{ title: '请求已受理' }, { title: '执行中' }],
        },
      ],
    };
  }

  if (params.phase === 'completed') {
    return {
      template: 'result_card',
      components: [
        { componentType: 'status_badge', id: 'done-status', status: 'success', text: params.message },
        { componentType: 'kv_grid', id: 'done-kv', title: '结果数据', items: kvItems },
      ],
    };
  }

  if ((params.phase === 'failed' || params.phase === 'fallback') && params.error) {
    return {
      template: 'error_banner',
      components: [
        { componentType: 'status_badge', id: 'error-status', status: 'error', text: params.error.message },
        {
          componentType: 'button_group',
          id: 'error-actions',
          buttons: params.error.retryable ? [{ id: 'retry', label: '重试', action: 'retry' }] : [],
        },
      ],
    };
  }

  return {
    template: 'chat_bubble',
    components: [{ componentType: 'text', id: 'chat-text', text: params.message }],
  };
}
