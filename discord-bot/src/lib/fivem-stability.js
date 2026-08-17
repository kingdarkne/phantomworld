/**
 * Phantom World FiveM stability score (0–100) + factor list + remediation.
 */
const { getPhantomStatus } = require('../../aio-bridge/fivem-status');
const store = require('./stability-store');

function fivemBase() {
  return (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
}

function apiToken() {
  return process.env.FIVEM_API_TOKEN || process.env.BOT_RELAY_SECRET || '';
}

async function probeJson(url, { auth = false, timeoutMs = 8000 } = {}) {
  const headers = {};
  if (auth) {
    const token = apiToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }
  const started = Date.now();
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(timeoutMs) });
  const ms = Date.now() - started;
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text.slice(0, 200) };
  }
  return { ok: res.ok, status: res.status, ms, json };
}

async function probeBotHealth() {
  const port = process.env.BOT_HTTP_PORT || process.env.PORT || 3099;
  const hosts = ['http://127.0.0.1', `http://${process.env.SERVER_IP || '172.245.71.46'}`];
  for (const host of hosts) {
    try {
      const r = await probeJson(`${host}:${port}/health`, { timeoutMs: 4000 });
      if (r.ok) return { ok: true, ms: r.ms, body: r.json };
    } catch {
      // try next
    }
  }
  return { ok: false };
}

/**
 * @returns {Promise<{
 *   score: number,
 *   grade: string,
 *   online: boolean,
 *   status: object,
 *   factors: Array<{ id: string, label: string, ok: boolean, penalty: number, detail: string, fixable?: boolean }>,
 *   blockers: string[],
 *   actions: Array<{ id: string, label: string, risk: string }>
 * }>}
 */
