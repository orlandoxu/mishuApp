import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import type { RunSummary, ScenarioResult, TestScenario } from '../types/index.js';
import type { TestListItem } from './types.js';

export async function listReports(): Promise<Array<{ id: string; path: string; createdAt: string; summary: RunSummary }>> {
  const dir = path.resolve(process.cwd(), 'reports');
  let files: string[] = [];
  try {
    files = (await readdir(dir)).filter((x) => x.endsWith('.json') && x !== 'index.json').sort();
  } catch {
    return [];
  }

  const output: Array<{ id: string; path: string; createdAt: string; summary: RunSummary }> = [];
  for (const file of files) {
    try {
      const raw = await readFile(path.join(dir, file), 'utf8');
      const summary = JSON.parse(raw) as RunSummary;
      output.push({
        id: file.replace('.json', ''),
        path: path.join(dir, file),
        createdAt: summary.endedAt ?? '',
        summary
      });
    } catch {
      // ignore broken report
    }
  }
  return output;
}

export async function readReportById(id: string): Promise<RunSummary | null> {
  const file = path.resolve(process.cwd(), 'reports', `${id}.json`);
  try {
    const raw = await readFile(file, 'utf8');
    return JSON.parse(raw) as RunSummary;
  } catch {
    return null;
  }
}

export async function buildTestListView(scenarios: TestScenario[]): Promise<TestListItem[]> {
  const reports = await listReports();
  const sorted = reports.sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  return scenarios.map((scenario) => {
    const history = collectScenarioHistory(sorted.map((x) => x.summary), scenario.id);
    const latest = history[0];
    const lastFailIndex = history.findIndex((x) => x.verdict === 'fail');

    let state: 'open' | 'resolved' | 'unknown' = 'unknown';
    if (!latest) {
      state = 'unknown';
    } else if (latest.verdict === 'fail') {
      state = 'open';
    } else if (lastFailIndex >= 1) {
      state = 'resolved';
    } else {
      state = 'unknown';
    }

    let consecutiveFailCount = 0;
    for (const item of history) {
      if (item.verdict === 'fail') {
        consecutiveFailCount += 1;
      } else {
        break;
      }
    }

    return {
      scenario,
      latestStatus: latest?.verdict ?? 'never',
      latestRunAt: latest?.endedAt,
      latestFailReason: latest?.issues?.[0]?.message,
      latestLayer: latest?.layer,
      latestIssues: latest?.issues?.map((x) => ({ kind: x.kind, message: x.message })),
      state,
      consecutiveFailCount
    };
  });
}

function collectScenarioHistory(summaries: RunSummary[], scenarioId: string): Array<{
  verdict: 'pass' | 'fail' | 'skip';
  endedAt: string;
  layer?: 'engine' | 'rpc';
  issues?: Array<{ kind: string; message: string }>;
}> {
  const rows: Array<{
    verdict: 'pass' | 'fail' | 'skip';
    endedAt: string;
    layer?: 'engine' | 'rpc';
    issues?: Array<{ kind: string; message: string }>;
  }> = [];

  for (const summary of summaries) {
    const matches = summary.results.filter((x) => x.scenarioId === scenarioId);
    if (matches.length === 0) continue;

    const winner = pickWorst(matches);
    rows.push({
      verdict: winner.verdict,
      endedAt: summary.endedAt,
      layer: winner.layer,
      issues: winner.issues.map((x) => ({ kind: x.kind, message: x.message }))
    });
  }

  return rows;
}

function pickWorst(rows: ScenarioResult[]): ScenarioResult {
  const fail = rows.find((x) => x.verdict === 'fail');
  return fail ?? rows[0];
}
