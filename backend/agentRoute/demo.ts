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
}

void run();
