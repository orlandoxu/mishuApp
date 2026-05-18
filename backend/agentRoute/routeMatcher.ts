import { TERMINAL_PHASES, type AgentRouteInput, type RouteDecision, type RoutePlugin, type SessionState } from './types';

const LOCKED_PHASES: ReadonlySet<SessionState['phase']> = new Set([
  'collecting_slots',
  'awaiting_confirmation',
  'ready_to_execute',
  'executing',
]);

export function decideRoute(
  routes: RoutePlugin[],
  input: AgentRouteInput,
  state: SessionState,
  llmHint?: { route: SessionState['activeRoute']; confidence: number; reason: string },
): RouteDecision {
  const currentRoute = routes.find((route) => route.id === state.activeRoute) ?? routes.find((route) => route.id === 'chat') ?? routes[0];

  if (!TERMINAL_PHASES.has(state.phase) && LOCKED_PHASES.has(state.phase)) {
    return {
      route: currentRoute.id,
      confidence: 1,
      reason: `keep current route while in phase ${state.phase}`,
      keepCurrentRoute: true,
    };
  }

  if (llmHint && llmHint.confidence >= 0.6 && llmHint.route !== 'fallback') {
    return {
      route: llmHint.route,
      confidence: llmHint.confidence,
      reason: llmHint.reason,
      keepCurrentRoute: llmHint.route === state.activeRoute,
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
      route: currentRoute.id,
      confidence: 0,
      reason: 'no reliable intent detected, keep current route for explicit handling',
      keepCurrentRoute: true,
    };
  }

  return {
    route: top.route.id,
    confidence: top.result.confidence,
    reason: top.result.reason ?? 'intent score matched',
    keepCurrentRoute: top.route.id === state.activeRoute,
  };
}
