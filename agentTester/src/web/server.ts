import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { loadScenarios } from '../scenarios/scenarios.js';
import type { RunLayer, RunSuite } from '../types/index.js';
import { buildTestListView, listReports, readReportById } from './reportStore.js';
import { enqueueRun, getRunJob, listRunJobs } from './queue.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const publicDir = path.resolve(__dirname, 'public');

const port = Number(process.env.AGENT_TESTER_WEB_PORT ?? 8320);
const host = process.env.AGENT_TESTER_WEB_HOST ?? '0.0.0.0';
const password = process.env.AGENT_TESTER_WEB_PASSWORD ?? '123456';
const sessionTtlMs = Number(process.env.AGENT_TESTER_WEB_SESSION_TTL_MS ?? 1000 * 60 * 60 * 8);

const sessions = new Map<string, number>();

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);

    if (url.pathname === '/api/login' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const provided = typeof body.password === 'string' ? body.password : '';
      if (!provided || provided !== password) {
        return json(res, 401, { ok: false, message: '口令错误' });
      }
      const token = crypto.randomBytes(24).toString('hex');
      sessions.set(token, Date.now() + sessionTtlMs);
      setCookie(res, `agent_tester_session=${token}; HttpOnly; Path=/; Max-Age=${Math.floor(sessionTtlMs / 1000)}`);
      return json(res, 200, { ok: true });
    }

    if (url.pathname.startsWith('/api/')) {
      const authed = ensureAuthed(req);
      if (!authed.ok) {
        return json(res, 401, { ok: false, message: '未登录或会话过期' });
      }

      if (url.pathname === '/api/overview' && req.method === 'GET') {
        const scenarios = await loadScenarios();
        const tests = await buildTestListView(scenarios);
        const reports = await listReports();
        const latest = reports.sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0]?.summary ?? null;

        return json(res, 200, {
          ok: true,
          latest,
          stats: {
            totalScenarios: scenarios.length,
            pass: tests.filter((x) => x.latestStatus === 'pass').length,
            fail: tests.filter((x) => x.latestStatus === 'fail').length,
            never: tests.filter((x) => x.latestStatus === 'never').length
          }
        });
      }

      if (url.pathname === '/api/tests' && req.method === 'GET') {
        const scenarios = await loadScenarios();
        const tests = await buildTestListView(scenarios);
        return json(res, 200, { ok: true, items: tests });
      }

      if (url.pathname === '/api/run' && req.method === 'POST') {
        const body = await readJsonBody(req);
        const layer = normalizeLayer(body.layer);
        const suite = normalizeSuite(body.suite);
        const group = typeof body.group === 'string' ? body.group : undefined;
        const line = typeof body.line === 'string' ? body.line : undefined;
        const ids = Array.isArray(body.scenarioIds) ? body.scenarioIds.filter((x: unknown) => typeof x === 'string') : undefined;

        const scenarios = await loadScenarios();
        const scenarioIds = (ids && ids.length > 0)
          ? ids
          : scenarios
              .filter((x) => (group ? x.group === group : true) && (line ? x.line === line : true))
              .map((x) => x.id);

        const job = enqueueRun({ layer, suite, env: 'local-frpc', scenarioIds });
        return json(res, 200, { ok: true, job });
      }

      if (url.pathname.startsWith('/api/runs/') && req.method === 'GET') {
        const id = url.pathname.split('/').pop() ?? '';
        const job = getRunJob(id);
        if (!job) return json(res, 404, { ok: false, message: '任务不存在' });
        return json(res, 200, { ok: true, job });
      }

      if (url.pathname === '/api/runs' && req.method === 'GET') {
        return json(res, 200, { ok: true, items: listRunJobs(50) });
      }

      if (url.pathname === '/api/reports/latest' && req.method === 'GET') {
        const reports = await listReports();
        const latest = reports.sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0];
        if (!latest) return json(res, 404, { ok: false, message: '暂无报告' });
        return json(res, 200, { ok: true, id: latest.id, summary: latest.summary });
      }

      if (url.pathname.startsWith('/api/reports/') && req.method === 'GET') {
        const id = url.pathname.split('/').pop() ?? '';
        const summary = await readReportById(id);
        if (!summary) return json(res, 404, { ok: false, message: '报告不存在' });
        return json(res, 200, { ok: true, summary });
      }

      return json(res, 404, { ok: false, message: 'not found' });
    }

    if (url.pathname === '/' || url.pathname === '/index.html') {
      return sendFile(res, path.join(publicDir, 'index.html'), 'text/html; charset=utf-8');
    }

    if (url.pathname === '/app.js') {
      return sendFile(res, path.join(publicDir, 'app.js'), 'application/javascript; charset=utf-8');
    }

    if (url.pathname === '/styles.css') {
      return sendFile(res, path.join(publicDir, 'styles.css'), 'text/css; charset=utf-8');
    }

    json(res, 404, { ok: false, message: 'not found' });
  } catch (error) {
    json(res, 500, { ok: false, message: error instanceof Error ? error.message : String(error) });
  }
});

server.listen(port, host, () => {
  console.log(`[agentTester-web] listening on http://${host}:${port}`);
});

function normalizeLayer(value: unknown): RunLayer {
  if (value === 'engine' || value === 'rpc' || value === 'all') return value;
  return 'all';
}

function normalizeSuite(value: unknown): RunSuite {
  if (value === 'smoke' || value === 'core' || value === 'full') return value;
  return 'core';
}

function ensureAuthed(req: IncomingMessage): { ok: boolean } {
  const cookieHeader = req.headers.cookie ?? '';
  const cookieMap = new Map<string, string>();
  for (const pair of cookieHeader.split(';')) {
    const trimmed = pair.trim();
    if (!trimmed) continue;
    const idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();
    cookieMap.set(key, value);
  }
  const token = cookieMap.get('agent_tester_session');
  if (!token) return { ok: false };
  const expiredAt = sessions.get(token);
  if (!expiredAt) return { ok: false };
  if (Date.now() > expiredAt) {
    sessions.delete(token);
    return { ok: false };
  }
  return { ok: true };
}

function setCookie(res: ServerResponse, cookie: string): void {
  res.setHeader('Set-Cookie', cookie);
}

function json(res: ServerResponse, status: number, payload: unknown): void {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(payload));
}

async function sendFile(res: ServerResponse, filePath: string, contentType: string): Promise<void> {
  const content = await readFile(filePath);
  res.statusCode = 200;
  res.setHeader('Content-Type', contentType);
  res.end(content);
}

async function readJsonBody(req: IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  return JSON.parse(raw) as Record<string, unknown>;
}
