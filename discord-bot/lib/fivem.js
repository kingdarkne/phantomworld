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

export async function fetchCfxFallback() {
  if (!cfxServerId) return null;
  const res = await fetch(`https://servers-frontend.fivem.net/api/servers/single/${cfxServerId}`, {
    signal: AbortSignal.timeout(8000),
  });
  if (!res.ok) return null;
  const data = await res.json();
  const d = data?.Data;
  if (!d) return null;
  return {
    serverName: d.hostname || 'Phantom World',
    playerCount: d.clients ?? 0,
    maxPlayers: d.sv_maxclients ?? 48,
    serverTime: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    source: 'cfx',
  };
}

export async function getStatus() {
  try {
    const status = await fetchFivem('/phantom-dashboard/status');
    return { ...status, source: 'fivem' };
  } catch (err) {
    console.warn('FiveM HTTP failed:', err.message);
    const fallback = await fetchCfxFallback();
    if (fallback) return fallback;
    throw err;
  }
}

export async function getPlayers() {
  try {
    const data = await fetchFivem('/phantom-dashboard/players');
    return data.players || [];
  } catch {
    return [];
  }
}

export function buildStatusEmbed(status) {
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle('Phantom World — Server Status')
    .addFields(
      { name: 'Server', value: status.serverName || 'Unknown', inline: true },
      { name: 'Players', value: `${status.playerCount ?? '?'}/${status.maxPlayers ?? '?'}`, inline: true },
      { name: 'Time', value: status.serverTime || '—', inline: true },
    )
    .setFooter({ text: `Source: ${status.source || 'fivem'}` })
    .setTimestamp();
}
