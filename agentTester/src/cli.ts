#!/usr/bin/env node
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { runAll } from './core/runner.js';
import { writeJsonReport } from './reporters/jsonReporter.js';
import { writeMarkdownReport } from './reporters/markdownReporter.js';
import type { RunEnv, RunLayer, RunOptions, RunSuite } from './types/index.js';

async function main(): Promise<void> {
  const [cmd = 'run', ...rest] = process.argv.slice(2);

  if (cmd === 'run') {
    const opts = parseRunOptions(rest);
    const summary = await runAll(opts);
    const jsonPath = await writeJsonReport(summary);
    const mdPath = await writeMarkdownReport(summary);

    console.log(`[agentTester] json report: ${jsonPath}`);
    console.log(`[agentTester] md report: ${mdPath}`);
    console.log(`[agentTester] gate passed: ${summary.gatePassed}`);

    if (!summary.gatePassed) {
      process.exitCode = 1;
    }
    return;
  }

  if (cmd === 'report') {
    const formatArg = rest.find((x) => x.startsWith('--format=')) ?? '--format=md';
    const format = formatArg.split('=')[1];
    const report = await readLatestJsonReport();
    if (format === 'json') {
      console.log(JSON.stringify(report, null, 2));
    } else {
      console.log(`# latest report`);
      console.log(`gatePassed: ${report.gatePassed}`);
      console.log(`totals: ${report.totals.passed} pass / ${report.totals.failed} fail / ${report.totals.skipped} skip`);
      console.log(`protocolStrongPassRate: ${(report.protocolStrongPassRate * 100).toFixed(2)}%`);
      console.log(`criticalPassRate: ${(report.criticalPassRate * 100).toFixed(2)}%`);
      console.log(`normalPassRate: ${(report.normalPassRate * 100).toFixed(2)}%`);
    }
    return;
  }

  throw new Error(`unknown command: ${cmd}`);
}

async function readLatestJsonReport(): Promise<Record<string, any>> {
  const dir = path.resolve(process.cwd(), 'reports');
  const files = (await readdir(dir)).filter((x) => x.endsWith('.json')).sort();
  if (files.length === 0) throw new Error('no json report found in reports/');
  const latest = files[files.length - 1];
  const raw = await readFile(path.join(dir, latest), 'utf8');
  return JSON.parse(raw) as Record<string, any>;
}

function parseRunOptions(args: string[]): RunOptions {
  const options: RunOptions = {
    layer: 'all',
    suite: 'smoke',
    env: 'local-frpc'
  };

  for (const arg of args) {
    if (arg.startsWith('--layer=')) options.layer = arg.split('=')[1] as RunLayer;
    if (arg.startsWith('--suite=')) options.suite = arg.split('=')[1] as RunSuite;
    if (arg.startsWith('--env=')) options.env = arg.split('=')[1] as RunEnv;
    if (arg.startsWith('--scenarioIds=')) {
      const value = arg.split('=')[1] ?? '';
      options.scenarioIds = value.split(',').map((x) => x.trim()).filter(Boolean);
    }
  }

  if (!['engine', 'rpc', 'all'].includes(options.layer)) throw new Error(`invalid layer=${options.layer}`);
  if (!['smoke', 'core', 'full'].includes(options.suite)) throw new Error(`invalid suite=${options.suite}`);
  if (!['local-frpc'].includes(options.env)) throw new Error(`invalid env=${options.env}`);
  return options;
}

main().catch((error) => {
  console.error('[agentTester] failed', error);
  process.exit(1);
});
