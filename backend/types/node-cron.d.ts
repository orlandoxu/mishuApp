declare module 'node-cron' {
  export type CronTask = {
    start: () => void;
    stop: () => void;
    destroy: () => void;
  };

  export type ScheduleOptions = {
    timezone?: string;
    name?: string;
    scheduled?: boolean;
  };

  export function schedule(expression: string, callback: () => void | Promise<void>, options?: ScheduleOptions): CronTask;

  const cron: {
    schedule: typeof schedule;
  };

  export default cron;
}
