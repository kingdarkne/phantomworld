
const { CommandInteraction, Client, SlashCommandBuilder, EmbedBuilder, ButtonBuilder, ActionRowBuilder, StringSelectMenuBuilder, ComponentType } = require('discord.js');
const fs = require('fs');
const path = require('path');

module.exports = {
    data: new SlashCommandBuilder()
        .setName('help')
        .setDescription('Get help with the bot'),

    /** 
     * @param {Client} client
     * @param {CommandInteraction} interaction
     * @param {String[]} args
     */

    run: async (client, interaction, args) => {
        const toUpperCase = (string) => string.charAt(0).toUpperCase() + string.slice(1);
        
        const getCommandMentions = (name) => {
            if (typeof client.getSlashMentions !== 'function') {
                return `Use \`/${name}\` — slash list still loading. Try /help again in a moment.`;
            }
            try {
                const mentions = client.getSlashMentions(name);
                if (!mentions || !Array.isArray(mentions)) return `Use \`/${name}\``;
                return mentions.map((cmd) => `${cmd[0]} - \`${cmd[1]}\``).join('\n');
            } catch (err) {
                console.error(`Error getting mentions for ${name}:`, err);
                return `Use \`/${name}\``;
            }
        };

        const categoriesPath = path.join(process.cwd(), 'src', 'commands');
        const categoryDirs = fs.readdirSync(categoriesPath);

        let em1 = new EmbedBuilder()
            .setAuthor({ name: `${client.user.username}'s Help Menu`, iconURL: client.user.displayAvatarURL({ extension: "png" })
            .setImage(`https://i.stack.imgur.com/Fzh0w.png`)
            .setColor(`#5865F2`)
            .setDescription(`Welcome to the help menu! Use the menu below to browse categories.`)
            .addFields([
                {
                    name: "Categories [1-9]",
                    value: `>>> 🚫┆AFK\n📣┆Announcement\n👮‍♂️┆Auto mod\n⚙️┆Auto setup\n🎂┆Birthday\n🤖┆Bot\n🎰┆Casino\n⚙┆Configuration\n💻┆CustomCommand`,
                    inline: true
                },
                {
                    name: "Categories [10-18]",
                    value: `>>> 💳┆Dcredits\n💰┆Economy\n👪┆Family\n😂┆Fun\n🎮┆Games\n🥳┆Giveaway\n⚙️┆Guild\n🖼┆Images\n📨┆Invites`,
                    inline: true
                },
                {
                    name: "\u200b",
                    value: "\u200b",
                    inline: true
                },
                {
                    name: "Categories [19-27]",
                    value: `>>> 🆙┆Leveling\n💬┆Messages\n👔┆Moderation\n🎶┆Music\n📓┆Notepad\n👤┆Profile\n📻┆Radio\n😛┆Reaction Role\n🔍┆Search`,
                    inline: true
                },
                {
                    name: "Categories [28-36]",
                    value: `>>> 📊┆Server stats\n⚙️┆Setup\n🎛┆Soundboard\n🗨️┆StickyMessage\n💡┆Suggestions\n🤝┆Thanks\n🎫┆Tickets\n⚒️┆Tools\n🔊┆Voice`,
                    inline: true
                },
                {
                    name: "\u200b",
                    value: "\u200b",
                    inline: true
                },
            ]);

        let startButton = new ButtonBuilder().setStyle(2).setEmoji(`⏮️`).setCustomId('start');
        let backButton = new ButtonBuilder().setStyle(2).setEmoji(`⬅️`).setCustomId('back');
        let forwardButton = new ButtonBuilder().setStyle(2).setEmoji(`➡️`).setCustomId('forward');
        let endButton = new ButtonBuilder().setStyle(2).setEmoji(`⏭️`).setCustomId('end');
        let link = new ButtonBuilder().setStyle(5).setLabel("Support Server").setEmoji(`🥹`).setURL('https://discord.gg/zZSvmdUx');

        const options = [{ label: 'Overview', value: '0' }];
        const options2 = [];

        categoryDirs.forEach((dir, index) => {
            const opt = {
                label: toUpperCase(dir.replace("-", " ")),
                value: `${index + 1}`
            };
            if (index < 24) {
                options.push(opt);
            } else {
                options2.push(opt);
            }
        });

        let menu = new StringSelectMenuBuilder().setPlaceholder('Change page (Part 1)').setCustomId('pagMenu').addOptions(options).setMaxValues(1).setMinValues(1);
        let menu2 = options2.length > 0 ? new StringSelectMenuBuilder().setPlaceholder('Change page (Part 2)').setCustomId('pagMenu2').addOptions(options2).setMaxValues(1).setMinValues(1) : null;

        const getComponents = (page, total) => {
            const row1 = new ActionRowBuilder().addComponents(menu);
            const row2 = new ActionRowBuilder().addComponents([
                startButton.setDisabled(page === 0),
                backButton.setDisabled(page === 0),
                forwardButton.setDisabled(page === total - 1),
                endButton.setDisabled(page === total - 1),
                link
            ]);
            const components = [row1, row2];
            if (menu2) components.push(new ActionRowBuilder().addComponents(menu2));
            return components;
        };

        const embeds = [em1];
        categoryDirs.forEach(dir => {
            embeds.push(new EmbedBuilder()
                .setAuthor({ name: toUpperCase(dir), iconURL: client.user.displayAvatarURL({ extension: "png" })
                .setColor("#5865F2")
                .setImage(`https://i.stack.imgur.com/Fzh0w.png`)
                .setDescription(`${getCommandMentions(dir)}`)
            );
        });

        embeds.forEach((embed, index) => {
            embed.setFooter({ text: `Page ${index + 1} / ${embeds.length}`, iconURL: client.user.displayAvatarURL({ extension: "png" });
        });

        const helpMessage = await interaction.reply({
            content: `Click on the buttons or use the menu to change pages`,
            embeds: [em1],
            components: getComponents(0, embeds.length),
            
        });

        const collector = interaction.channel.createMessageComponentCollector({
            filter: (i) => i.user.id === interaction.user.id,
            time: 60000,
            componentType: ComponentType.Button || ComponentType.StringSelect
        });

        let currentPage = 0;

        collector.on('collect', async (b) => {
            if (b.customId === 'start') currentPage = 0;
            else if (b.customId === 'back') currentPage--;
            else if (b.customId === 'forward') currentPage++;
            else if (b.customId === 'end') currentPage = embeds.length - 1;
            else if (b.customId === 'pagMenu' || b.customId === 'pagMenu2') currentPage = parseInt(b.values[0]);

            await b.update({
                embeds: [embeds[currentPage]],
                components: getComponents(currentPage, embeds.length)
            });
        });

        collector.on('end', () => {
            interaction.editReply({   components: [] }).catch(() => {});
        });
    },
};
