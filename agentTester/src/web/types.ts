import type { RunLayer, RunSuite, RunSummary, TestScenario } from '../types/index.js';

export type RunJobStatus = 'queued' | 'running' | 'done' | 'failed';

export type RunJob = {
  id: string;
  createdAt: string;
  startedAt?: string;
  endedAt?: string;
  status: RunJobStatus;
  payload: {
    layer: RunLayer;
    suite: RunSuite;
    env: 'local-frpc';
    scenarioIds?: string[];
  };
  error?: string;
  reportPath?: string;
  summary?: RunSummary;
};

export type TestListItem = {
  scenario: TestScenario;
  latestStatus: 'pass' | 'fail' | 'skip' | 'never';
  latestRunAt?: string;
  latestFailReason?: string;
  latestLayer?: 'engine' | 'rpc';
  latestIssues?: Array<{ kind: string; message: string }>;
  state: 'open' | 'resolved' | 'unknown';
  consecutiveFailCount: number;
};
