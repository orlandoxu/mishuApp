import { env } from '../config/env';

export class ApiError extends Error {
  constructor(
    message: string,
    readonly code: number,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

type ApiEnvelope<T> = {
  ret?: number;
  msg?: string;
  message?: string;
  data?: T;
};

type RequestOptions = {
  signal?: AbortSignal;
};

function endpointUrl(path: string): string {
  const base = env.apiBaseUrl.replace(/\/$/, '');
  return `${base}${path.startsWith('/') ? path : `/${path}`}`;
}

export async function apiRequest<T>(
  path: string,
  init: RequestInit = {},
  options: RequestOptions = {},
): Promise<T> {
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), 12_000);
  const signal = options.signal ?? controller.signal;

  try {
    const response = await fetch(endpointUrl(path), {
      ...init,
      signal,
      headers: {
        'Content-Type': 'application/json',
        ...(init.headers ?? {}),
      },
    });
    const envelope = (await response.json().catch(() => ({}))) as ApiEnvelope<T>;
    const ret = envelope.ret ?? response.status;
    const message = envelope.msg ?? envelope.message ?? '请求失败，请稍后再试';

    if (!response.ok || ret !== 0) {
      throw new ApiError(message, ret);
    }

    return envelope.data as T;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new ApiError('请求超时，请稍后再试', 408);
    }
    throw new ApiError('网络异常，请稍后再试', 400);
  } finally {
    window.clearTimeout(timeoutId);
  }
}
