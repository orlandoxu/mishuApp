import { dbConn } from '../common/mongoInstance.js';
import { redis } from '../common/redisInstance.js';

export type DependencyHealth = {
  redis: 'ok' | 'error';
  mongodb: 'ok' | 'error';
};

export class InfraHealthService {
  static async checkDependencies(): Promise<DependencyHealth> {
    const [redisState, mongoState] = await Promise.all([
      redis
        .ping()
        .then(() => 'ok' as const)
        .catch(() => 'error' as const),
      dbConn
        .asPromise()
        .then(() => 'ok' as const)
        .catch(() => 'error' as const),
    ]);

    return {
      redis: redisState,
      mongodb: mongoState,
    };
  }
}
