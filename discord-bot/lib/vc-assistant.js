import {
  joinVoiceChannel,
  getVoiceConnection,
  createAudioPlayer,
  AudioPlayerStatus,
  EndBehaviorType,
  entersState,
  VoiceConnectionStatus,
  NoSubscriberBehavior,
} from '@discordjs/voice';
import prism from 'prism-media';
import { EmbedBuilder } from 'discord.js';
import { PERSONAS, getPersona } from './personas.js';
import { chatReply, transcribeWav, aiConfigured } from './ai.js';
import { textToSpeechResource } from './tts.js';
import { stopMusic } from './music.js';
import { forceClearAllVoice } from './voice-guard.js';

/** @typedef {{ connection: any, player: any, voiceChannelId: string, textChannelId: string, personaKey: string, customSystem?: string, listening: boolean, speaking: boolean, speakQueue: string[], processingUsers: Set<string>, client: any }} VcSession */

const sessions = new Map();

function pcmToWav(pcm, sampleRate = 48000, channels = 2) {
  const byteRate = sampleRate * channels * 2;
  const blockAlign = channels * 2;
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

function getSession(guildId) {
  return sessions.get(guildId);
}

function systemPrompt(session) {
  if (session.customSystem) {
    return `${getPersona(session.personaKey).system}\n\nAdditional persona: ${session.customSystem}`;
  }
  return getPersona(session.personaKey).system;
}

function personaKey(session) {
  return session.personaKey;
}

async function ensurePlayer(session) {
  if (!session.player) {
    session.player = createAudioPlayer({
      behaviors: { noSubscriber: NoSubscriberBehavior.Play },
    });
    session.connection.subscribe(session.player);
    session.player.on(AudioPlayerStatus.Idle, () => {
      drainSpeakQueue(session.guildId);
    });
  }
}

async function speakNow(session, text) {
  await ensurePlayer(session);
  const resource = await textToSpeechResource(text, personaKey(session));
  session.speaking = true;
  session.player.play(resource);
  await entersState(session.player, AudioPlayerStatus.Playing, 20_000).catch(() => {});
  await entersState(session.player, AudioPlayerStatus.Idle, 120_000).catch(() => {});
  session.speaking = false;
}

async function drainSpeakQueue(guildId) {
  const session = sessions.get(guildId);
  if (!session || session.speaking || !session.speakQueue.length) return;
  const next = session.speakQueue.shift();
  try {
    await speakNow(session, next);
  } catch (err) {
    console.warn('VC TTS failed:', err.message);
  }
  if (session.speakQueue.length) drainSpeakQueue(guildId);
}

function queueSpeech(session, text) {
  session.speakQueue.push(text);
  if (!session.speaking) drainSpeakQueue(session.guildId);
}

function wireConnectionLifecycle(session) {
  const { connection, guildId } = session;
  if (!connection || connection.__phantomVcWired) return;
  connection.__phantomVcWired = true;

  connection.on(VoiceConnectionStatus.Disconnected, async () => {
    try {
      await Promise.race([
        entersState(connection, VoiceConnectionStatus.Signalling, 20_000),
        entersState(connection, VoiceConnectionStatus.Connecting, 20_000),
      ]);
      console.log(`VC voice reconnected (guild ${guildId})`);
    } catch {
      console.warn(
        `VC voice disconnected (guild ${guildId}) — use /vcjoin again if the bot left the channel.`,
      );
    }
  });

  connection.on(VoiceConnectionStatus.Destroyed, () => {
    sessions.delete(guildId);
    console.log(`VC session ended (guild ${guildId})`);
  });
}

function bindSession(guildId, session) {
  sessions.set(guildId, session);
  setupVoiceListen(session);
  wireConnectionLifecycle(session);
}

/**
 * Bot can be in VC (music/Lavalink or partial join) without a VC assistant session.
 * Rebuild session so /ask works without forcing another /vcjoin.
 */
export async function recoverVcSession(interaction) {
  const guildId = interaction.guildId;
  const existing = sessions.get(guildId);
  if (existing?.connection) return existing;

  const botChannelId = interaction.guild.members.me?.voice?.channelId;
  if (!botChannelId) return null;

  if (!aiConfigured()) return null;

  await stopMusic(guildId);
  await forceClearAllVoice(guildId);

  let connection = getVoiceConnection(guildId);
  if (!connection || connection.joinConfig.channelId !== botChannelId) {
    if (connection) {
      try {
        connection.destroy();
      } catch {
        /* ignore */
      }
    }
    connection = joinVoiceChannel({
      channelId: botChannelId,
      guildId,
      adapterCreator: interaction.guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });
    await entersState(connection, VoiceConnectionStatus.Ready, 15_000);
  }

  const session = {
    guildId,
    connection,
    player: existing?.player || null,
    voiceChannelId: botChannelId,
    textChannelId: interaction.channelId,
    personaKey: existing?.personaKey || 'assistant',
    customSystem: existing?.customSystem,
    listening: existing?.listening ?? true,
    speaking: false,
    speakQueue: existing?.speakQueue || [],
    processingUsers: new Set(),
    client: interaction.client,
  };

  bindSession(guildId, session);
  console.log(`VC session recovered for guild ${guildId} in channel ${botChannelId}`);
  return session;
}

function setupVoiceListen(session) {
  if (session.__phantomListenWired) return;
  session.__phantomListenWired = true;
  const receiver = session.connection.receiver;

  receiver.speaking.on('start', (userId) => {
    if (!session.listening || !aiConfigured()) return;
    if (session.processingUsers.has(userId)) return;
    if (userId === session.client.user.id) return;

    session.processingUsers.add(userId);

    const opusStream = receiver.subscribe(userId, {
      end: {
        behavior: EndBehaviorType.AfterSilence,
        duration: 1400,
      },
    });

    const decoder = new prism.opus.Decoder({
      rate: 48000,
      channels: 2,
      frameSize: 960,
    });

    const chunks = [];
    opusStream.pipe(decoder);
    decoder.on('data', (chunk) => chunks.push(chunk));

    decoder.on('end', async () => {
      session.processingUsers.delete(userId);
      const pcm = Buffer.concat(chunks);
      if (pcm.length < 48000 * 2 * 0.4) return; // ~0.4s min

      try {
        const wav = pcmToWav(pcm);
        const text = await transcribeWav(wav);
        if (!text || text.length < 2) return;

        const guild = await session.client.guilds.fetch(session.guildId).catch(() => null);
        const member = guild ? await guild.members.fetch(userId).catch(() => null) : null;

        const display = member?.displayName || member?.user?.username || 'Someone';
        console.log(`VC heard (${display}): ${text.slice(0, 80)}`);

        const answer = await chatReply(text, {
          system: systemPrompt(session),
          userName: display,
        });

        queueSpeech(session, answer);

        const channel = await session.client.channels.fetch(session.textChannelId).catch(() => null);
        if (channel?.isTextBased()) {
          await channel.send({
            embeds: [
              new EmbedBuilder()
                .setColor(0x8b5cf6)
                .setTitle(`🎙️ ${display} asked`)
                .setDescription(text.slice(0, 500))
                .addFields({ name: `${getPersona(session.personaKey).label} says`, value: answer.slice(0, 1000) }),
            ],
          });
        }
      } catch (err) {
        console.warn('VC listen pipeline:', err.message);
      }
    });

    opusStream.on('error', () => session.processingUsers.delete(userId));
    decoder.on('error', () => session.processingUsers.delete(userId));
  });
}

export function isVcActive(guildId) {
  return sessions.has(guildId);
}

export async function joinVcAssistant(interaction, { listen = true } = {}) {
  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) throw new Error('Join a voice channel first.');

  if (!aiConfigured()) {
    throw new Error('Add OPENAI_API_KEY to .env for voice Q&A (chat + Whisper).');
  }

  await stopMusic(interaction.guildId);
  await forceClearAllVoice(interaction.guildId);

  let session = sessions.get(interaction.guildId);
  if (session?.connection) {
    try {
      session.connection.destroy();
    } catch {
      /* ignore */
    }
    sessions.delete(interaction.guildId);
  }

  let connection;
  try {
    connection = joinVoiceChannel({
      channelId: voiceChannel.id,
      guildId: interaction.guildId,
      adapterCreator: interaction.guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });

    await entersState(connection, VoiceConnectionStatus.Ready, 20_000);

    session = {
      guildId: interaction.guildId,
      connection,
      player: null,
      voiceChannelId: voiceChannel.id,
      textChannelId: interaction.channelId,
      personaKey: 'assistant',
      customSystem: undefined,
      listening: listen && aiConfigured(),
      speaking: false,
      speakQueue: [],
      processingUsers: new Set(),
      client: interaction.client,
    };

    bindSession(interaction.guildId, session);
  } catch (err) {
    if (connection) {
      try {
        connection.destroy();
      } catch {
        /* ignore */
      }
    }
    sessions.delete(interaction.guildId);
    throw err;
  }

  if (voiceChannel.type === 13) {
    setTimeout(() => {
      interaction.guild.members.me?.voice.setSuppressed(false).catch(() => {});
    }, 500);
  }

  const persona = getPersona(session.personaKey);
  return { persona, listening: session.listening, channelName: voiceChannel.name };
}

