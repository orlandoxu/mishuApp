import { writeJsonReport } from '../reporters/jsonReporter.js';
import { writeMarkdownReport } from '../reporters/markdownReporter.js';
import { runAll } from '../core/runner.js';
import { uid } from '../utils/id.js';
import type { RunLayer, RunSuite } from '../types/index.js';
import type { RunJob } from './types.js';

const jobs = new Map<string, RunJob>();
const queue: string[] = [];
let runningJobId: string | null = null;

export function enqueueRun(payload: {
  layer: RunLayer;
  suite: RunSuite;
  env: 'local-frpc';
  scenarioIds?: string[];
}): RunJob {
  const job: RunJob = {
    id: uid('runjob'),
    createdAt: new Date().toISOString(),
    status: 'queued',
    payload
  };

  jobs.set(job.id, job);
  queue.push(job.id);
  void consumeQueue();
  return job;
}

export function getRunJob(id: string): RunJob | null {
  return jobs.get(id) ?? null;
}

export function listRunJobs(limit = 30): RunJob[] {
  return [...jobs.values()]
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .slice(0, limit);
}

async function consumeQueue(): Promise<void> {
  if (runningJobId) return;
  const next = queue.shift();
  if (!next) return;

  const job = jobs.get(next);
  if (!job) {
    void consumeQueue();
    return;
  }

  runningJobId = job.id;
  job.status = 'running';
  job.startedAt = new Date().toISOString();

  try {
    const summary = await runAll({
      layer: job.payload.layer,
      suite: job.payload.suite,
      env: job.payload.env,
      scenarioIds: job.payload.scenarioIds
    });
    const reportPath = await writeJsonReport(summary);
    await writeMarkdownReport(summary);

    job.summary = summary;
    job.reportPath = reportPath;
    job.status = 'done';
  } catch (error) {
    job.error = error instanceof Error ? error.message : String(error);
    job.status = 'failed';
  } finally {
    job.endedAt = new Date().toISOString();
    runningJobId = null;
    void consumeQueue();
  }
}
