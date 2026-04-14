import { loadUserByToken, issueToken } from '../lib/tokenStore.js';
import type { RedisUser } from '../config/config.js';

export class UserTokenService {
  static ensureLastUserRedis(token: string): RedisUser | null {
    return loadUserByToken(token);
  }

  static mockLogin(name: string): { token: string; user: RedisUser } {
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

    const token = issueToken(user);
    return { token, user };
  }
}
