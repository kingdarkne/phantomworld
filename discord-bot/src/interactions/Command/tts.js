const { SlashCommandBuilder } = require('discord.js');

module.exports = {
    data: new SlashCommandBuilder()
        .setName('tts')
        .setDescription('Text-to-speech in voice (requires setup)')
        .addSubcommand((sub) =>
            sub
                .setName('speak')
                .setDescription('Speak text in your voice channel')
                .addStringOption((option) =>
                    option.setName('text').setDescription('What to say').setRequired(true),
                ),
        ),

    run: async (client, interaction) => {
        if (!interaction.deferred && !interaction.replied) await interaction.deferReply({ ephemeral: true });
        client.loadSubcommands(client, interaction);
    },
};
