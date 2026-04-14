export type ApiResponse<T> = {
  ret: number;
  msg: string;
  data: T;
};

export function ok<T>(data: T, msg = 'ok', ret = 0): ApiResponse<T> {
  return {
    ret,
    msg,
    data,
  };
}
