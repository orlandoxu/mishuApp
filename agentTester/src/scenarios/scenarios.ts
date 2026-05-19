import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { TestScenario } from '../types/index.js';

const builtinScenarios: TestScenario[] = [
  {
    id: 'smoke-chat-basic',
    group: 'business',
    line: 'chat',
    capabilityId: 'agent.chat',
    title: '闲聊场景应返回可渲染协议',
    level: 'normal',
    tags: ['smoke', 'chat'],
    suite: 'smoke',
    enabled: true,
    turns: [{ text: '你好，我今天有点焦虑。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'special-agent-route-protocol-v3',
    group: 'special',
    line: 'agent_route_protocol',
    capabilityId: 'agent.chat',
    title: 'AgentRoute 协议专项：必须输出 v3 协议结构',
    level: 'critical',
    tags: ['special', 'protocol'],
    suite: 'core',
    enabled: true,
    turns: [{ text: '请确认你当前可用。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'special-state-machine-version-conflict',
    group: 'special',
    line: 'state_machine',
    capabilityId: 'agent.chat',
    title: '状态机专项：session version 过期应返回冲突错误',
    level: 'critical',
    tags: ['special', 'state-machine'],
    suite: 'core',
    enabled: true,
    turns: [
      { text: '先给我一个响应。' },
      { text: '再次发送，但用旧版本。' }
    ],
    requiredErrorCode: 'SESSION_VERSION_CONFLICT',
    requiresProtocolV3Only: true
  },
  {
    id: 'special-executor-money-closed-loop',
    group: 'special',
    line: 'executor',
    capabilityId: 'agent.money.record',
    title: '执行器专项：记账闭环应完成',
    level: 'critical',
    tags: ['special', 'executor', 'money'],
    suite: 'core',
    enabled: true,
    turns: [
      { text: '记一笔支出，午饭45元，分类餐饮。' },
      {
        text: '补充槽位',
        interaction: {
          kind: 'slot_update',
          slots: {
            intent: 'money.record',
            amount: '45',
            direction: 'expense',
            category: '餐饮',
            note: '午饭'
          }
        }
      },
      {
        text: '确认记账',
        interaction: {
          kind: 'confirm',
          decision: 'confirm'
        }
      }
    ],
    expectedPhasePath: ['collecting_slots'],
    requiredDirectives: ['confirm', 'completed'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-food-create',
    group: 'business',
    line: 'food',
    capabilityId: 'agent.food.create',
    title: '业务场景：美食记忆新增',
    level: 'critical',
    tags: ['business', 'food'],
    suite: 'core',
    enabled: true,
    turns: [{ text: '帮我记一条美食记忆：店名阿芳面馆，人均35，点评很鲜，分类小吃。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-money-record',
    group: 'business',
    line: 'money',
    capabilityId: 'agent.money.record',
    title: '业务场景：记账流程',
    level: 'critical',
    tags: ['business', 'money'],
    suite: 'core',
    enabled: true,
    turns: [
      { text: '记一笔支出，午饭45元，分类餐饮。' },
      {
        text: '补充槽位',
        interaction: {
          kind: 'slot_update',
          slots: {
            intent: 'money.record',
            amount: '45',
            direction: 'expense',
            category: '餐饮',
            note: '午饭'
          }
        }
      },
      { text: '确认记账', interaction: { kind: 'confirm', decision: 'confirm' } }
    ],
    requiredDirectives: ['confirm', 'completed'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-contact-action-smoke',
    group: 'business',
    line: 'contact',
    capabilityId: 'agent.contact.action',
    title: '业务场景：联系人动作冒烟',
    level: 'normal',
    tags: ['business', 'contact'],
    suite: 'full',
    enabled: true,
    turns: [{ text: '给张伟发消息说我们明天见面。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-task-action-smoke',
    group: 'business',
    line: 'task',
    capabilityId: 'agent.task.action',
    title: '业务场景：任务动作冒烟',
    level: 'normal',
    tags: ['business', 'task'],
    suite: 'full',
    enabled: true,
    turns: [{ text: '创建一个任务，明天下午三点前整理合同。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-reminder-action-smoke',
    group: 'business',
    line: 'reminder',
    capabilityId: 'agent.reminder.action',
    title: '业务场景：提醒动作冒烟',
    level: 'normal',
    tags: ['business', 'reminder'],
    suite: 'full',
    enabled: true,
    turns: [{ text: '提醒我明天早上8点吃药。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'biz-chat-general',
    group: 'business',
    line: 'chat',
    capabilityId: 'agent.chat',
    title: '业务场景：普通闲聊',
    level: 'normal',
    tags: ['business', 'chat'],
    suite: 'full',
    enabled: true,
    turns: [{ text: '最近压力很大，想聊聊。' }],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  },
  {
    id: 'full-cancel-flow',
    group: 'special',
    line: 'state_machine',
    capabilityId: 'agent.task.action',
    title: '状态机专项：取消指令应进入 cancelled',
    level: 'normal',
    tags: ['special', 'cancel'],
    suite: 'full',
    enabled: true,
    turns: [{ text: '取消' }],
    expectedPhasePath: ['cancelled'],
    requiredDirectives: ['assistant_message'],
    requiresProtocolV3Only: true
  }
];

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const externalScenarioDir = path.resolve(__dirname, '../../scenarios');

async function loadExternalScenarios(): Promise<TestScenario[]> {
  try {
    const files = (await readdir(externalScenarioDir)).filter((x) => x.endsWith('.json'));
    const loaded: TestScenario[] = [];
    for (const file of files) {
      const raw = await readFile(path.join(externalScenarioDir, file), 'utf8');
      const parsed = JSON.parse(raw) as TestScenario[];
      if (Array.isArray(parsed)) {
        loaded.push(...parsed);
      }
    }
    return loaded;
  } catch {
    return [];
  }
}

export async function loadScenarios(): Promise<TestScenario[]> {
  const external = await loadExternalScenarios();
  const all = [...builtinScenarios, ...external].filter((x) => x.enabled !== false);

  const seen = new Set<string>();
  const dedup: TestScenario[] = [];
  for (const scenario of all) {
    if (seen.has(scenario.id)) continue;
    seen.add(scenario.id);
    dedup.push(scenario);
  }
  return dedup;
}

export { builtinScenarios };
