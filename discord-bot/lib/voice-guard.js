import { getVoiceConnection } from '@discordjs/voice';
import { getLavalink } from './lavalink.js';

/** Drop Shoukaku/Lavalink voice (music) for this guild. */
export async function forceLeaveShoukaku(guildId) {
  const shoukaku = getLavalink();
  if (!shoukaku) return;
  const player = shoukaku.players.get(guildId);
  if (!player) return;
  await shoukaku.leaveVoiceChannel(guildId).catch(() => {});
}

/** Drop @discordjs/voice connection (VC AI / TTS). */
export function destroyDiscordVoice(guildId) {
  const conn = getVoiceConnection(guildId);
  if (!conn) return;
  try {
    conn.destroy();
  } catch {
    /* ignore */
  }
}

/** Music and VC AI cannot share voice — clear both before joining either mode. */
export async function forceClearAllVoice(guildId) {
  await forceLeaveShoukaku(guildId);
  destroyDiscordVoice(guildId);
}
