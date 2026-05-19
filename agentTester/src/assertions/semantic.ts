import type { AssertionIssue } from '../types/index.js';

export function assertSemanticContains(message: string | undefined, expectedTokens: string[]): AssertionIssue[] {
  if (!expectedTokens.length) return [];
  const text = message ?? '';
  const miss = expectedTokens.filter((token) => !text.includes(token));
  if (miss.length === 0) return [];
  return [
    {
      severity: 'semantic',
      kind: 'model_flakiness',
      message: `语义校验失败，回复未命中关键 token: ${miss.join(', ')}`,
      hint: '检查模型波动或 prompt/系统设定。'
    }
  ];
}
