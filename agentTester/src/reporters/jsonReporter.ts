import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { RunSummary } from '../types/index.js';
import { readdir, readFile } from 'node:fs/promises';

export async function writeJsonReport(summary: RunSummary): Promise<string> {
  const dir = path.resolve(process.cwd(), 'reports');
  await mkdir(dir, { recursive: true });
  const file = path.join(dir, `report-${Date.now()}.json`);
  await writeFile(file, JSON.stringify(summary, null, 2), 'utf8');
  await refreshReportIndex(dir);
  return file;
}

async function refreshReportIndex(dir: string): Promise<void> {
  const files = (await readdir(dir)).filter((x) => x.endsWith('.json') && x !== 'index.json').sort();
  const history: Array<{ id: string; endedAt: string; gatePassed: boolean; totals: { passed: number; failed: number; skipped: number } }> = [];
  for (const file of files.slice(-100)) {
    try {
      const raw = await readFile(path.join(dir, file), 'utf8');
      const summary = JSON.parse(raw) as RunSummary;
      history.push({
        id: file.replace('.json', ''),
        endedAt: summary.endedAt,
        gatePassed: summary.gatePassed,
        totals: summary.totals
      });
    } catch {
      // ignore broken report
    }
  }

  history.sort((a, b) => b.endedAt.localeCompare(a.endedAt));
  const latest = history[0] ?? null;
  const index = { latest, history };
  await writeFile(path.join(dir, 'index.json'), JSON.stringify(index, null, 2), 'utf8');
}
