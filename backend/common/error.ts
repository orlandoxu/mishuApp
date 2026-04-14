export class RestError extends Error {
  code: number;

  constructor(message = '', code = 10000) {
    super(message);
    this.code = code;
  }
}

export function ASSERT(expr: unknown, message = '', code = 10000): asserts expr {
  if (!expr) {
    throw new RestError(message, code);
  }
}

export const Ret = {
  OK: 0,
  ERROR: 10000,
  NotLogin: 401,
  UserBaned: 400,
} as const;
