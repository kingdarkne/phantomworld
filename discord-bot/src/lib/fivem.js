import { EmbedBuilder } from 'discord.js';

function fivemBaseUrl() {
  return (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
}

function apiToken() {
  return process.env.FIVEM_API_TOKEN || '';
}

function cfxServerId() {
  return process.env.CFX_SERVER_ID || '';
}

export async function fetchFivem(path) {
  const headers = {};
  const token = apiToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${fivemBaseUrl()}${path}`, { headers, signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

const CFX_API_BASES = [
  'https://frontend.cfx-services.net/api/servers/single',
  'https://servers-frontend.fivem.net/api/servers/single',
];

function parseCfxPayload(data) {
  const d = data?.Data;
  if (!d) return null;

  const topPlayers = (d.players || [])
    .map((p) => p.name)
    .filter(Boolean)
    .slice(0, 8);

  return {
    serverName: d.hostname || 'Phantom World',
    playerCount: d.clients ?? 0,
    maxPlayers: d.sv_maxclients ?? 48,
    serverTime: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    mapName: d.mapname || null,
    gameType: d.gametype || null,
    uptimeSeconds: d.uptime != null ? Number(d.uptime) : null,
    topPlayers,
    source: 'cfx',
  };
}

export async function fetchCfxListing() {
  const serverId = cfxServerId();
  if (!serverId) return null;

  for (const base of CFX_API_BASES) {
    try {
      const res = await fetch(`${base}/${serverId}`, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) continue;
      const parsed = parseCfxPayload(await res.json());
      if (parsed) return parsed;
    } catch (err) {
      console.warn(`CFX listing failed (${base}):`, err.message);
    }
  }

  return null;
}

export async function fetchFivemPublic() {
  const headers = {};
  const token = apiToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  const base = fivemBaseUrl();

  const infoRes = await fetch(`${base}/info.json`, {
    headers,
    signal: AbortSignal.timeout(8000),
  });
  if (!infoRes.ok) throw new Error(`info.json HTTP ${infoRes.status}`);

  const playersRes = await fetch(`${base}/players.json`, {
    headers,
    signal: AbortSignal.timeout(8000),
  });
  if (!playersRes.ok) throw new Error(`players.json HTTP ${playersRes.status}`);

  const info = await infoRes.json();
  const players = await playersRes.json();
  const vars = info.vars || {};
  const maxPlayers =
    Number(vars.sv_maxclients || vars.sv_maxClients || vars.SV_MAXCLIENTS) || 48;

  const topPlayers = (Array.isArray(players) ? players : [])
    .map((p) => p.name)
    .filter(Boolean)
    .slice(0, 8);

  return {
    serverName: vars.sv_projectName || vars.sv_hostname || 'Phantom World',
    playerCount: topPlayers.length,
    maxPlayers,
    serverTime: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    mapName: info.mapname || vars.mapname || null,
    gameType: info.gametype || vars.gametype || null,
    topPlayers,
    source: 'fivem-public',
  };
}

function mergeStatus(primary, secondary) {
  if (!primary) return secondary;
  if (!secondary) return primary;

  return {
    ...secondary,
    ...primary,
    serverName: primary.serverName || secondary.serverName,
    playerCount: primary.playerCount ?? secondary.playerCount ?? 0,
    maxPlayers: primary.maxPlayers ?? secondary.maxPlayers ?? 48,
    uptimeSeconds: primary.uptimeSeconds ?? secondary.uptimeSeconds ?? null,
    mapName: primary.mapName || secondary.mapName || null,
    gameType: primary.gameType || secondary.gameType || null,
    topPlayers:
      (primary.topPlayers?.length ? primary.topPlayers : secondary.topPlayers) || [],
    source: primary.source || secondary.source,
  };
}

export async function getStatus() {
  const cfx = await fetchCfxListing();

  let dashboard = null;
  try {
    dashboard = await fetchFivem('/phantom-dashboard/status');
    dashboard.source = 'fivem-dashboard';
  } catch (err) {
    console.warn('FiveM dashboard HTTP failed:', err.message);
  }

  let publicData = null;
  try {
    publicData = await fetchFivemPublic();
  } catch (err) {
    console.warn('FiveM public JSON failed:', err.message);
  }

  let merged = mergeStatus(publicData, cfx);
  merged = mergeStatus(dashboard, merged);

  if (dashboard && (merged.playerCount ?? 0) > 0) {
    try {
      const playerData = await fetchFivem('/phantom-dashboard/players');
      const names = (playerData.players || []).map((p) => p.name).filter(Boolean).slice(0, 8);
      if (names.length > 0) merged.topPlayers = names;
    } catch {
      // players.json / CFX list already applied
    }
  }

  if (merged) return merged;
  throw new Error('No status source (FiveM and CFX listing both failed)');
}

export async function getPlayers() {
  try {
    const data = await fetchFivem('/phantom-dashboard/players');
    return data.players || [];
  } catch {
    return [];
  }
}

function formatUptimeEmbed(seconds) {
  if (!seconds || seconds < 0) return '—';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

export function buildStatusEmbed(status) {
  const embed = new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle('Phantom World — Server Status')
    .addFields(
      { name: 'Server', value: status.serverName || 'Unknown', inline: true },
      { name: 'Players', value: `${status.playerCount ?? '?'}/${status.maxPlayers ?? '?'}`, inline: true },
      { name: 'Time', value: status.serverTime || '—', inline: true },
    );

  if (status.mapName) {
    embed.addFields({ name: 'Map', value: status.mapName, inline: true });
  }
  if (status.gameType) {
    embed.addFields({ name: 'Mode', value: status.gameType, inline: true });
  }
  if (status.uptimeSeconds) {
    embed.addFields({ name: 'Uptime', value: formatUptimeEmbed(status.uptimeSeconds), inline: true });
  }
  if (status.topPlayers?.length) {
    embed.addFields({
      name: 'Online now',
      value: status.topPlayers.slice(0, 10).join('\n').slice(0, 1024),
    });
  }

  embed.setFooter({ text: `Source: ${status.source || 'fivem'}` }).setTimestamp();
  return embed;
}
