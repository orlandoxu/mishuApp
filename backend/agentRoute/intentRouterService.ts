import { DoubaoService } from '../services/doubaoService';
import type { AgentRouteInput, RouteId, SessionState } from './types';

type IntentDetectResult = {
  domain: 'money' | 'reminder' | 'contact' | 'task' | 'chat' | 'fallback';
  intent: string;
  confidence: number;
  reason: string;
  slots: Record<string, string>;
};

const SYSTEM_PROMPT = [
  '你是一个严格的意图路由器，需要从可用能力中选择最合适的能力。',
  '只输出 JSON。',
  'domain 只能是: money|reminder|contact|task|chat|fallback。',
  'intent 必须是该 domain 下的能力标识。',
  '能力目录：',
  '- money.record: 记录收支流水（提取 amount/direction/category/note）。',
  '- money.query: 查询收支统计（今天/本周/本月）。',
  '- reminder.create: 创建提醒。',
  '- contact.manage: 联系人相关操作。',
  '- task.create: 创建任务。',
  '- chat.reply: 普通聊天回复。',
  '- fallback.unknown: 无法确定能力。',
  'confidence 为 0~1 的数字。',
  'slots 只放明确提到的信息。',
].join('\n');

export class IntentRouterService {
  async detect(input: AgentRouteInput, state: SessionState): Promise<IntentDetectResult | null> {
    const userText = input.text.trim();
    if (!userText) return null;

    try {
      const history = state.history
        .slice(-8)
        .map((item) => `${item.actor}:${item.text}`)
        .join('\n');

      const result = await withTimeout(
        DoubaoService.jsonCompletion<IntentDetectResult>({
          userId: input.clientContext?.userId ?? input.clientContext?.deviceId,
          temperature: 0,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            {
              role: 'user',
              content: `历史:\n${history || '无'}\n\n当前输入:\n${userText}`,
            },
          ],
          jsonSchemaHint:
            '{"domain":"money|reminder|contact|task|chat|fallback","intent":"money.record|money.query|reminder.create|contact.manage|task.create|chat.reply|fallback.unknown","confidence":0.0,"reason":"string","slots":{"key":"value"}}',
        }),
        15000,
      );

      if (!result.data || typeof result.data !== 'object') return null;
      const parsed = result.data;
      if (typeof parsed.domain !== 'string' || typeof parsed.confidence !== 'number') return null;

      return {
        domain: normalizeDomain(parsed.domain),
        intent: typeof parsed.intent === 'string' ? parsed.intent.trim().toLowerCase() : 'fallback.unknown',
        confidence: Math.max(0, Math.min(1, parsed.confidence)),
        reason: typeof parsed.reason === 'string' ? parsed.reason : 'llm_intent',
        slots: isRecord(parsed.slots) ? normalizeSlots(parsed.slots) : {},
      };
    } catch {
      return null;
    }
  }
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | null = null;
  try {
    return await Promise.race([
      promise,
      new Promise<T>((_, reject) => {
        timer = setTimeout(() => reject(new Error('intent_router_timeout')), timeoutMs);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

function normalizeDomain(raw: string): RouteId {
  const text = raw.trim().toLowerCase();
  if (text === 'money' || text === 'reminder' || text === 'contact' || text === 'task' || text === 'chat') {
    return text;
  }
  return 'fallback';
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function normalizeSlots(slots: Record<string, unknown>): Record<string, string> {
  const output: Record<string, string> = {};
  for (const [k, v] of Object.entries(slots)) {
    if (typeof v === 'string' && v.trim()) {
      output[k] = v.trim();
    } else if (typeof v === 'number' && Number.isFinite(v)) {
      output[k] = `${v}`;
    }
  }
  return output;
}