async function computeStability() {
  const factors = [];
  let score = 100;
  const base = fivemBase();

  let info = null;
  let players = null;
  let dynamic = null;
  let online = false;

  try {
    info = await probeJson(`${base}/info.json`);
    online = info.ok;
    if (!info.ok) {
      factors.push({
        id: 'fx_info',
        label: 'FXServer info.json',
        ok: false,
        penalty: 35,
        detail: `Unreachable (${info.status})`,
        fixable: true,
      });
      score -= 35;
    } else {
      factors.push({
        id: 'fx_info',
        label: 'FXServer info.json',
        ok: true,
        penalty: 0,
        detail: `OK in ${info.ms}ms`,
      });
      if (info.ms > 2500) {
        factors.push({
          id: 'fx_latency',
          label: 'FX HTTP latency',
          ok: false,
          penalty: 5,
          detail: `Slow response ${info.ms}ms`,
        });
        score -= 5;
      }
    }
  } catch (err) {
    online = false;
    factors.push({
      id: 'fx_info',
      label: 'FXServer info.json',
      ok: false,
      penalty: 40,
      detail: err.message,
      fixable: true,
    });
    score -= 40;
  }

  try {
    players = await probeJson(`${base}/players.json`);
    if (!players.ok) {
      factors.push({
        id: 'fx_players',
        label: 'players.json',
        ok: false,
        penalty: 8,
        detail: `HTTP ${players.status}`,
        fixable: true,
      });
      score -= 8;
    } else {
      const count = Array.isArray(players.json) ? players.json.length : 0;
      factors.push({
        id: 'fx_players',
        label: 'players.json',
        ok: true,
        penalty: 0,
        detail: `${count} online`,
      });
    }
  } catch (err) {
    factors.push({
      id: 'fx_players',
      label: 'players.json',
      ok: false,
      penalty: 8,
      detail: err.message,
      fixable: true,
    });
    score -= 8;
  }

  try {
    dynamic = await probeJson(`${base}/dynamic.json`);
    if (dynamic.ok) {
      factors.push({
        id: 'fx_dynamic',
        label: 'dynamic.json',
        ok: true,
        penalty: 0,
        detail: `${dynamic.json?.hostname || 'ok'} · ${dynamic.json?.clients ?? '?'}/${dynamic.json?.sv_maxclients || '?'}`,
      });
    }
  } catch {
    // optional
  }

  // Dashboard HTTP — screencapture owns SetHttpHandler and mounts routes under
  // /screencapture/phantom-dashboard/* (also try unprefixed / legacy paths).
  const dashPaths = [
    '/screencapture/phantom-dashboard/status',
    '/phantom-dashboard/status',
    '/screenshot-basic/phantom-dashboard/status',
  ];
  let dashOk = null;
  let dashFailDetail = 'unreachable';
  for (const path of dashPaths) {
    try {
      const dash = await probeJson(`${base}${path}`, { auth: true, timeoutMs: 5000 });
      if (dash.ok && dash.json && !dash.json.error && dash.json.serverName) {
        dashOk = { path, ms: dash.ms };
        break;
      }
      dashFailDetail = dash.ok
        ? `Unexpected body from ${path}`
        : `HTTP ${dash.status} at ${path}`;
    } catch (err) {
      dashFailDetail = `${path}: ${err.message}`;
    }
  }
  if (dashOk) {
    factors.push({
      id: 'dashboard',
      label: 'phantom_dashboard HTTP',
      ok: true,
      penalty: 0,
      detail: `OK via ${dashOk.path} (${dashOk.ms}ms)`,
    });
  } else {
    factors.push({
      id: 'dashboard',
      label: 'phantom_dashboard HTTP',
      ok: false,
      penalty: 6,
      detail: dashFailDetail,
      fixable: true,
    });
    score -= 6;
  }

  // CFX listing
  let status = null;
  try {
    status = await getPhantomStatus();
    factors.push({
      id: 'cfx',
      label: 'CFX master listing',
      ok: true,
      penalty: 0,
      detail: `${status.serverName} · ${status.playerCount}/${status.maxPlayers} (${status.source})`,
    });
  } catch (err) {
    factors.push({
      id: 'cfx',
      label: 'CFX master listing',
      ok: false,
      penalty: 8,
      detail: err.message,
    });
    score -= 8;
  }

  // Bot relay health
  const bot = await probeBotHealth();
  if (bot.ok) {
    factors.push({
      id: 'bot_relay',
      label: 'Rex bot HTTP relay',
      ok: true,
      penalty: 0,
      detail: `healthy (${bot.ms}ms)`,
    });
  } else {
    factors.push({
      id: 'bot_relay',
      label: 'Rex bot HTTP relay',
      ok: false,
      penalty: 5,
      detail: 'Bot /health failed',
      fixable: true,
    });
    score -= 5;
  }

  // Recent error / stuck / restart window
  const hour = store.countByCategory(60 * 60 * 1000);
  const errors = (hour.error || 0) + (hour.critical || 0);
  const stuck = hour.stuck || 0;
  const restarts = (hour.scheduled_restart || 0) + (hour.restart || 0) + (hour.lifecycle || 0);

  if (errors === 0) {
    factors.push({
      id: 'errors_1h',
      label: 'Script errors (1h)',
      ok: true,
      penalty: 0,
      detail: 'No error/critical relays in the last hour',
    });
  } else {
    const penalty = Math.min(25, 5 + errors * 4);
    factors.push({
      id: 'errors_1h',
      label: 'Script errors (1h)',
      ok: false,
      penalty,
      detail: `${errors} error/critical event(s) relayed to Rex`,
      fixable: true,
    });
    score -= penalty;
  }

  if (stuck === 0) {
    factors.push({
      id: 'stuck_1h',
      label: 'Stuck reports (1h)',
      ok: true,
      penalty: 0,
      detail: 'No stuck reports in the last hour',
    });
  } else {
    const penalty = Math.min(15, stuck * 5);
    factors.push({
      id: 'stuck_1h',
      label: 'Stuck reports (1h)',
      ok: false,
      penalty,
      detail: `${stuck} stuck report(s) — players may need /unstuck or staff help`,
      fixable: true,
    });
    score -= penalty;
  }

  if (restarts > 0) {
    const penalty = Math.min(8, restarts * 3);
    factors.push({
      id: 'restarts_1h',
      label: 'Restarts / lifecycle (1h)',
      ok: false,
      penalty,
      detail: `${restarts} restart/lifecycle event(s) — brief instability expected after restarts`,
    });
    score -= penalty;
  } else {
    factors.push({
      id: 'restarts_1h',
      label: 'Restarts / lifecycle (1h)',
      ok: true,
      penalty: 0,
      detail: 'No restart churn in the last hour',
    });
  }

  score = Math.max(0, Math.min(100, Math.round(score)));

  const blockers = factors
    .filter((f) => !f.ok && f.penalty > 0)
    .sort((a, b) => b.penalty - a.penalty)
    .map((f) => `−${f.penalty}% ${f.label}: ${f.detail}`);

  const actions = [];
  if (!online) {
    actions.push({
      id: 'restart_fx',
      label: 'Restart FXServer via Wings (only if empty / confirmed)',
      risk: 'high',
    });
  }
  if (factors.some((f) => f.id === 'dashboard' && !f.ok)) {
    actions.push({
      id: 'ensure_dashboard',
      label: 'ensure phantom_dashboard (reload Discord bridge + stuck detector)',
      risk: 'low',
    });
  }
  if (stuck > 0) {
    actions.push({
      id: 'clear_stuck_window',
      label: 'Acknowledge stuck window (score recovers as reports age out)',
      risk: 'none',
    });
  }
  if (errors > 0) {
    actions.push({
      id: 'review_errors',
      label: 'Review recent script errors in Rex Alerts / mod-log',
      risk: 'none',
    });
  }
  if (bot.ok === false) {
    actions.push({
      id: 'restart_bot',
      label: 'Restart Rex container so /events relay is healthy',
      risk: 'medium',
    });
  }

  const grade =
    score >= 95 ? 'Excellent' : score >= 85 ? 'Good' : score >= 70 ? 'Fair' : score >= 50 ? 'Poor' : 'Critical';

  return {
    score,
    grade,
    online,
    status: status || {
      serverName: 'Phantom World',
      playerCount: Array.isArray(players?.json) ? players.json.length : 0,
      maxPlayers: 48,
    },
    factors,
    blockers,
    actions,
    recent: store.recentEvents({ sinceMs: 60 * 60 * 1000 }).slice(-12),
  };
}

