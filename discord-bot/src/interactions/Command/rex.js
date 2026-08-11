const { SlashCommandBuilder } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('rex')
    .setDescription('Rex — AI voice assistant powered by Groq + Kokoro')
    .addSubcommand((sub) =>
      sub
        .setName('join')
        .setDescription('Rex joins your voice channel and starts listening for "Hey Rex"'),
    )
    .addSubcommand((sub) =>
      sub.setName('leave').setDescription('Rex leaves the voice channel and stops listening'),
    )
    .addSubcommand((sub) =>
      sub
        .setName('ask')
        .setDescription('Ask Rex something via text (no voice needed)')
        .addStringOption((opt) =>
          opt.setName('question').setDescription('What do you want to ask Rex?').setRequired(true),
        ),
    )
    .addSubcommand((sub) =>
      sub
        .setName('mode')
        .setDescription('[ADMIN ONLY] Toggle Rex unrestricted mode')
        .addStringOption((opt) =>
          opt
            .setName('setting')
            .setDescription('Enable or disable unrestricted mode')
            .setRequired(true)
            .addChoices(
              { name: '🔓 Enable Unrestricted Mode', value: 'on' },
              { name: '🔒 Disable (Normal Mode)', value: 'off' },
            ),
        ),
    )
    .addSubcommand((sub) =>
      sub.setName('reset').setDescription("Clear Rex's conversation memory for this server"),
    )
    .addSubcommand((sub) =>
      sub
        .setName('voice')
        .setDescription("Change Rex's voice")
        .addStringOption((opt) =>
          opt
            .setName('pick')
            .setDescription('Choose a voice for Rex')
            .setRequired(true)
            .addChoices(
              { name: '🔵 Adam (US Male) — Default', value: 'am_adam' },
              { name: '🟢 Michael (US Male)', value: 'am_michael' },
              { name: '🇬🇧 George (British Male)', value: 'bm_george' },
              { name: '💜 Heart (US Female)', value: 'af_heart' },
              { name: '⭐ Bella (US Female)', value: 'af_bella' },
              { name: '🇬🇧 Emma (British Female)', value: 'bf_emma' },
            ),
        ),
    ),

  /**
   * interactionCreate already defers — never defer again here.
   * All subs live under src/commands/rex/*.js
   */
  run: async (client, interaction, args) => {
    const sub = interaction.options.getSubcommand(false);
    if (!sub) {
      const msg =
        'Usage: `/rex join` · `/rex leave` · `/rex ask` · `/rex voice` — or `$rex join` / `$rex ask <question>`';
      if (interaction.deferred || interaction.replied) {
        return interaction.editReply({ content: msg }).catch(() => {});
      }
      return interaction.reply({ content: msg, ephemeral: true }).catch(() => {});
    }

    return client.loadSubcommands(client, interaction, args);
  },
};
