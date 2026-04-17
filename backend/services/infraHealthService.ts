import { redis } from '../common/redisInstance';
import { wsRuntimeState, type WsStatus } from '../socket';
import { getMongoDBConnectionState } from '../utils/database';

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
    const [redisState] = await Promise.all([
      redis
        .ping()
        .then(() => 'ok' as const)
        .catch(() => 'error' as const),
    ]);

    const mongoState = getMongoDBConnectionState() === 'connected' ? 'ok' : 'error';

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
