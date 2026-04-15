import { AgentRoute } from './AgentRoute';

const engine = new AgentRoute();

/**
 * 本地最小演示：连续输入多轮文本，观察 route/phase/slots 的结构化输出。
 */
async function run(): Promise<void> {
  const sessionId = 'demo-session-1';

  const turns = [
    { messageId: 'm1', turnId: 't1', text: '明天下午提醒我给张总发周报' },
    { messageId: 'm2', turnId: 't2', text: '确认' },
    { messageId: 'm3', turnId: 't3', text: '帮我创建一个待办：周五前整理合同' },
    { messageId: 'm4', turnId: 't4', text: '好的' },
  ];

  for (const turn of turns) {
    const response = await engine.handle({
      sessionId,
      turnId: turn.turnId,
      messageId: turn.messageId,
      text: turn.text,
      clientContext: {
        platform: 'ios',
        timezone: 'Asia/Shanghai',
      },
    });

    console.log(JSON.stringify(response, null, 2));
  }

  const contactSession = 'demo-contact-vector';
  const contactTurns = [
    {
      messageId: 'c1',
      turnId: 'ct1',
      text: '给那个张总发消息说我们改到明天开会',
    },
    {
      messageId: 'c2',
      turnId: 'ct2',
      text: '',
      interaction: {
        kind: 'client_data_response' as const,
        payload: {
          requestId: `${contactSession}:c1:contact_vector`,
          kind: 'vector_memory_search' as const,
          items: [{ text: '张伟', score: 0.91, metadata: { contactName: '张伟' } }],
        },
      },
    },
    {
      messageId: 'c3',
      turnId: 'ct3',
      text: '确认',
    },
  ];

  for (const turn of contactTurns) {
    const response = await engine.handle({
      sessionId: contactSession,
      turnId: turn.turnId,
      messageId: turn.messageId,
      text: turn.text,
      interaction: turn.interaction,
      clientContext: {
        platform: 'ios',
        timezone: 'Asia/Shanghai',
      },
    });

    console.log(JSON.stringify(response, null, 2));
  }
}

void run();