export async function leaveVcAssistant(guildId) {
  const session = sessions.get(guildId);
  if (!session) return false;

  session.listening = false;
  session.speakQueue = [];
  if (session.player) {
    session.player.stop();
  }
  if (session.connection) {
    session.connection.destroy();
  }
  sessions.delete(guildId);
  return true;
}

export function setVcPersona(guildId, personaKey, customSystem) {
  const session = sessions.get(guildId);
  if (!session) return null;
  if (personaKey && PERSONAS[personaKey]) session.personaKey = personaKey;
  if (customSystem !== undefined) {
    session.customSystem = customSystem?.trim() || undefined;
  }
  return getPersona(session.personaKey);
}

export function setVcListening(guildId, enabled) {
  const session = sessions.get(guildId);
  if (!session) return false;
  session.listening = enabled && aiConfigured();
  return session.listening;
}

export async function askInVc(interaction, question) {
  let session = sessions.get(interaction.guildId);
  if (!session) {
    session = await recoverVcSession(interaction);
  }
  if (!session) {
    throw new Error('Bot is not in voice. Use `/vcjoin` first (not `/play` — music uses a different voice mode).');
  }

  const memberChannel = interaction.member?.voice?.channelId;
  if (memberChannel !== session.voiceChannelId) {
    throw new Error('You must be in the same voice channel as the bot.');
  }

  const q = (question || '').trim();
  if (!q) throw new Error('Ask a question.');

  const answer = await chatReply(q, {
    system: systemPrompt(session),
    userName: interaction.user.username,
  });

  queueSpeech(session, answer);
  return { question: q, answer, persona: getPersona(session.personaKey) };
}

export async function sayInVc(guildId, text) {
  const session = sessions.get(guildId);
  if (!session) throw new Error('Bot is not in voice.');
  queueSpeech(session, text);
}
