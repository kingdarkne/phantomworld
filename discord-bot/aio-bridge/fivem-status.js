/**
 * Minimal FiveM / CFX status for AIO bridge (CommonJS).
 */
const CFX_BASES = [
  'https://frontend.cfx-services.net/api/servers/single',
  'https://servers-frontend.fivem.net/api/servers/single',
];

function fivemBase() {
  return (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
}

function apiToken() {
  return process.env.FIVEM_API_TOKEN || process.env.BOT_RELAY_SECRET || '';
}

async function fetchCfx(serverId) {
  if (!serverId) return null;
  for (const base of CFX_BASES) {
    try {
      const res = await fetch(`${base}/${serverId}`, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) continue;
      const data = await res.json();
      const d = data?.Data;
      if (!d) continue;
      return {
        serverName: d.hostname || 'Phantom World',
        playerCount: d.clients ?? 0,
        maxPlayers: d.sv_maxclients ?? 48,
        source: 'cfx',
      };
    } catch {
      // try next base
    }
  }
  return null;
}

async function fetchPublicJson() {
  const base = fivemBase();
  const headers = {};
  const token = apiToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const infoRes = await fetch(`${base}/info.json`, { headers, signal: AbortSignal.timeout(8000) });
  if (!infoRes.ok) throw new Error(`info.json HTTP ${infoRes.status}`);
  const info = await infoRes.json();
  const vars = info.vars || {};
  const maxPlayers = Number(vars.sv_maxclients || vars.sv_maxClients) || 48;

  let playerCount = 0;
  try {
    const playersRes = await fetch(`${base}/players.json`, { headers, signal: AbortSignal.timeout(8000) });
    if (playersRes.ok) {
      const players = await playersRes.json();
      playerCount = Array.isArray(players) ? players.length : 0;
    }
  } catch {
    // ignore
  }

  return {
    serverName: vars.sv_projectName || vars.sv_hostname || 'Phantom World',
    playerCount,
    maxPlayers,
    source: 'fivem-public',
  };
}

async function getPhantomStatus() {
  const cfx = await fetchCfx(process.env.CFX_SERVER_ID || '');
  try {
    const pub = await fetchPublicJson();
    return { ...pub, ...cfx, playerCount: pub.playerCount ?? cfx?.playerCount ?? 0 };
  } catch {
    if (cfx) return cfx;
    throw new Error('FiveM and CFX status both failed');
  }
}

module.exports = { getPhantomStatus };
