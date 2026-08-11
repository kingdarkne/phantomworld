const {
  SlashCommandBuilder,
  EmbedBuilder,
  ButtonBuilder,
  ActionRowBuilder,
  StringSelectMenuBuilder,
  ButtonStyle,
  ComponentType,
} = require('discord.js');
const fs = require('fs');
const path = require('path');

module.exports = {
  data: new SlashCommandBuilder().setName('help').setDescription('Get help with the bot'),

  /**
   * @param {import('discord.js').Client} client
   * @param {import('discord.js').ChatInputCommandInteraction} interaction
   */
  run: async (client, interaction) => {
    const toUpperCase = (string) => string.charAt(0).toUpperCase() + string.slice(1);

    const getCommandMentions = (name) => {
      if (typeof client.getSlashMentions !== 'function') {
        return `Use \`/${name}\` — or \`$ ${name}\` with the bot prefix.`;
      }
      try {
        const mentions = client.getSlashMentions(name);
        if (!mentions || !Array.isArray(mentions)) {
          return `Use \`/${name}\` or \`$${name}\``;
        }
        return mentions.map((cmd) => `${cmd[0]} - \`${cmd[1]}\``).join('\n');
      } catch (err) {
        console.error(`Error getting mentions for ${name}:`, err);
        return `Use \`/${name}\` or \`$${name}\``;
      }
    };

    const categoriesPath = path.join(process.cwd(), 'src', 'commands');
    const categoryDirs = fs.readdirSync(categoriesPath).filter((d) => {
      try {
        return fs.statSync(path.join(categoriesPath, d)).isDirectory();
      } catch {
        return false;
      }
    });

    const prefix = client.config?.discord?.prefix || process.env.COMMAND_PREFIX || '$';

    const overview = new EmbedBuilder()
      .setAuthor({
        name: `${client.user.username}'s Help Menu`,
        iconURL: client.user.displayAvatarURL({ extension: 'png' }),
      })
      .setColor('#2ee6c5')
      .setDescription(
        [
          `Welcome to the help menu! Browse categories below.`,
          '',
          `**Prefix:** \`${prefix}\` · **Slash:** \`/\``,
          `Examples: \`${prefix}help\` · \`${prefix}play <song>\` · \`${prefix}ban @user\` · \`/music play\``,
        ].join('\n'),
      )
      .addFields(
        {
          name: 'Popular',
          value: [
            `\`${prefix}play\` / \`/music play\` — music`,
            `\`${prefix}ban\` / \`/moderation ban\` — moderation`,
            `\`${prefix}hug\` / \`/fun hug\` — fun`,
            `\`/phantomstatus\` — FiveM status`,
            `\`/dminvite\` — DM FiveM invite`,
          ].join('\n'),
        },
        {
          name: `Categories (${categoryDirs.length})`,
          value: categoryDirs
            .slice(0, 30)
            .map((d) => `\`${d}\``)
            .join(', ')
            .slice(0, 1000),
        },
      );

    const startButton = new ButtonBuilder().setStyle(ButtonStyle.Secondary).setEmoji('⏮️').setCustomId('help-start');
    const backButton = new ButtonBuilder().setStyle(ButtonStyle.Secondary).setEmoji('⬅️').setCustomId('help-back');
    const forwardButton = new ButtonBuilder().setStyle(ButtonStyle.Secondary).setEmoji('➡️').setCustomId('help-forward');
    const endButton = new ButtonBuilder().setStyle(ButtonStyle.Secondary).setEmoji('⏭️').setCustomId('help-end');

    const options = [{ label: 'Overview', value: '0', description: 'Start here' }];
    const options2 = [];
    categoryDirs.forEach((dir, index) => {
      const opt = {
        label: toUpperCase(dir.replace(/-/g, ' ')).slice(0, 100),
        value: `${index + 1}`,
      };
      if (options.length < 25) options.push(opt);
      else if (options2.length < 25) options2.push(opt);
    });

    const menu = new StringSelectMenuBuilder()
      .setPlaceholder('Change page (Part 1)')
      .setCustomId('help-pagMenu')
      .addOptions(options)
      .setMaxValues(1)
      .setMinValues(1);
    const menu2 =
      options2.length > 0
        ? new StringSelectMenuBuilder()
            .setPlaceholder('Change page (Part 2)')
            .setCustomId('help-pagMenu2')
            .addOptions(options2)
            .setMaxValues(1)
            .setMinValues(1)
        : null;

    const embeds = [overview];
    for (const dir of categoryDirs) {
      embeds.push(
        new EmbedBuilder()
          .setAuthor({
            name: toUpperCase(dir.replace(/-/g, ' ')),
            iconURL: client.user.displayAvatarURL({ extension: 'png' }),
          })
          .setColor('#2ee6c5')
          .setDescription(
            `${getCommandMentions(dir)}\n\nPrefix: \`${prefix}${dir} <subcommand>\` or \`${prefix}<subcommand>\` when unique.`,
          )
          .setFooter({
            text: `Prefix ${prefix} · Slash /`,
            iconURL: client.user.displayAvatarURL({ extension: 'png' }),
          }),
      );
    }

    embeds.forEach((embed, index) => {
      embed.setFooter({
        text: `Page ${index + 1} / ${embeds.length} · Prefix ${prefix}`,
        iconURL: client.user.displayAvatarURL({ extension: 'png' }),
      });
    });

    const getComponents = (page, total) => {
      const row1 = new ActionRowBuilder().addComponents(menu);
      const row2 = new ActionRowBuilder().addComponents(
        startButton.setDisabled(page === 0),
        backButton.setDisabled(page === 0),
        forwardButton.setDisabled(page >= total - 1),
        endButton.setDisabled(page >= total - 1),
      );
      const components = [row1, row2];
      if (menu2) components.push(new ActionRowBuilder().addComponents(menu2));
      return components;
    };

    const payload = {
      content: `Use the menu/buttons · Prefix \`${prefix}\` works for commands too`,
      embeds: [embeds[0]],
      components: getComponents(0, embeds.length),
    };

    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(payload);
    } else {
      await interaction.reply(payload);
    }

    const message = await interaction.fetchReply();
    const collector = message.createMessageComponentCollector({
      filter: (i) => i.user.id === interaction.user.id,
      time: 120000,
    });

    let currentPage = 0;
    collector.on('collect', async (b) => {
      try {
        if (b.customId === 'help-start') currentPage = 0;
        else if (b.customId === 'help-back') currentPage = Math.max(0, currentPage - 1);
        else if (b.customId === 'help-forward') currentPage = Math.min(embeds.length - 1, currentPage + 1);
        else if (b.customId === 'help-end') currentPage = embeds.length - 1;
        else if (b.customId === 'help-pagMenu' || b.customId === 'help-pagMenu2') {
          currentPage = parseInt(b.values[0], 10) || 0;
        }

        await b.update({
          embeds: [embeds[currentPage]],
          components: getComponents(currentPage, embeds.length),
        });
      } catch (err) {
        console.warn('[help] collector update failed:', err.message);
      }
    });

    collector.on('end', () => {
      interaction.editReply({ components: [] }).catch(() => {});
    });
  },
};
