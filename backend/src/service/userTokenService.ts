import { loadUserByToken, issueToken } from '../lib/tokenStore.js';
import type { RedisUser } from '../config/config.js';

export class UserTokenService {
  static async ensureLastUserRedis(token: string): Promise<RedisUser | null> {
    return loadUserByToken(token);
  }

  static async mockLogin(name: string): Promise<{ token: string; user: RedisUser }> {
    const user: RedisUser = {
      id: `user-${name}`,
      noId: 1,
      realName: name,
      company: 'demo-company',
      status: 'active',
      iVer: 1,
      sVer: 1,
      v: 1,
    };

    const token = await issueToken(user);
    return { token, user };
  }
}
