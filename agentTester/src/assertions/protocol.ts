import type { AssertionIssue } from '../types/index.js';

const LEGACY_RECOMMENDED_INPUT = new Set(['client_data_response']);
const LEGACY_DIRECTIVES = new Set(['request_client_data']);
const LEGACY_INTERACTION_KINDS = new Set(['client_data_response']);

export function assertProtocolV3Strict(payload: unknown): AssertionIssue[] {
  const issues: AssertionIssue[] = [];
  const rec = asRecord(payload);
  if (!rec) {
    return [{ severity: 'strong', kind: 'protocol_failure', message: '响应不是对象结构。' }];
  }

  const protocol = asRecord(rec.protocol);
  if (!protocol) {
    issues.push({ severity: 'strong', kind: 'protocol_failure', message: '缺少 protocol 包络。' });
    return issues;
  }

  const version = protocol.version;
  if (typeof version !== 'string' || version.trim().length === 0) {
    issues.push({ severity: 'strong', kind: 'protocol_failure', message: 'protocol.version 缺失。' });
  }

  const recommendedInput = protocol.recommendedInput;
  if (typeof recommendedInput !== 'string') {
    issues.push({ severity: 'strong', kind: 'protocol_failure', message: 'protocol.recommendedInput 缺失。' });
  } else if (LEGACY_RECOMMENDED_INPUT.has(recommendedInput)) {
    issues.push({ severity: 'strong', kind: 'protocol_failure', message: `检测到旧 recommendedInput 字段值: ${recommendedInput}` });
  }

  const directives = Array.isArray(protocol.directives) ? protocol.directives : [];
  for (const item of directives) {
    const d = asRecord(item);
    const type = typeof d?.type === 'string' ? d.type : '';
    if (LEGACY_DIRECTIVES.has(type)) {
      issues.push({ severity: 'strong', kind: 'protocol_failure', message: `检测到旧 directive: ${type}` });
    }
  }

  return issues;
}

export function assertInteractionNoLegacy(interaction: unknown): AssertionIssue[] {
  const rec = asRecord(interaction);
  const kind = typeof rec?.kind === 'string' ? rec.kind : '';
  if (LEGACY_INTERACTION_KINDS.has(kind)) {
    return [{ severity: 'strong', kind: 'protocol_failure', message: `请求使用了旧 interaction.kind: ${kind}` }];
  }
  return [];
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>;
  return null;
}
