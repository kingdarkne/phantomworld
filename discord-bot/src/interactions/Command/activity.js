const { SlashCommandBuilder } = require('discord.js');

module.exports = {
    data: new SlashCommandBuilder()
        .setName('activity')
        .setDescription('Manage server activity checks')
        .addSubcommand(subcommand =>
            subcommand
                .setName('check')
                .setDescription('Start an activity check for all servers')
        )
        .addSubcommand(subcommand =>
            subcommand
                .setName('status')
                .setDescription('Check the status of ongoing activity checks')
        ),

    /** 
     * @param {import('discord.js').Client} client
     * @param {import('discord.js').ChatInputCommandInteraction} interaction
     * @param {any} args
     */
    run: async (client, interaction, args) => {
        // Global defer is already handled in interactionCreate.js
        client.loadSubcommands(client, interaction, args);
    },
};
