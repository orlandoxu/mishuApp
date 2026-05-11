import { DoubaoService } from '../services/doubaoService';
import type { AgentRouteInput, RouteId, SessionState } from './types';

type IntentDetectResult = {
  route: RouteId;
  confidence: number;
  reason: string;
  slots: Record<string, string>;
};

const SYSTEM_PROMPT = [
  '你是一个严格的意图路由器。',
  '只输出 JSON。',
  'route 只能是: money|reminder|contact|task|chat|fallback。',
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
          userId: input.clientContext?.deviceId,
          temperature: 0,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            {
              role: 'user',
              content: `历史:\n${history || '无'}\n\n当前输入:\n${userText}`,
            },
          ],
          jsonSchemaHint:
            '{"route":"money|reminder|contact|task|chat|fallback","confidence":0.0,"reason":"string","slots":{"key":"value"}}',
        }),
        3000,
      );

      if (!result.data || typeof result.data !== 'object') return null;
      const parsed = result.data;
      if (typeof parsed.route !== 'string' || typeof parsed.confidence !== 'number') return null;

      return {
        route: normalizeRoute(parsed.route),
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

function normalizeRoute(raw: string): RouteId {
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
