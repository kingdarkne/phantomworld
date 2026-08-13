const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { getPhantomStatus } = require('../../../aio-bridge/fivem-status');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('players')
    .setDescription('List online FiveM players'),

  run: async (client, interaction) => {
    if (!interaction.deferred && !interaction.replied) {
      if (!interaction.deferred && !interaction.replied) await interaction.deferReply().catch(() => {}).catch(() => {});
    }

    try {
      const status = await getPhantomStatus();
      const base = (process.env.FIVEM_SERVER_URL || 'http://172.245.71.46:30120').replace(/\/$/, '');
      let players = [];
      try {
        const headers = {};
        const token = process.env.FIVEM_API_TOKEN || process.env.BOT_RELAY_SECRET || '';
        if (token) headers.Authorization = `Bearer ${token}`;
        const res = await fetch(`${base}/players.json`, {
          headers,
          signal: AbortSignal.timeout(8000),
        });
        if (res.ok) {
          const data = await res.json();
          players = Array.isArray(data) ? data : [];
        }
      } catch {
        // ignore list fetch
      }

      const lines =
        players.length > 0
          ? players
              .slice(0, 40)
              .map((p) => `• **${p.name || 'Unknown'}**${p.id != null ? ` (ID ${p.id})` : ''}`)
              .join('\n')
          : '_No players online or list unavailable._';

      const embed = new EmbedBuilder()
        .setColor(0x2ee6c5)
        .setTitle(`${status.serverName || 'Phantom World'} — Players`)
        .setDescription(lines.slice(0, 4000))
        .addFields({
          name: 'Online',
          value: `${status.playerCount ?? players.length}/${status.maxPlayers ?? 48}`,
          inline: true,
        })
        .setFooter({ text: 'Phantom World' })
        .setTimestamp();

      await interaction.editReply({ embeds: [embed] });
    } catch (err) {
      await interaction.editReply(`Failed to fetch players: ${err.message}`).catch(() => {});
    }
  },
};
