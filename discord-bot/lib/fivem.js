import { EmbedBuilder } from 'discord.js';

const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
const apiToken = process.env.FIVEM_API_TOKEN || '';
const cfxServerId = process.env.CFX_SERVER_ID || '';

export async function fetchFivem(path) {
  const headers = {};
  if (apiToken) headers.Authorization = `Bearer ${apiToken}`;
  const res = await fetch(`${fivemUrl}${path}`, { headers, signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export async function fetchCfxListing() {
  if (!cfxServerId) return null;
  const res = await fetch(`https://servers-frontend.fivem.net/api/servers/single/${cfxServerId}`, {
    signal: AbortSignal.timeout(8000),
  });
  if (!res.ok) return null;
  const data = await res.json();
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

export async function getStatus() {
  const cfx = await fetchCfxListing();

  let fivem = null;
  try {
    fivem = await fetchFivem('/phantom-dashboard/status');
    fivem.source = 'fivem';
  } catch (err) {
    console.warn('FiveM HTTP failed:', err.message);
  }

  if (fivem) {
    const merged = {
      ...cfx,
      ...fivem,
      serverName: fivem.serverName || cfx?.serverName,
      playerCount: fivem.playerCount ?? cfx?.playerCount ?? 0,
      maxPlayers: fivem.maxPlayers ?? cfx?.maxPlayers ?? 48,
      uptimeSeconds: fivem.uptimeSeconds ?? cfx?.uptimeSeconds ?? null,
      mapName: cfx?.mapName || null,
      gameType: cfx?.gameType || null,
    };

    if ((merged.playerCount ?? 0) > 0) {
      try {
        const playerData = await fetchFivem('/phantom-dashboard/players');
        const names = (playerData.players || []).map((p) => p.name).filter(Boolean).slice(0, 8);
        if (names.length > 0) {
          merged.topPlayers = names;
        }
      } catch {
        merged.topPlayers = merged.topPlayers || cfx?.topPlayers || [];
      }
    } else {
      merged.topPlayers = [];
    }

    return merged;
  }

  if (cfx) return cfx;
  throw new Error('No status source (FiveM HTTP and CFX listing both failed)');
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
