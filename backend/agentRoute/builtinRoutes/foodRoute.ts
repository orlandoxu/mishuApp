import type {
  AgentRouteInput,
  ConfirmationPayload,
  ExecutionRequest,
  RouteIntentResult,
  RoutePlugin,
  SessionState,
  SlotExtraction,
} from '../types';

function detectIntent(_: AgentRouteInput): RouteIntentResult {
  return { confidence: 0, reason: 'food route intent is decided by AI router only' };
}

function extractSlots(_: AgentRouteInput): SlotExtraction {
  // 槽位仅由 AI 路由结果写入 state.slots；这里不做关键词/正则规则提取。
  return { filled: {} };
}

function buildConfirmation(_: SessionState): ConfirmationPayload {
  return {
    prompt: '美食记忆信息已收齐，即将创建。',
    summary: '',
  };
}

function buildExecutionRequest(
  state: SessionState,
  input: AgentRouteInput,
): ExecutionRequest | null {
  const userId = input.clientContext?.userId;
  const name = state.slots.name?.value?.trim();
  const category = state.slots.category?.value?.trim();
  const review = state.slots.review?.value?.trim();
  const price = Number(state.slots.pricePerPerson?.value ?? '');
  if (!userId || !name || !category || !review || !Number.isFinite(price) || price < 0) {
    return null;
  }

  return {
    requestKey: `${state.sessionId}:${input.messageId}:food`,
    route: 'food',
    action: 'food.create',
    payload: {
      userId,
      name,
      category,
      pricePerPerson: price,
      review,
      rating: Number(state.slots.rating?.value ?? 4) || 4,
      visitedAt: Number(state.slots.visitedAt?.value ?? Date.now()) || Date.now(),
      lat: Number(state.slots.lat?.value ?? 0) || 0,
      lng: Number(state.slots.lng?.value ?? 0) || 0,
      address: state.slots.address?.value?.trim() ?? '',
      features: splitCsv(state.slots.features?.value),
      signatureDishes: splitCsv(state.slots.signatureDishes?.value),
      avoidDishes: splitCsv(state.slots.avoidDishes?.value),
      photos: splitCsv(state.slots.photos?.value),
    },
  };
}

function splitCsv(value?: string): string[] {
  if (!value) return [];
  return value
    .split(/[，,、|]/)
    .map((x) => x.trim())
    .filter(Boolean);
}

export const foodRoute: RoutePlugin = {
  id: 'food',
  description: 'Food memory creation route.',
  requiredSlots: ['name', 'category', 'pricePerPerson', 'review'],
  detectIntent,
  extractSlots,
  buildSlotPrompt(missingSlots) {
    if (missingSlots.length === 0) return '请补充美食记忆信息。';
    if (missingSlots.length <= 2) {
      const slotLabels: Record<string, string> = {
        name: '店名',
        category: '菜系',
        pricePerPerson: '人均消费',
        review: '点评',
      };
      const labels = missingSlots.map((key) => slotLabels[key] ?? key).join('，');
      return `很棒，再告诉我这家店的${labels}，我一起帮你记下来吧！`;
    }
    return '好呀！告诉我餐厅的名字、人均消费、特色菜，点评一下呗。我会帮你记录下来的哦。';
  },
  needsConfirmation() {
    return false;
  },
  buildConfirmation,
  buildExecutionRequest,
  buildCompletedMessage(state: SessionState): string {
    return `已创建美食记忆：${state.slots.name?.value ?? '未命名店铺'}`;
  },
};
