const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { getPhantomStatus } = require('../../../aio-bridge/fivem-status');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('phantomstatus')
    .setDescription('Phantom World FiveM server status'),

  /** @param {import('discord.js').Client} client */
  /** @param {import('discord.js').ChatInputCommandInteraction} interaction */
  run: async (client, interaction) => {
    try {
      const status = await getPhantomStatus();
      const joinId = process.env.CFX_SERVER_ID || '';
      const embed = new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World — Server Status')
        .addFields(
          { name: 'Server', value: status.serverName || 'Unknown', inline: true },
          {
            name: 'Players',
            value: `${status.playerCount ?? 0}/${status.maxPlayers ?? 48}`,
            inline: true,
          },
          { name: 'Source', value: status.source || 'fivem', inline: true },
        )
        .setTimestamp();
      if (joinId) {
        embed.setDescription(`[Connect](https://cfx.re/join/${joinId})`);
      }
      await interaction.editReply({ embeds: [embed] });
    } catch (err) {
      await interaction.editReply({ content: err?.message || 'Status failed' });
    }
  },
};
