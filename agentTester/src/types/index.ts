export type RunLayer = 'engine' | 'rpc' | 'all';
export type RunSuite = 'smoke' | 'core' | 'full';
export type RunEnv = 'local-frpc';

export type FailureKind = 'protocol_failure' | 'state_machine_failure' | 'capability_gap' | 'model_flakiness' | 'environment_failure';

export type AssertionSeverity = 'strong' | 'semantic';

export type Verdict = 'pass' | 'fail' | 'skip';

export type TestTurnInput = {
  text: string;
  interaction?: Record<string, unknown>;
};

export type TestScenario = {
  id: string;
  capabilityId: string;
  title: string;
  level: 'critical' | 'normal';
  tags: string[];
  suite: RunSuite | 'all';
  turns: TestTurnInput[];
  expectedPhasePath?: string[];
  requiredDirectives?: string[];
  requiresProtocolV3Only?: boolean;
  semanticExpectations?: string[];
};

export type CapabilityManifestItem = {
  id: string;
  appFeature: string;
  status: 'connected' | 'not_connected' | 'planned';
  ownerRoute?: string;
  notes: string;
};

export type CapabilityMatrixRow = CapabilityManifestItem & {
  coveredByScenario: boolean;
  tested: boolean;
  passed: boolean;
};

export type AssertionIssue = {
  severity: AssertionSeverity;
  kind: FailureKind;
  message: string;
  hint?: string;
};

export type StepResult = {
  turnIndex: number;
  phase?: string;
  directives: string[];
  recommendedInput?: string;
  message?: string;
  issues: AssertionIssue[];
};

export type ScenarioResult = {
  layer: 'engine' | 'rpc';
  scenarioId: string;
  capabilityId: string;
  title: string;
  level: 'critical' | 'normal';
  verdict: Verdict;
  steps: StepResult[];
  issues: AssertionIssue[];
};

export type EnvironmentCheck = {
  ok: boolean;
  issues: AssertionIssue[];
  baseHttpUrl: string;
  wsUrl: string;
  authToken: string;
};

export type RunOptions = {
  layer: RunLayer;
  suite: RunSuite;
  env: RunEnv;
};

export type RunSummary = {
  options: RunOptions;
  startedAt: string;
  endedAt: string;
  protocolStrongPassRate: number;
  criticalPassRate: number;
  normalPassRate: number;
  gatePassed: boolean;
  totals: {
    scenarios: number;
    passed: number;
    failed: number;
    skipped: number;
  };
  results: ScenarioResult[];
  capabilityMatrix: CapabilityMatrixRow[];
  environment: EnvironmentCheck;
};
