const { getVoiceConnection } = require('@discordjs/voice');
const { stopShoukakuGuild } = require('../../lib/rex-voice-play.cjs');

module.exports = async (client, interaction) => {
  if (!interaction.deferred && !interaction.replied) {
    if (!interaction.deferred && !interaction.replied) await interaction.deferReply().catch(() => {}).catch(() => {});
  }

  const guildId = interaction.guild.id;
  const guild = interaction.guild;
  const djsConnection = getVoiceConnection(guildId);
  const shoukakuPlayer = client.shoukaku?.players?.get(guildId);
  const botMember = guild.members.me || (await guild.members.fetchMe().catch(() => null));
  const botInVc = Boolean(botMember?.voice?.channelId);
  const rexActive = Boolean(global.rexState?.[guildId]?.active);

  if (!djsConnection && !shoukakuPlayer && !botInVc && !rexActive) {
    return client.errNormal(
      {
        error:
          'Rex is not in a voice channel right now.\n\nUse `/rex join` to listen, or `/rex ask` while you are in a VC to speak.',
        type: 'editreply',
      },
      interaction,
    );
  }

  if (global.rexState?.[guildId]) {
    global.rexState[guildId].active = false;
    global.rexState[guildId].processing = false;
    global.rexState[guildId].connection = null;
  }

  const leftFrom = [];

  try {
    if (djsConnection) {
      djsConnection.destroy();
      leftFrom.push('listener');
    }
  } catch (err) {
    console.warn('[Rex Leave] destroy djs failed:', err.message);
  }

  try {
    if (shoukakuPlayer || botInVc) {
      await stopShoukakuGuild(client, guildId);
      leftFrom.push('player');
    }
  } catch (err) {
    console.warn('[Rex Leave] shoukaku leave failed:', err.message);
  }

  // If Discord still shows the bot in VC, force disconnect
  try {
    const fresh = guild.members.me || (await guild.members.fetchMe().catch(() => null));
    if (fresh?.voice?.channelId) {
      await fresh.voice.disconnect().catch(() => {});
      leftFrom.push('discord');
    }
  } catch (_) {}

  return client.succNormal({
    text:
      leftFrom.length > 0
        ? 'Rex has left the voice channel and stopped listening.'
        : 'Rex session cleared. (Bot was already out of voice.)',
    type: 'editreply',
  }, interaction);
};
