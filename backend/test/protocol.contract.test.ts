import { describe, expect, test } from 'bun:test';
import { AgentRoute } from '../agentRoute/AgentRoute';

/**
 * 协议契约测试：校验关键交互字段的稳定输出。
 */
describe('AgentRoute interaction protocol contract', () => {
  test('should request client vector data when contact is ambiguous', async () => {
    const engine = new AgentRoute();

    const response = await engine.handle({
      sessionId: 'contract-1',
      turnId: 't1',
      messageId: 'm1',
      text: '给那个张总发消息说我们改到明天开会',
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' },
    });

    expect(response.phase).toBe('collecting_slots');
    expect(response.protocol.recommendedInput).toBe('client_data_response');
    const requestDirective = response.protocol.directives.find((item) => item.type === 'request_client_data');
    expect(requestDirective).toBeDefined();

    if (requestDirective?.type === 'request_client_data') {
      expect(requestDirective.request.kind).toBe('vector_memory_search');
      expect(requestDirective.request.namespace).toBe('contacts');
    }

    expect(response.presentation.template).toBe('chat_bubble');
  });

  test('should consume client data response and continue confirmation flow', async () => {
    const engine = new AgentRoute();

    const first = await engine.handle({
      sessionId: 'contract-2',
      turnId: 't1',
      messageId: 'm1',
      text: '给那个张总发消息说我们改到明天开会',
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' },
    });

    const requestDirective = first.protocol.directives.find((item) => item.type === 'request_client_data');
    expect(requestDirective?.type).toBe('request_client_data');

    if (requestDirective?.type !== 'request_client_data') {
      throw new Error('missing request_client_data directive');
    }

    const second = await engine.handle({
      sessionId: 'contract-2',
      turnId: 't2',
      messageId: 'm2',
      text: '',
      interaction: {
        kind: 'client_data_response',
        payload: {
          requestId: requestDirective.request.requestId,
          kind: 'vector_memory_search',
          items: [{ text: '张伟', score: 0.92, metadata: { contactName: '张伟' } }],
        },
      },
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' },
    });

    expect(second.phase).toBe('awaiting_confirmation');
    expect(second.filledSlots.contactName).toBe('张伟');
    expect(second.protocol.recommendedInput).toBe('confirm_or_deny');
  });

  test('completed response should contain result_card component schema', async () => {
    const engine = new AgentRoute();

    await engine.handle({
      sessionId: 'contract-3',
      turnId: 't1',
      messageId: 'm1',
      text: '提醒我明天给李总发周报',
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' },
    });

    const done = await engine.handle({
      sessionId: 'contract-3',
      turnId: 't2',
      messageId: 'm2',
      text: '确认',
      clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' },
    });

    expect(done.phase).toBe('completed');
    expect(done.presentation.template).toBe('result_card');
    expect(done.presentation.components.some((item) => item.componentType === 'status_badge')).toBe(true);
    expect(done.presentation.components.some((item) => item.componentType === 'kv_grid')).toBe(true);
  });
});
