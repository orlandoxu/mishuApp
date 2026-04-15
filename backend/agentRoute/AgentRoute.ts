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
import { contactExecutor, reminderExecutor, taskExecutor } from './builtinExecutors';
import { chatRoute } from './builtinRoutes/chatRoute';
import { contactRoute } from './builtinRoutes/contactRoute';
import { fallbackRoute } from './builtinRoutes/fallbackRoute';
import { reminderRoute } from './builtinRoutes/reminderRoute';
import { taskRoute } from './builtinRoutes/taskRoute';
import type { ClientDataResponsePayload } from './protocol';
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
};

const CANCEL_PATTERN = /^(取消|停止|cancel|abort)$/i;

export class AgentRoute {
  private readonly store: SessionStore;
  private readonly routes: RoutePlugin[];
  private readonly routeMap: Map<string, RoutePlugin>;
  private readonly fallback: RoutePlugin;
  private readonly execution: ExecutionOrchestrator;

  /**
   * 构造 AgentRoute 实例。
   * 作用：注入会话存储、路由插件、兜底路由与执行编排器，组装服务端运行时。
   */
  constructor(options: AgentRouteOptions = {}) {
    this.store = options.store ?? new InMemorySessionStore();
    this.routes = options.routes ?? [reminderRoute, contactRoute, taskRoute, chatRoute];
    this.fallback = options.fallback ?? fallbackRoute;
    this.routeMap = new Map(
      [...this.routes, this.fallback].map((route) => [route.id, route]),
    );

    this.execution =
      options.execution ??
      new ExecutionOrchestrator({
        reminder: reminderExecutor,
        contact: contactExecutor,
        task: taskExecutor,
      });
  }

  /**
   * 处理单条用户输入并推进会话状态。
   * 作用：完成去重、路由决策、槽位收集、确认门控、执行编排与结构化响应生成。
   */
  async handle(input: AgentRouteInput): Promise<AgentRouteOutput> {
    const now = input.timestamp ?? Date.now();
    const persisted = await this.store.get(input.sessionId);
    const state = persisted ?? createInitialSessionState(input.sessionId, now);
    const baseVersion = state.version;

    if (
      typeof input.clientSessionVersion === 'number' &&
      input.clientSessionVersion !== state.version
    ) {
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
    if (deduped) {
      return {
        ...deduped,
        deduped: true,
      };
    }

    appendUserMessage(state, input, now);
    state.currentTurnId = input.turnId;

    if (
      input.interaction?.kind === 'cancel' ||
      CANCEL_PATTERN.test(input.text.trim())
    ) {
      this.setPhase(state, 'cancelled');
      state.missingSlots = [];
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

    const decision = decideRoute(this.routes, this.fallback, input, state);
    const previousRoute = state.activeRoute;
    state.activeRoute = decision.route;
    const route = this.getRoute(decision.route);
    const previousPhase = state.phase;

    if (previousRoute !== route.id && !decision.keepCurrentRoute) {
      // 路由切换时清理旧路由遗留槽位，避免跨任务污染。
      const allowed = new Set(route.requiredSlots);
      state.slots = Object.fromEntries(
        Object.entries(state.slots).filter(([slotKey]) => allowed.has(slotKey)),
      );
      state.missingSlots = [];
      state.ambiguousSlots = {};
      state.pendingClientDataRequest = undefined;
      resetConfirmation(state);
    }

    this.applyInteractionSlotUpdate(input, state);
    this.setPhase(state, 'intent_detected');
    collectSlots(route, state, input);
    this.refreshMissingSlots(route, state);

    if (
      input.interaction?.kind === 'client_data_response' &&
      !this.applyClientDataResponse(route, state, input.interaction.payload)
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
          message: '客户端数据响应与当前请求不匹配，请重新同步后重试。',
          executable: false,
          display: 'error',
          error: {
            code: 'CLIENT_DATA_RESPONSE_MISMATCH',
            message: 'requestId mismatch or no pending request',
            retryable: true,
          },
        }),
        now,
      });
    }
    if (input.interaction?.kind === 'client_data_response') {
      this.refreshMissingSlots(route, state);
    }

    if (state.pendingClientDataRequest) {
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

    const clientDataRequest = route.buildClientDataRequest?.(input, state) ?? null;
    if (clientDataRequest) {
      state.pendingClientDataRequest = clientDataRequest;
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

  /**
   * 处理客户端主动覆盖槽位（例如表单改值后回传）。
   */
  private applyInteractionSlotUpdate(input: AgentRouteInput, state: SessionState): void {
    if (input.interaction?.kind !== 'slot_update') {
      return;
    }

    const overwrite = input.interaction.overwrite ?? true;
    for (const [slotKey, value] of Object.entries(input.interaction.slots)) {
      const existing = state.slots[slotKey];
      if (existing && !overwrite) {
        continue;
      }
      state.slots[slotKey] = {
        key: slotKey,
        value,
        confidence: 1,
        sourceMessageId: input.messageId,
        updatedAt: input.timestamp ?? Date.now(),
      };
    }
  }

  /**
   * 处理客户端数据请求响应并应用到当前 route。
   */
  private applyClientDataResponse(
    route: RoutePlugin,
    state: SessionState,
    payload: ClientDataResponsePayload,
  ): boolean {
    const pending = state.pendingClientDataRequest;
    if (!pending || pending.requestId !== payload.requestId) {
      return false;
    }

    state.clientDataHistory.push(payload);
    route.applyClientDataResponse?.(state, payload);
    state.pendingClientDataRequest = undefined;
    return true;
  }

  /**
   * 在路由内统一刷新 missingSlots。
   */
  private refreshMissingSlots(route: RoutePlugin, state: SessionState): void {
    state.missingSlots = route.requiredSlots.filter((slotKey) => {
      const slot = state.slots[slotKey];
      return !slot || !slot.value.trim();
    });
  }

  /**
   * 根据 routeId 获取路由插件；不存在时回落到 fallback。
   */
  private getRoute(routeId: string): RoutePlugin {
    return this.routeMap.get(routeId) ?? this.fallback;
  }

  /**
   * 统一完成响应写回与会话落库。
   * 作用：追加 assistant 消息、记录幂等快照、处理乐观并发冲突。
   */
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

    appendAssistantMessage(
      params.state,
      params.input.turnId,
      params.input.messageId,
      response.message,
      params.now,
    );

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

  /**
   * 受控地推进会话 phase。
   * 作用：在状态机规则内转移；若非法跳变则抛错，避免“中间态失控”。
   */
  private setPhase(state: SessionState, next: SessionState['phase']): void {
    assertPhaseTransition(state.phase, next);
    state.phase = next;
  }
}