async function attemptRemediation(client, { allowRestart = false } = {}) {
  const before = await computeStability();
  const applied = [];
  const notes = [];

  // Soft wait + re-probe (helps flapping)
  await new Promise((r) => setTimeout(r, 1500));
  applied.push('reprobe');

  // If FX is online but dashboard HTTP is dead, try a lightweight ensure via
  // the host helper script when available (optional; never blocks).
  const dashBad = before.factors.some((f) => f.id === 'dashboard' && !f.ok);
  if (dashBad && process.env.STABILITY_ENSURE_CMD) {
    try {
      const { execFile } = require('child_process');
      await new Promise((resolve) => {
        execFile(
          'bash',
          ['-lc', process.env.STABILITY_ENSURE_CMD],
          { timeout: 20000 },
          (err, stdout, stderr) => {
            applied.push('ensure_dashboard');
            notes.push(
              err
                ? `ensure failed: ${err.message}`
                : `ensure: ${(stdout || stderr || 'ok').toString().slice(0, 160)}`,
            );
            resolve();
          },
        );
      });
      await new Promise((r) => setTimeout(r, 4000));
    } catch (err) {
      notes.push(`ensure skipped: ${err.message}`);
    }
  } else if (dashBad) {
    notes.push(
      'Dashboard HTTP failed — ensure screencapture is running (it proxies /screencapture/phantom-dashboard/*)',
    );
  }

  if (!before.online && allowRestart) {
    const players = before.status?.playerCount ?? 0;
    if (players > 0) {
      notes.push(`Skipped FX restart — ${players} player(s) online`);
    } else {
      try {
        const port = process.env.BOT_HTTP_PORT || 3099;
        const secret = process.env.BOT_RELAY_SECRET || process.env.FIVEM_API_TOKEN || '';
        const res = await fetch(`http://127.0.0.1:${port}/server/restart`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${secret}`,
          },
          body: JSON.stringify({ reason: 'stability_fix_offline', force: true }),
          signal: AbortSignal.timeout(15000),
        });
        const body = await res.json().catch(() => ({}));
        applied.push('restart_fx');
        notes.push(`FX restart requested: HTTP ${res.status} ${JSON.stringify(body).slice(0, 120)}`);
        await new Promise((r) => setTimeout(r, 20000));
      } catch (err) {
        notes.push(`FX restart failed: ${err.message}`);
      }
    }
  }

  const after = await computeStability();

  if (after.score > before.score) {
    notes.push(`Score improved ${before.score}% → ${after.score}%`);
  } else if (after.score === before.score) {
    notes.push(`Score unchanged at ${after.score}% — remaining blockers need manual fixes`);
  } else {
    notes.push(`Score ${before.score}% → ${after.score}% after remediation attempt`);
  }

  return { before, after, applied, notes };
}

module.exports = {
  computeStability,
  attemptRemediation,
};
