export class RestError extends Error {
  code: number;

  constructor(message = '', code = 10000) {
    super(message);
    this.code = code;
  }
}

export class RestErrorWithData<TData = unknown> extends Error {
  code: number;
  data: TData;

  constructor(data: TData, message = 'ok', code = 0) {
    super(message);
    this.code = code;
    this.data = data;
  }
}

export function ASSERT(expr: unknown, message = '', code = 10000): asserts expr {
  if (!expr) {
    throw new RestError(message, code);
  }
}

export function ASSERT_NOT(expr: unknown, message = '', code = 10000): void {
  if (expr) {
    throw new RestError(message, code);
  }
}

export function REPLY<TData>(data: TData, message = 'ok', code = 0): never {
  throw new RestErrorWithData<TData>(data, message, code);
}

export function NewAssertNot(message = '', code = 10000): (expr: unknown) => void {
  return (expr: unknown) => ASSERT_NOT(expr, message, code);
}

export const Ret = {
  OK: 0,
  ERROR: 10000,
  NotLogin: 401,
  UserBaned: 400,
} as const;
