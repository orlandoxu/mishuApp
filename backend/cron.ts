import 'node-cron';
import cron from 'node-cron';
import { connectMongoDB } from './utils/database';
import { DashboardDailyStatService } from './services/dashboardDailyStatService';

async function runYesterdaySnapshotJob(): Promise<void> {
  try {
    await DashboardDailyStatService.generateYesterdaySnapshot();
    console.log('[cron] dashboard snapshot generated for yesterday');
  } catch (error) {
    console.error('[cron] dashboard snapshot failed', error);
  }
}

async function runTodaySnapshotJob(): Promise<void> {
  try {
    await DashboardDailyStatService.generateTodaySnapshot();
    console.log('[cron] dashboard snapshot refreshed for today');
  } catch (error) {
    console.error('[cron] dashboard today snapshot refresh failed', error);
  }
}

async function bootstrapCron(): Promise<void> {
  await connectMongoDB();

  // 启动时先补偿一次，避免服务重启错过定时窗口。
  await runYesterdaySnapshotJob();
  await runTodaySnapshotJob();

  cron.schedule('5 0 * * *', () => {
    void runYesterdaySnapshotJob();
  }, {
    timezone: 'Asia/Shanghai',
  });

  cron.schedule('9,19,29,39,49,59 * * * *', () => {
    void runTodaySnapshotJob();
  }, {
    timezone: 'Asia/Shanghai',
  });

  console.log('[cron] scheduler started: daily 00:05 + today refresh at minute 9/19/29/39/49/59 (Asia/Shanghai)');
}

bootstrapCron().catch((error) => {
  console.error('[cron] bootstrap failed', error);
  process.exit(1);
});
