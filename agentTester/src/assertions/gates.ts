import type { RunSummary } from '../types/index.js';

export function evaluateGate(summary: RunSummary): { ok: boolean; reasons: string[] } {
  const reasons: string[] = [];
  if (summary.protocolStrongPassRate < 1) {
    reasons.push(`协议强断言未达100%，当前 ${(summary.protocolStrongPassRate * 100).toFixed(2)}%`);
  }
  if (summary.criticalPassRate < 0.95) {
    reasons.push(`关键能力通过率未达95%，当前 ${(summary.criticalPassRate * 100).toFixed(2)}%`);
  }
  if (summary.normalPassRate < 0.9) {
    reasons.push(`普通能力通过率未达90%，当前 ${(summary.normalPassRate * 100).toFixed(2)}%`);
  }
  return { ok: reasons.length === 0, reasons };
}
