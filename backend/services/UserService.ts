import { User } from '../models/User';
import { ASSERT, Ret } from '../common/error';
import { DashboardDailyStatService } from './dashboardDailyStatService';

export interface AppLoginUser {
  userId: string;
  phoneNumber: string;
}

function normalizeMobile(value: string): string {
  return value.trim().replace(/\s+/g, '');
}

function normalizeMainlandMobile(raw: string): string | null {
  const compact = normalizeMobile(raw).replace(/^(\+86|0086|86)/, '');
  if (!/^1[3-9]\d{9}$/.test(compact)) {
    return null;
  }
  return compact;
}

export class UserService {
  static async findOrCreateByPhoneNumber(rawMobile: string): Promise<AppLoginUser> {
    const phoneNumber = normalizeMainlandMobile(rawMobile);
    ASSERT(phoneNumber, '仅支持中国大陆手机号', Ret.ERROR);

    let user = await User.findByPhoneNumber(phoneNumber);
    if (!user) {
      user = await User.createUser({ phoneNumber });
    } else {
      user = await User.updateLastLogin(user._id);
      ASSERT(user, '用户状态更新失败', Ret.ERROR);
    }

    ASSERT(user, '用户创建失败', Ret.ERROR);

    // 登录成功后写入“用户-日期”活跃静态明细，供夜间 cron 聚合。
    await DashboardDailyStatService.markUserActive(user._id.toString());

    return {
      userId: user._id.toString(),
      phoneNumber: user.phoneNumber,
    };
  }

  static normalizeMainlandMobile(rawMobile: string): string {
    const phoneNumber = normalizeMainlandMobile(rawMobile);
    ASSERT(phoneNumber, '仅支持中国大陆手机号', Ret.ERROR);
    return phoneNumber;
  }
}
