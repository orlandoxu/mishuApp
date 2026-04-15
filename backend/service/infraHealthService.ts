import { dbConn } from '../common/mongoInstance';
import { redis } from '../common/redisInstance';
import { wsRuntimeState, type WsStatus } from '../socket';

export type DependencyHealth = {
  redis: 'ok' | 'error';
  mongodb: 'ok' | 'error';
  websocket: {
    ws: WsStatus;
    wsClients: number;
  };
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
      websocket: {
        ws: wsRuntimeState.ws,
        wsClients: wsRuntimeState.wsClients,
      },
    };
  }
}
