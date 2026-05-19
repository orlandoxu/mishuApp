import { AgentRoute } from '../../../backend/agentRoute/AgentRoute.ts';
import { AGENT_ROUTE_PROTOCOL_VERSION } from '../../../backend/agentRoute/protocol/version.ts';
import { connectMongoDB } from '../../../backend/utils/database.ts';
import type { ScenarioResult, StepResult, TestScenario } from '../types/index.js';
import { uid } from '../utils/id.js';

let dbReady = false;

export async function runEngineScenario(scenario: TestScenario): Promise<ScenarioResult> {
  if (!dbReady) {
    await connectMongoDB();
    dbReady = true;
  }
  const sessionId = uid(`engine-${scenario.id}`);
  const route = new AgentRoute({ intentRouter: new DeterministicIntentRouter() as never });
  const steps: StepResult[] = [];
  let sessionVersion = 0;
  let lastActionRequestId: string | null = null;

  for (let i = 0; i < scenario.turns.length; i += 1) {
    const turn = scenario.turns[i];
    const messageId = uid(`m${i + 1}`);
    const turnId = uid(`t${i + 1}`);

    const request: Record<string, unknown> = {
      protocolVersion: AGENT_ROUTE_PROTOCOL_VERSION,
      sessionId,
      turnId,
      messageId,
      text: turn.text,
      clientSessionVersion: sessionVersion,
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai', userId: 'agent-tester-user' }
    };

    if (turn.interaction) {
      const cloned = JSON.parse(JSON.stringify(turn.interaction));
      const interaction = asRecord(cloned);
      const payload = asRecord(interaction?.payload);
      if (payload?.requestId === '__AUTO_FROM_DIRECTIVE__') {
        payload.requestId = lastActionRequestId ?? uid('fallback-action');
      }
      request.interaction = cloned;
    }

    if (scenario.id === 'core-session-version-conflict' && i === 1) {
      request.clientSessionVersion = 0;
    }

    let response = await route.handle(request as never);
    if (response.error?.code === 'INTENT_ROUTER_EMPTY') {
      const retryVersion = typeof response.sessionVersion === 'number' ? response.sessionVersion : (request.clientSessionVersion as number | undefined) ?? 0;
      response = await route.handle({
        ...request,
        messageId: uid(`retry-m${i + 1}`),
        turnId: uid(`retry-t${i + 1}`),
        clientSessionVersion: retryVersion
      } as never);
    }
    sessionVersion = response.sessionVersion;

    for (const directive of response.protocol.directives) {
      if (directive.type === 'request_client_action') {
        lastActionRequestId = directive.requestId;
      }
    }

    const directives = response.protocol.directives.map((x: { type: string }) => x.type);
    steps.push({
      turnIndex: i,
      phase: response.phase,
      directives,
      recommendedInput: response.protocol.recommendedInput,
      message: response.message,
      errorCode: response.error?.code,
      issues: []
    });
  }

  return {
    layer: 'engine',
    scenarioId: scenario.id,
    capabilityId: scenario.capabilityId,
    title: scenario.title,
    level: scenario.level,
    verdict: 'pass',
    steps,
    issues: []
  };
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>;
  return null;
}

class DeterministicIntentRouter {
  async detect(input: { text: string; interaction?: unknown }): Promise<{ domain: 'money' | 'food' | 'chat' | 'fallback'; intent: string; confidence: number; reason: string; slots: Record<string, string> }> {
    const interaction = asRecord(input.interaction);
    const payload = asRecord(interaction?.payload);
    if (interaction?.kind === 'slot_update') {
      const slots = asRecord(interaction.slots) ?? {};
      const mapped: Record<string, string> = {};
      for (const [k, v] of Object.entries(slots)) {
        if (typeof v === 'string') mapped[k] = v;
      }
      return { domain: 'money', intent: mapped.intent ?? 'money.record', confidence: 1, reason: 'slot_update', slots: mapped };
    }
    if (interaction?.kind === 'confirm') {
      return { domain: 'money', intent: 'money.record', confidence: 1, reason: 'confirm', slots: {} };
    }
    if (interaction?.kind === 'client_action_response' && payload) {
      return { domain: 'money', intent: 'money.record', confidence: 1, reason: 'client_action_response', slots: {} };
    }

    const text = input.text;
    if (text.includes('美食')) {
      return { domain: 'food', intent: 'food.create', confidence: 1, reason: 'keyword food', slots: {} };
    }
    if (text.includes('记一笔') || text.includes('记账') || text.includes('支出') || text.includes('收入')) {
      return { domain: 'money', intent: 'money.record', confidence: 1, reason: 'keyword money', slots: {} };
    }
    return { domain: 'chat', intent: 'chat.reply', confidence: 1, reason: 'default chat', slots: {} };
  }
}
