import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { RunSummary } from '../types/index.js';

export async function writeJsonReport(summary: RunSummary): Promise<string> {
  const dir = path.resolve(process.cwd(), 'reports');
  await mkdir(dir, { recursive: true });
  const file = path.join(dir, `report-${Date.now()}.json`);
  await writeFile(file, JSON.stringify(summary, null, 2), 'utf8');
  return file;
}
