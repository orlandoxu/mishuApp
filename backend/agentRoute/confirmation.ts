import type { AgentRouteInput, SessionState } from './types';

const POSITIVE = /^(确认|确定|好的|好|可以|是|对|yes|y|ok|sure|confirm)$/i;
const NEGATIVE = /^(取消|不用|不|否|no|n|deny|算了)$/i;

export type ConfirmationVerdict = 'confirmed' | 'denied' | 'unknown';

/**
 * 将用户文本解析为确认态判定结果。
 */
export function parseConfirmation(input: AgentRouteInput): ConfirmationVerdict {
  const text = input.text.trim();
  if (!text) {
    return 'unknown';
  }

  if (POSITIVE.test(text)) {
    return 'confirmed';
  }

  if (NEGATIVE.test(text)) {
    return 'denied';
  }

  return 'unknown';
}

/**
 * 重置确认状态，通常用于改口或重新收集参数场景。
 */
export function resetConfirmation(state: SessionState): void {
  state.confirmation = {
    required: false,
  };
}
