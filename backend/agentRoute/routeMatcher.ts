import { TERMINAL_PHASES, type AgentRouteInput, type RouteDecision, type RoutePlugin, type SessionState } from './types';

const LOCKED_PHASES: ReadonlySet<SessionState['phase']> = new Set([
  'collecting_slots',
  'awaiting_confirmation',
  'ready_to_execute',
  'executing',
]);

/**
 * 计算本轮应进入的路由。
 * 作用：在中间态优先“锁定当前 route”，其余情况按意图置信度选择最佳 route。
 */
export function decideRoute(
  routes: RoutePlugin[],
  fallbackRoute: RoutePlugin,
  input: AgentRouteInput,
  state: SessionState,
): RouteDecision {
  const currentRoute = routes.find((route) => route.id === state.activeRoute) ?? fallbackRoute;

  if (!TERMINAL_PHASES.has(state.phase) && LOCKED_PHASES.has(state.phase)) {
    return {
      route: currentRoute.id,
      confidence: 1,
      reason: `keep current route while in phase ${state.phase}`,
      keepCurrentRoute: true,
    };
  }

  const candidates = routes.map((route) => ({
    route,
    result: route.detectIntent(input, state),
  }));

  candidates.sort((a, b) => b.result.confidence - a.result.confidence);
  const top = candidates[0];

  if (!top || top.result.confidence < 0.35) {
    return {
      route: fallbackRoute.id,
      confidence: 0,
      reason: 'no reliable intent detected, fallback route selected',
      keepCurrentRoute: false,
    };
  }

  return {
    route: top.route.id,
    confidence: top.result.confidence,
    reason: top.result.reason ?? 'intent score matched',
    keepCurrentRoute: top.route.id === state.activeRoute,
  };
}
