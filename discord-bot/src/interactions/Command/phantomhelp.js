const help = require('./help');
const { SlashCommandBuilder } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('phantomhelp')
    .setDescription('Phantom command menu (alias of /help)'),
  run: help.run,
};
