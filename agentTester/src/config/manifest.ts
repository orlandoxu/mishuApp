import type { CapabilityManifestItem } from '../types/index.js';

export const capabilityManifest: CapabilityManifestItem[] = [
  { id: 'agent.chat', appFeature: '首页语音闲聊', status: 'connected', ownerRoute: 'chat', notes: '已接 Agent 路由。' },
  { id: 'agent.food.create', appFeature: '美食记忆-对话新增', status: 'connected', ownerRoute: 'food', notes: '核心流程已接。' },
  { id: 'agent.money.record', appFeature: '小钱罐-对话记账', status: 'connected', ownerRoute: 'money', notes: '本地动作回传依赖协议一致性。' },
  { id: 'agent.contact.action', appFeature: '联系人-对话动作', status: 'connected', ownerRoute: 'contact', notes: '执行器仍有占位风险。' },
  { id: 'agent.task.action', appFeature: '待办-对话动作', status: 'connected', ownerRoute: 'task', notes: '执行器仍有占位风险。' },
  { id: 'agent.reminder.action', appFeature: '提醒-对话动作', status: 'connected', ownerRoute: 'reminder', notes: '执行器仍有占位风险。' },

  { id: 'app.treehole.chat', appFeature: '树洞聊天', status: 'not_connected', notes: '当前是页面内本地聊天，不走 Agent 后端。' },
  { id: 'app.partner.binding', appFeature: 'TA 邀请绑定', status: 'not_connected', notes: '走 REST，未接 Agent。' },
  { id: 'app.pro.payment', appFeature: 'Pro 支付', status: 'not_connected', notes: '支付链路未接 Agent。' },
  { id: 'app.settings.privacy', appFeature: '设置与隐私', status: 'not_connected', notes: '未接 Agent。' },
  { id: 'app.memory.profile', appFeature: '个人画像', status: 'not_connected', notes: '已定为隐藏入口，暂不开发。' },
  { id: 'app.child.module', appFeature: '孩子模块', status: 'not_connected', notes: '已定为隐藏入口，暂不开发。' }
];
