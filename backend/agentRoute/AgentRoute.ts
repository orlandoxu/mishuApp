import { parseConfirmation, resetConfirmation } from './confirmation';
import { ExecutionOrchestrator } from './execution';
import { assertPhaseTransition } from './phaseTransition';
import { decideRoute } from './routeMatcher';
import { buildResponse } from './responseBuilder';
import {
  appendAssistantMessage,
  appendUserMessage,
  createInitialSessionState,
  getDedupOutput,
  InMemorySessionStore,
  markProcessedTurn,
} from './sessionState';
import { collectSlots } from './slotCollector';
import { chatExecutor, contactExecutor, moneyExecutor, reminderExecutor, taskExecutor } from './builtinExecutors';
import { chatRoute } from './builtinRoutes/chatRoute';
import { contactRoute } from './builtinRoutes/contactRoute';
import { fallbackRoute } from './builtinRoutes/fallbackRoute';
import { moneyRoute } from './builtinRoutes/moneyRoute';
import { reminderRoute } from './builtinRoutes/reminderRoute';
import { taskRoute } from './builtinRoutes/taskRoute';
import { IntentRouterService } from './intentRouterService';
import type {
  ClientActionResponsePayload,
  ClientCapabilityResponsePayload,
} from './protocol';
import type {
  AgentRouteInput,
  AgentRouteOutput,
  RoutePlugin,
  SessionStore,
  SessionState,
} from './types';

type AgentRouteOptions = {
  store?: SessionStore;
  routes?: RoutePlugin[];
  fallback?: RoutePlugin;
  execution?: ExecutionOrchestrator;
  intentRouter?: IntentRouterService;
};

const CANCEL_PATTERN = /^(取消|停止|cancel|abort)$/i;

export class AgentRoute {
  private readonly store: SessionStore;
  private readonly routes: RoutePlugin[];
  private readonly routeMap: Map<string, RoutePlugin>;
  private readonly fallback: RoutePlugin;
  private readonly execution: ExecutionOrchestrator;
  private readonly intentRouter: IntentRouterService;

  constructor(options: AgentRouteOptions = {}) {
    this.store = options.store ?? new InMemorySessionStore();
    this.routes = options.routes ?? [moneyRoute, reminderRoute, contactRoute, taskRoute, chatRoute];
    this.fallback = options.fallback ?? fallbackRoute;
    this.routeMap = new Map([...this.routes, this.fallback].map((route) => [route.id, route]));
    this.intentRouter = options.intentRouter ?? new IntentRouterService();

    this.execution =
      options.execution ??
      new ExecutionOrchestrator({
        money: moneyExecutor,
        chat: chatExecutor,
        reminder: reminderExecutor,
        contact: contactExecutor,
        task: taskExecutor,
      });
  }

