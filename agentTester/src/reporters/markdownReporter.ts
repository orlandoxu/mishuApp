import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { RunSummary } from '../types/index.js';

export async function writeMarkdownReport(summary: RunSummary): Promise<string> {
  const dir = path.resolve(process.cwd(), 'reports');
  await mkdir(dir, { recursive: true });
  const file = path.join(dir, `report-${Date.now()}.md`);

  const lines: string[] = [];
  lines.push(`# AgentTester Report`);
  lines.push(``);
  lines.push(`- window: ${summary.startedAt} ~ ${summary.endedAt}`);
  lines.push(`- env: ${summary.options.env}`);
  lines.push(`- layer: ${summary.options.layer}`);
  lines.push(`- suite: ${summary.options.suite}`);
  lines.push(`- gatePassed: ${summary.gatePassed ? 'YES' : 'NO'}`);
  lines.push(``);
  lines.push(`## Metrics`);
  lines.push(``);
  lines.push(`- protocolStrongPassRate: ${(summary.protocolStrongPassRate * 100).toFixed(2)}%`);
  lines.push(`- criticalPassRate: ${(summary.criticalPassRate * 100).toFixed(2)}%`);
  lines.push(`- normalPassRate: ${(summary.normalPassRate * 100).toFixed(2)}%`);
  lines.push(`- totals: ${summary.totals.passed} pass / ${summary.totals.failed} fail / ${summary.totals.skipped} skip`);
  lines.push(``);

  lines.push(`## Capability Matrix`);
  lines.push(``);
  lines.push(`| capabilityId | feature | status | tested | passed |`);
  lines.push(`|---|---|---|---|---|`);
  for (const row of summary.capabilityMatrix) {
    lines.push(`| ${row.id} | ${row.appFeature} | ${row.status} | ${row.tested ? 'Y' : 'N'} | ${row.passed ? 'Y' : 'N'} |`);
  }
  lines.push(``);

  lines.push(`## Failures`);
  lines.push(``);
  const failed = summary.results.filter((x) => x.verdict === 'fail');
  if (failed.length === 0) {
    lines.push(`- none`);
  } else {
    for (const item of failed) {
      lines.push(`- [${item.layer}] ${item.scenarioId} (${item.capabilityId})`);
      for (const issue of item.issues) {
        lines.push(`  - (${issue.severity}/${issue.kind}) ${issue.message}`);
      }
    }
  }

  await writeFile(file, lines.join('\n'), 'utf8');
  return file;
}
