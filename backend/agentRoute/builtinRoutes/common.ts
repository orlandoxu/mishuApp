/**
 * 判断文本中是否包含任一关键词。
 */
export function hasAnyKeyword(text: string, keywords: string[]): boolean {
  const lower = text.toLowerCase();
  return keywords.some((keyword) => lower.includes(keyword.toLowerCase()));
}

/**
 * 从 marker 之后提取文本片段。
 */
export function extractAfter(text: string, marker: string): string | null {
  const index = text.indexOf(marker);
  if (index < 0) {
    return null;
  }
  const raw = text.slice(index + marker.length).trim();
  return raw ? raw : null;
}

/**
 * 压缩多余空白，统一文本格式。
 */
export function compactText(text: string): string {
  return text.replace(/\s+/g, ' ').trim();
}

/**
 * 提取常见时间表达（轻量规则版）。
 */
export function firstTimeLike(text: string): string | null {
  const match = text.match(
    /(今天|明天|后天|今晚|明早|明天下午|明天上午|\d{1,2}点(?:半)?|\d{1,2}:\d{2}|\d{1,2}月\d{1,2}日(?:\s*\d{1,2}点(?:\d{1,2}分)?)?)/,
  );

  return match?.[0] ?? null;
}

/**
 * 从文本中猜测联系人名称（轻量规则版）。
 */
export function simpleNameGuess(text: string): string | null {
  const normalized = compactText(text);
  const quoted = normalized.match(/["“](.+?)["”]/);
  if (quoted?.[1]) {
    return quoted[1];
  }

  const named = normalized.match(/(?:给|联系|告诉|通知|打给)([\u4e00-\u9fa5A-Za-z]{2,12})/);
  return named?.[1] ?? null;
}
