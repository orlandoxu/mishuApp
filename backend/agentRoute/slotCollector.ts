import type { AgentRouteInput, RoutePlugin, SessionState, SlotValue } from './types';

export type SlotCollectResult = {
  changedSlots: string[];
  missingSlots: string[];
};

/**
 * 从当前输入中抽取并增量更新 slots。
 * 规则：高置信度覆盖低置信度；同置信度时允许新值覆盖旧值。
 */
export function collectSlots(route: RoutePlugin, state: SessionState, input: AgentRouteInput): SlotCollectResult {
  const extraction = route.extractSlots(input, state);
  const now = input.timestamp ?? Date.now();
  const changedSlots: string[] = [];

  for (const [key, candidate] of Object.entries(extraction.filled)) {
    const previous = state.slots[key];
    const shouldReplace =
      !previous ||
      candidate.confidence > previous.confidence ||
      (candidate.confidence === previous.confidence && candidate.value !== previous.value);

    if (!shouldReplace) {
      continue;
    }

    const next: SlotValue = {
      key,
      value: candidate.value,
      confidence: candidate.confidence,
      sourceMessageId: input.messageId,
      updatedAt: now,
    };
    state.slots[key] = next;
    changedSlots.push(key);
  }

  state.ambiguousSlots = extraction.ambiguous ?? {};

  const missingSlots = route.requiredSlots.filter((slotKey) => {
    const slot = state.slots[slotKey];
    return !slot || slot.value.trim() === '';
  });

  state.missingSlots = missingSlots;

  return {
    changedSlots,
    missingSlots,
  };
}

/**
 * 将内部 SlotValue 投影为客户端可直接展示的 key/value 结构。
 */
export function projectFilledSlots(state: SessionState): Record<string, string> {
  return Object.fromEntries(Object.entries(state.slots).map(([k, v]) => [k, v.value]));
}
