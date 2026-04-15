import type { AgentPhase } from './types';

/**
 * 定义 AgentRoute 状态机允许的阶段转移集合。
 * 作用：避免多轮对话中出现非法跳变，保证服务端推进一致性。
 */
const PHASE_TRANSITIONS: Record<AgentPhase, ReadonlySet<AgentPhase>> = {
  intent_detected: new Set(['collecting_slots', 'awaiting_confirmation', 'ready_to_execute', 'fallback', 'cancelled']),
  collecting_slots: new Set(['intent_detected', 'collecting_slots', 'awaiting_confirmation', 'cancelled', 'fallback']),
  awaiting_confirmation: new Set(['intent_detected', 'collecting_slots', 'ready_to_execute', 'cancelled', 'fallback']),
  ready_to_execute: new Set(['executing', 'completed', 'failed', 'fallback', 'cancelled']),
  executing: new Set(['completed', 'failed', 'fallback']),
  completed: new Set(['intent_detected', 'cancelled']),
  failed: new Set(['intent_detected', 'collecting_slots', 'fallback', 'cancelled']),
  fallback: new Set(['intent_detected', 'collecting_slots', 'cancelled']),
  cancelled: new Set(['intent_detected']),
};

/**
 * 判断状态机是否允许从当前阶段迁移到目标阶段。
 */
export function canTransitionPhase(from: AgentPhase, to: AgentPhase): boolean {
  if (from === to) {
    return true;
  }
  return PHASE_TRANSITIONS[from].has(to);
}

/**
 * 强制校验阶段迁移；若不合法则抛错，让上层决定 fallback 处理策略。
 */
export function assertPhaseTransition(from: AgentPhase, to: AgentPhase): void {
  if (!canTransitionPhase(from, to)) {
    throw new Error(`INVALID_PHASE_TRANSITION: from=${from} to=${to}`);
  }
}
