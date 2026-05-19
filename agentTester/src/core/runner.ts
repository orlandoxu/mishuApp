import { runEngineScenario } from '../adapters/engineAdapter.js';
import { runRpcScenario } from '../adapters/rpcAdapter.js';
import { assertProtocolV3Strict } from '../assertions/protocol.js';
import { assertSemanticContains } from '../assertions/semantic.js';
import { evaluateGate } from '../assertions/gates.js';
import { resolveEnv } from '../config/env.js';
import { capabilityManifest } from '../config/manifest.js';
import { scenarios } from '../scenarios/scenarios.js';
import type { CapabilityMatrixRow, RunOptions, RunSummary, ScenarioResult, TestScenario } from '../types/index.js';
import { checkEnvironment } from './environment.js';

export async function runAll(options: RunOptions): Promise<RunSummary> {
  const startedAt = new Date().toISOString();
  const env = resolveEnv(options.env);
  const environment = await checkEnvironment(env);

  const selectedScenarios = scenarios.filter((item) => item.suite === options.suite || item.suite === 'all' || options.suite === 'full');
  const layers = options.layer === 'all' ? (['engine', 'rpc'] as const) : ([options.layer] as const);

  const results: ScenarioResult[] = [];

  if (!environment.ok) {
    const endedAt = new Date().toISOString();
    const summary = buildSummary(options, startedAt, endedAt, [], environment);
    summary.gatePassed = false;
    return summary;
  }

  for (const scenario of selectedScenarios) {
    for (const layer of layers) {
      const base = layer === 'engine' ? await runEngineScenario(scenario) : await runRpcScenario(scenario, env);
      results.push(applyAssertions(base, scenario));
    }
  }

  const endedAt = new Date().toISOString();
  const summary = buildSummary(options, startedAt, endedAt, results, environment);
  appendCapabilityGapFailures(summary);
  const gate = evaluateGate(summary);
  summary.gatePassed = gate.ok;
  if (!gate.ok) {
    summary.results.push({
      layer: 'engine',
      scenarioId: 'gate-check',
      capabilityId: 'meta.gate',
      title: '发布门禁',
      level: 'critical',
      verdict: 'fail',
      steps: [],
      issues: gate.reasons.map((message) => ({ severity: 'strong', kind: 'protocol_failure', message }))
    });
    summary.totals.failed += 1;
    summary.totals.scenarios += 1;
  }
  return summary;
}

function applyAssertions(result: ScenarioResult, scenario: TestScenario): ScenarioResult {
  const issues = [...result.issues];
  const phasePath = result.steps.map((x) => x.phase).filter((x): x is string => Boolean(x));

  if (scenario.expectedPhasePath && scenario.expectedPhasePath.length > 0) {
    const ok = scenario.expectedPhasePath.every((phase, idx) => phasePath[idx] === phase);
    if (!ok) {
      issues.push({
        severity: 'strong',
        kind: 'state_machine_failure',
        message: `phase 路径不符合预期，expected=${scenario.expectedPhasePath.join('>')} actual=${phasePath.join('>')}`
      });
    }
  }

  for (const step of result.steps) {
    const protocolPayload = {
      protocol: {
        version: 'runtime',
        recommendedInput: step.recommendedInput,
        directives: step.directives.map((type) => ({ type }))
      }
    };
    const pIssues = assertProtocolV3Strict(protocolPayload);
    step.issues.push(...pIssues);
    issues.push(...pIssues);

    if (scenario.requiredDirectives) {
      for (const d of scenario.requiredDirectives) {
        if (!step.directives.includes(d)) {
          const miss = {
            severity: 'strong' as const,
            kind: 'protocol_failure' as const,
            message: `缺少必需 directive: ${d}`
          };
          step.issues.push(miss);
          issues.push(miss);
        }
      }
    }
  }

  if (scenario.semanticExpectations && scenario.semanticExpectations.length > 0) {
    const lastMessage = result.steps.at(-1)?.message;
    const semanticIssues = assertSemanticContains(lastMessage, scenario.semanticExpectations);
    issues.push(...semanticIssues);
    if (result.steps.length > 0) {
      result.steps[result.steps.length - 1].issues.push(...semanticIssues);
    }
  }

  const verdict = issues.length === 0 ? 'pass' : 'fail';
  return { ...result, verdict, issues };
}

function buildSummary(
  options: RunOptions,
  startedAt: string,
  endedAt: string,
  results: ScenarioResult[],
  environment: RunSummary['environment']
): RunSummary {
  const totals = {
    scenarios: results.length,
    passed: results.filter((x) => x.verdict === 'pass').length,
    failed: results.filter((x) => x.verdict === 'fail').length,
    skipped: results.filter((x) => x.verdict === 'skip').length
  };

  const strongAll = results.flatMap((x) => x.issues).filter((x) => x.severity === 'strong');
  const withStrongFailure = new Set(results.filter((x) => x.issues.some((issue) => issue.severity === 'strong')).map((x) => `${x.layer}:${x.scenarioId}`));
  const protocolStrongPassRate = results.length === 0 ? 0 : (results.length - withStrongFailure.size) / results.length;

  const critical = results.filter((x) => x.level === 'critical');
  const normal = results.filter((x) => x.level === 'normal');
  const criticalPassRate = critical.length === 0 ? 1 : critical.filter((x) => x.verdict === 'pass').length / critical.length;
  const normalPassRate = normal.length === 0 ? 1 : normal.filter((x) => x.verdict === 'pass').length / normal.length;

  const capabilityMatrix = buildCapabilityMatrix(results);

  return {
    options,
    startedAt,
    endedAt,
    protocolStrongPassRate,
    criticalPassRate,
    normalPassRate,
    gatePassed: false,
    totals,
    results,
    capabilityMatrix,
    environment
  };
}

function buildCapabilityMatrix(results: ScenarioResult[]): CapabilityMatrixRow[] {
  const resultMap = new Map<string, ScenarioResult[]>();
  for (const result of results) {
    const rows = resultMap.get(result.capabilityId) ?? [];
    rows.push(result);
    resultMap.set(result.capabilityId, rows);
  }

  return capabilityManifest.map((item) => {
    const rows = resultMap.get(item.id) ?? [];
    const tested = rows.length > 0;
    const passed = tested && rows.every((x) => x.verdict === 'pass');
    const coveredByScenario = scenarios.some((x) => x.capabilityId === item.id);

    if (item.status !== 'connected') {
      return { ...item, coveredByScenario, tested, passed: false };
    }

    return { ...item, coveredByScenario, tested, passed };
  });
}

function appendCapabilityGapFailures(summary: RunSummary): void {
  const gaps = summary.capabilityMatrix.filter((row) => row.status !== 'connected');
  for (const row of gaps) {
    summary.results.push({
      layer: 'engine',
      scenarioId: `capability-gap-${row.id}`,
      capabilityId: row.id,
      title: `${row.appFeature} 未接入 Agent`,
      level: 'critical',
      verdict: 'fail',
      steps: [],
      issues: [
        {
          severity: 'strong',
          kind: 'capability_gap',
          message: `功能缺口：${row.appFeature} 当前状态=${row.status}，未接入 Agent 测试链路。`
        }
      ]
    });
    summary.totals.scenarios += 1;
    summary.totals.failed += 1;
  }
}
