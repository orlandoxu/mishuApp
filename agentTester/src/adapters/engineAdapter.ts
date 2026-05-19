import { AgentRoute } from '../../../backend/agentRoute/AgentRoute.ts';
import { AGENT_ROUTE_PROTOCOL_VERSION } from '../../../backend/agentRoute/protocol/version.ts';
import type { ScenarioResult, StepResult, TestScenario } from '../types/index.js';
import { uid } from '../utils/id.js';

export async function runEngineScenario(scenario: TestScenario): Promise<ScenarioResult> {
  const sessionId = uid(`engine-${scenario.id}`);
  const route = new AgentRoute();
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

    const response = await route.handle(request as never);
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
