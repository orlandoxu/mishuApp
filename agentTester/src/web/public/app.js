const authBox = document.getElementById('authBox');
const metricsEl = document.getElementById('metrics');
const testListEl = document.getElementById('testList');
const runStatusEl = document.getElementById('runStatus');
const runBtn = document.getElementById('runBtn');

const groupSelect = document.getElementById('groupSelect');
const lineSelect = document.getElementById('lineSelect');
const layerSelect = document.getElementById('layerSelect');
const suiteSelect = document.getElementById('suiteSelect');

let pollTimer = null;

boot();

async function boot() {
  renderLogin();
  const ok = await tryLoad();
  if (ok) renderAuthed();
}

function renderLogin() {
  authBox.innerHTML = `
    <input id="pwd" type="password" placeholder="输入口令" />
    <button id="loginBtn">登录</button>
  `;
  document.getElementById('loginBtn').onclick = async () => {
    const password = document.getElementById('pwd').value;
    const resp = await fetch('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ password }) });
    if (!resp.ok) {
      alert('口令错误');
      return;
    }
    renderAuthed();
    await loadDashboard();
  };
}

function renderAuthed() {
  authBox.innerHTML = '<span class="meta">已登录</span>';
}

async function tryLoad() {
  const resp = await fetch('/api/overview');
  if (resp.status === 401) return false;
  if (!resp.ok) return false;
  await loadDashboard();
  return true;
}

async function loadDashboard() {
  const [overviewResp, testsResp, runsResp] = await Promise.all([
    fetch('/api/overview'),
    fetch('/api/tests'),
    fetch('/api/runs')
  ]);
  if (!overviewResp.ok || !testsResp.ok || !runsResp.ok) return;

  const overview = await overviewResp.json();
  const tests = await testsResp.json();
  const runs = await runsResp.json();

  renderMetrics(overview);
  renderTests(tests.items || []);
  renderRunStatus(runs.items || []);
}

function renderMetrics(overview) {
  const latest = overview.latest;
  metricsEl.innerHTML = `
    <div class="metrics-grid">
      <div class="metric"><div class="k">门禁状态</div><div class="v">${latest ? (latest.gatePassed ? 'PASS' : 'FAIL') : 'N/A'}</div></div>
      <div class="metric"><div class="k">总测试项</div><div class="v">${overview.stats.totalScenarios}</div></div>
      <div class="metric"><div class="k">通过</div><div class="v">${overview.stats.pass}</div></div>
      <div class="metric"><div class="k">失败</div><div class="v">${overview.stats.fail}</div></div>
      <div class="metric"><div class="k">未运行</div><div class="v">${overview.stats.never}</div></div>
      <div class="metric"><div class="k">协议强断言</div><div class="v">${latest ? ((latest.protocolStrongPassRate*100).toFixed(1)+'%') : 'N/A'}</div></div>
    </div>
  `;
}

function renderTests(items) {
  const group = groupSelect.value;
  const line = lineSelect.value;
  const filtered = items.filter((x) => (!group || x.scenario.group === group) && (!line || x.scenario.line === line));

  testListEl.innerHTML = filtered.map((item, idx) => {
    const reason = item.latestFailReason || '-';
    const state = item.latestStatus;
    return `
      <div class="item">
        <div class="item-head">
          <div><span class="badge ${state}">${state.toUpperCase()}</span></div>
          <div>
            <div class="title">${item.scenario.title}</div>
            <div class="meta">${item.scenario.group} / ${item.scenario.line} / ${item.scenario.id}</div>
          </div>
          <div>
            <div class="reason">${escapeHtml(reason)}</div>
            <div class="meta">最后运行：${item.latestRunAt || '未运行'}</div>
          </div>
          <div><span class="expand" data-idx="${idx}">展开详情</span></div>
        </div>
        <div class="detail" id="detail-${idx}">
          <pre>${escapeHtml(JSON.stringify(item, null, 2))}</pre>
        </div>
      </div>
    `;
  }).join('');

  document.querySelectorAll('.expand').forEach((el) => {
    el.onclick = () => {
      const idx = el.getAttribute('data-idx');
      const box = document.getElementById(`detail-${idx}`);
      const open = box.style.display === 'block';
      box.style.display = open ? 'none' : 'block';
      el.textContent = open ? '展开详情' : '收起详情';
    };
  });
}

function renderRunStatus(items) {
  const running = items.find((x) => x.status === 'running');
  if (running) {
    runStatusEl.textContent = `当前运行中：${running.id} (${running.payload.layer}/${running.payload.suite})`;
  } else {
    runStatusEl.textContent = '当前无运行任务';
  }
}

runBtn.onclick = async () => {
  runBtn.disabled = true;
  try {
    const body = {
      group: groupSelect.value || undefined,
      line: lineSelect.value || undefined,
      layer: layerSelect.value,
      suite: suiteSelect.value
    };
    const resp = await fetch('/api/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!resp.ok) {
      const e = await resp.json();
      alert(e.message || '运行失败');
      return;
    }
    const data = await resp.json();
    const jobId = data.job.id;
    runStatusEl.textContent = `任务已创建：${jobId}`;
    startPolling(jobId);
  } finally {
    runBtn.disabled = false;
  }
};

groupSelect.onchange = () => loadDashboard();
lineSelect.onchange = () => loadDashboard();

function startPolling(jobId) {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(async () => {
    const resp = await fetch(`/api/runs/${jobId}`);
    if (!resp.ok) return;
    const data = await resp.json();
    const job = data.job;
    runStatusEl.textContent = `任务 ${job.id}: ${job.status}`;

    if (job.status === 'done' || job.status === 'failed') {
      clearInterval(pollTimer);
      await loadDashboard();
    }
  }, 2000);
}

function escapeHtml(str) {
  return String(str)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
