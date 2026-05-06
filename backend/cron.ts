import 'node-cron';
import cron from 'node-cron';
import { connectMongoDB } from './utils/database';
import { DashboardDailyStatService } from './services/dashboardDailyStatService';

async function runSnapshotJob(): Promise<void> {
  try {
    await DashboardDailyStatService.generateYesterdaySnapshot();
    console.log('[cron] dashboard snapshot generated for yesterday');
  } catch (error) {
    console.error('[cron] dashboard snapshot failed', error);
  }
}

async function bootstrapCron(): Promise<void> {
  await connectMongoDB();

  // 启动时先补偿一次，避免服务重启错过定时窗口。
  await runSnapshotJob();

  cron.schedule('5 0 * * *', () => {
    void runSnapshotJob();
  }, {
    timezone: 'Asia/Shanghai',
  });

  console.log('[cron] scheduler started: 00:05 Asia/Shanghai daily');
}

bootstrapCron().catch((error) => {
  console.error('[cron] bootstrap failed', error);
  process.exit(1);
});
