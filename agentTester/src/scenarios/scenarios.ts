import type { TestScenario } from '../types/index.js';

export const scenarios: TestScenario[] = [
  {
    id: 'smoke-chat-basic',
    capabilityId: 'agent.chat',
    title: '闲聊场景应返回可渲染协议',
    level: 'normal',
    tags: ['smoke', 'protocol'],
    suite: 'smoke',
    turns: [{ text: '你好，我今天有点焦虑。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true,
    semanticExpectations: ['我', '你']
  },
  {
    id: 'core-food-create',
    capabilityId: 'agent.food.create',
    title: '美食记忆创建应进入执行并最终完成或补槽',
    level: 'critical',
    tags: ['core', 'food'],
    suite: 'core',
    turns: [
      { text: '帮我记一条美食记忆：店名阿芳面馆，人均35，点评很鲜，分类小吃。' }
    ],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true,
    semanticExpectations: ['美食', '记录']
  },
  {
    id: 'core-money-record',
    capabilityId: 'agent.money.record',
    title: '记账场景应走 request_client_action 并完成闭环',
    level: 'critical',
    tags: ['core', 'money', 'action'],
    suite: 'core',
    turns: [
      { text: '记一笔支出，午饭45元，分类餐饮。' },
      {
        text: '',
        interaction: {
          kind: 'client_action_response',
          payload: {
            requestId: '__AUTO_FROM_DIRECTIVE__',
            action: 'money.record',
            success: true,
            result: { saved: true }
          }
        }
      }
    ],
    expectedPhasePath: ['collecting_slots', 'completed'],
    requiredDirectives: ['request_client_action', 'completed'],
    requiresProtocolV3Only: true
  },
  {
    id: 'core-session-version-conflict',
    capabilityId: 'agent.chat',
    title: 'session version 过期应返回 sync_required / conflict',
    level: 'critical',
    tags: ['core', 'version'],
    suite: 'core',
    turns: [
      { text: '先给我一个响应。' },
      { text: '再次发送，但用旧版本。' }
    ],
    requiredDirectives: ['sync_required'],
    requiresProtocolV3Only: true
  },
  {
    id: 'full-cancel-flow',
    capabilityId: 'agent.task.action',
    title: '取消指令应进入 cancelled',
    level: 'normal',
    tags: ['full', 'cancel'],
    suite: 'full',
    turns: [{ text: '取消' }],
    expectedPhasePath: ['cancelled'],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  }
];