  async handle(input: AgentRouteInput): Promise<AgentRouteOutput> {
    const now = input.timestamp ?? Date.now();
    const persisted = await this.store.get(input.sessionId);
    const state = persisted ?? createInitialSessionState(input.sessionId, now);
    const baseVersion = state.version;

    if (typeof input.clientSessionVersion === 'number' && input.clientSessionVersion !== state.version) {
      const staleRoute = this.getRoute(state.activeRoute);
      return buildResponse({
        input,
        state,
        route: staleRoute,
        message: '客户端会话版本过期，请先同步最新会话状态。',
        executable: false,
        display: 'error',
        actions: [{ type: 'none' }],
        error: {
          code: 'SESSION_VERSION_CONFLICT',
          message: `client=${input.clientSessionVersion}, server=${state.version}`,
          retryable: true,
        },
      });
    }

    const deduped = getDedupOutput(state, input.messageId);
    if (deduped) return { ...deduped, deduped: true };

    appendUserMessage(state, input, now);
    state.currentTurnId = input.turnId;

    if (input.interaction?.kind === 'cancel' || CANCEL_PATTERN.test(input.text.trim())) {
      this.setPhase(state, 'cancelled');
      state.missingSlots = [];
      state.pendingClientCapabilityRequest = undefined;
      state.execution.pendingClientAction = undefined;
      resetConfirmation(state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route: this.getRoute(state.activeRoute),
        response: buildResponse({
          input,
          state,
          route: this.getRoute(state.activeRoute),
          message: '已取消当前任务。',
          executable: false,
          display: 'text',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    if (this.isClientActionResponse(input)) {
      const actionOk = this.applyClientActionResponse(state, input.interaction.payload);
      const route = this.getRoute(state.activeRoute);
      if (!actionOk) {
        return this.finalizeAndSave({
          input,
          state,
          baseVersion,
          route,
          response: buildResponse({
            input,
            state,
            route,
            message: '客户端动作响应与当前请求不匹配，请重试。',
            executable: false,
            display: 'error',
            error: {
              code: 'CLIENT_ACTION_RESPONSE_MISMATCH',
              message: 'requestId mismatch or no pending client action',
              retryable: true,
            },
          }),
          now,
        });
      }

      this.setPhase(state, 'completed');
      resetConfirmation(state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: route.buildCompletedMessage(state),
          executable: false,
          display: 'success',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    const llmIntent = await this.intentRouter.detect(input, state);
    if (llmIntent?.confidence && llmIntent.confidence >= 0.6) {
      for (const [slotKey, slotValue] of Object.entries(llmIntent.slots)) {
        state.slots[slotKey] = {
          key: slotKey,
          value: slotValue,
          confidence: llmIntent.confidence,
          sourceMessageId: input.messageId,
          updatedAt: now,
        };
      }
    }

    const decision = decideRoute(this.routes, this.fallback, input, state, llmIntent ? {
      route: llmIntent.route,
      confidence: llmIntent.confidence,
      reason: llmIntent.reason,
    } : undefined);

    const previousRoute = state.activeRoute;
    state.activeRoute = decision.route;
    const route = this.getRoute(decision.route);
    const previousPhase = state.phase;

    if (previousRoute !== route.id && !decision.keepCurrentRoute) {
      const allowed = new Set(route.requiredSlots);
      state.slots = Object.fromEntries(Object.entries(state.slots).filter(([slotKey]) => allowed.has(slotKey)));
      state.missingSlots = [];
      state.ambiguousSlots = {};
      state.pendingClientCapabilityRequest = undefined;
      state.execution.pendingClientAction = undefined;
      resetConfirmation(state);
    }

    this.applyInteractionSlotUpdate(input, state);
    this.setPhase(state, 'intent_detected');
    collectSlots(route, state, input);
    this.refreshMissingSlots(route, state);

    if (
      this.isClientCapabilityResponse(input) &&
      !this.applyClientCapabilityResponse(route, state, input.interaction.payload)
    ) {
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: '客户端能力响应与当前请求不匹配，请重新同步后重试。',
          executable: false,
          display: 'error',
          error: {
            code: 'CLIENT_CAPABILITY_RESPONSE_MISMATCH',
            message: 'requestId mismatch or no pending request',
            retryable: true,
          },
        }),
        now,
      });
    }

    if (this.isClientCapabilityResponse(input)) {
      this.refreshMissingSlots(route, state);
    }

    if (state.execution.pendingClientAction) {
      this.setPhase(state, 'executing');
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: '正在等待 App 执行本地动作并回传结果…',
          executable: false,
          display: 'loading',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    if (state.pendingClientCapabilityRequest) {
      this.setPhase(state, 'collecting_slots');
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: '正在等待 App 返回补充数据…',
          executable: false,
          display: 'loading',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    const clientCapabilityRequest = route.buildClientCapabilityRequest?.(input, state) ?? null;
    if (clientCapabilityRequest) {
      state.pendingClientCapabilityRequest = clientCapabilityRequest;
      this.setPhase(state, 'collecting_slots');
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: '我需要从 App 获取候选数据来补全信息，请稍候。',
          executable: false,
          display: 'loading',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    if (previousPhase === 'awaiting_confirmation') {
      const verdict = parseConfirmation(input);
      if (verdict === 'confirmed') {
        state.confirmation.confirmedAt = now;
        this.setPhase(state, 'ready_to_execute');
      }
      if (verdict === 'denied') {
        this.setPhase(state, 'collecting_slots');
        state.confirmation.deniedAt = now;
        const prompt = '好的，我们先不执行。请告诉我你要修改哪一项。';
        return this.finalizeAndSave({
          input,
          state,
          baseVersion,
          route,
          response: buildResponse({
            input,
            state,
            route,
            message: prompt,
            askUser: {
              prompt,
              expectedSlots: state.missingSlots,
            },
            executable: false,
            display: 'slot_prompt',
            actions: [{ type: 'none' }],
          }),
          now,
        });
      }
    }

    if (state.missingSlots.length > 0) {
      this.setPhase(state, 'collecting_slots');
      resetConfirmation(state);
      const prompt = route.buildSlotPrompt(state.missingSlots, state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: prompt,
          askUser: {
            prompt,
            expectedSlots: state.missingSlots,
            candidates: Object.keys(state.ambiguousSlots).length > 0 ? state.ambiguousSlots : undefined,
          },
          executable: false,
          display: Object.keys(state.ambiguousSlots).length > 0 ? 'candidate_list' : 'slot_prompt',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    const needsConfirmation = route.needsConfirmation(state);
    const alreadyConfirmed = Boolean(state.confirmation.confirmedAt);
    if (needsConfirmation && !alreadyConfirmed) {
      this.setPhase(state, 'awaiting_confirmation');
      state.confirmation.required = true;
      state.confirmation.askedAt = now;
      const confirmation = route.buildConfirmation(state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: confirmation.prompt,
          confirmation,
          executable: false,
          display: 'confirmation_sheet',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    this.setPhase(state, 'ready_to_execute');
    const request = route.buildExecutionRequest(state, input);
    if (!request) {
      this.setPhase(state, 'completed');
      resetConfirmation(state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: route.buildCompletedMessage(state),
          executable: false,
          display: 'success',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    this.setPhase(state, 'executing');
    state.execution.request = request;
    const executionResult = await this.execution.execute(request);
    state.execution.result = executionResult;

    if (executionResult.requestClientAction) {
      state.execution.pendingClientAction = {
        ...executionResult.requestClientAction,
        askedAt: now,
      };
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: executionResult.summary,
          executable: false,
          display: 'loading',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    if (executionResult.success) {
      this.setPhase(state, 'completed');
      resetConfirmation(state);
      return this.finalizeAndSave({
        input,
        state,
        baseVersion,
        route,
        response: buildResponse({
          input,
          state,
          route,
          message: route.buildCompletedMessage(state),
          executable: false,
          display: 'success',
          actions: [{ type: 'none' }],
        }),
        now,
      });
    }

    state.execution.retries += 1;
    state.execution.lastErrorAt = now;
    const retryable = Boolean(executionResult.retryable);
    this.setPhase(state, retryable ? 'fallback' : 'failed');

    return this.finalizeAndSave({
      input,
      state,
      baseVersion,
      route,
      response: buildResponse({
        input,
        state,
        route,
        message: executionResult.summary,
        executable: false,
        display: 'error',
        actions: retryable ? [{ type: 'retry', route: route.id }] : [{ type: 'none' }],
        error: {
          code: executionResult.errorCode ?? 'EXECUTION_FAILED',
          message: executionResult.summary,
          retryable,
        },
      }),
      now,
    });
  }

  private applyInteractionSlotUpdate(input: AgentRouteInput, state: SessionState): void {
    if (input.interaction?.kind !== 'slot_update') return;
    const overwrite = input.interaction.overwrite ?? true;
    for (const [slotKey, value] of Object.entries(input.interaction.slots)) {
      const existing = state.slots[slotKey];
      if (existing && !overwrite) continue;
      state.slots[slotKey] = {
        key: slotKey,
        value,
        confidence: 1,
        sourceMessageId: input.messageId,
        updatedAt: input.timestamp ?? Date.now(),
      };
    }
  }

  private applyClientCapabilityResponse(
    route: RoutePlugin,
    state: SessionState,
    payload: ClientCapabilityResponsePayload,
  ): boolean {
    const pending = state.pendingClientCapabilityRequest;
    if (!pending || pending.requestId !== payload.requestId) return false;

    state.clientCapabilityHistory.push(payload);
    route.applyClientCapabilityResponse?.(state, payload);
    state.pendingClientCapabilityRequest = undefined;
    return true;
  }

  private applyClientActionResponse(
    state: SessionState,
    payload: ClientActionResponsePayload,
  ): boolean {
    const pending = state.execution.pendingClientAction;
    if (!pending || pending.requestId !== payload.requestId) return false;

    const route = this.getRoute(state.activeRoute);
    route.applyClientActionResponse?.(state, payload);
    state.execution.pendingClientAction = undefined;
    state.execution.result = {
      success: payload.success,
      summary: payload.success ? '客户端动作执行成功' : payload.error ?? '客户端动作执行失败',
      data: payload.result,
    };
    return payload.success;
  }

  private refreshMissingSlots(route: RoutePlugin, state: SessionState): void {
    const slotKeys = route.resolveMissingSlots?.(state) ?? route.requiredSlots.filter((slotKey) => {
      const slot = state.slots[slotKey];
      return !slot || !slot.value.trim();
    });
    state.missingSlots = slotKeys;
  }

  private getRoute(routeId: string): RoutePlugin {
    return this.routeMap.get(routeId) ?? this.fallback;
  }

  private isClientCapabilityResponse(
    input: AgentRouteInput,
  ): input is AgentRouteInput & { interaction: { kind: 'client_capability_response' | 'client_data_response'; payload: ClientCapabilityResponsePayload } } {
    return input.interaction?.kind === 'client_capability_response' || input.interaction?.kind === 'client_data_response';
  }

  private isClientActionResponse(
    input: AgentRouteInput,
  ): input is AgentRouteInput & { interaction: { kind: 'client_action_response'; payload: ClientActionResponsePayload } } {
    return input.interaction?.kind === 'client_action_response';
  }

  private async finalizeAndSave(params: {
    input: AgentRouteInput;
    state: SessionState;
    baseVersion: number;
    route: RoutePlugin;
    response: AgentRouteOutput;
    now: number;
  }): Promise<AgentRouteOutput> {
    const expectedNextVersion = params.baseVersion + 1;
    const response: AgentRouteOutput = {
      ...params.response,
      sessionVersion: expectedNextVersion,
    };

    appendAssistantMessage(params.state, params.input.turnId, params.input.messageId, response.message, params.now);
    markProcessedTurn(params.state, params.input, response, params.now);

    try {
      await this.store.save(params.state, params.baseVersion);
      return response;
    } catch (error) {
      const latest = await this.store.get(params.state.sessionId);
      const fallbackState = latest ?? params.state;
      return buildResponse({
        input: params.input,
        state: fallbackState,
        route: params.route,
        message: '会话写入冲突，请客户端刷新后重试。',
        executable: false,
        display: 'error',
        error: {
          code: 'SESSION_SAVE_CONFLICT',
          message: error instanceof Error ? error.message : 'unknown save conflict',
          retryable: true,
        },
      });
    }
  }

  private setPhase(state: SessionState, next: SessionState['phase']): void {
    assertPhaseTransition(state.phase, next);
    state.phase = next;
  }
}
