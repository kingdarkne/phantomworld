const Discord = require('discord.js');
const { getGuildJoinLink } = require('../../lib/guild-invite-link');

const GUILDS_PER_EMBED = 10;

module.exports = async (client, interaction) => {
    const guilds = [...client.guilds.cache.values()].sort(
        (a, b) => b.memberCount - a.memberCount
    );

    if (!guilds.length) {
        return client.errNormal({
            error: 'The bot is not in any servers.',
            type: 'editreply',
        }, interaction);
    }

    const lines = [];
    const embeds = [];

    for (let i = 0; i < guilds.length; i++) {
        const guild = guilds[i];
        const joinLink = await getGuildJoinLink(guild);
        const joinText = joinLink ? joinLink : 'No invite (bot needs Create Invite in a channel)';

        lines.push(
            `${i + 1}. ${guild.name} (${guild.id}) | ${guild.memberCount} members | Join: ${joinText}`
        );

        const chunkIndex = Math.floor(i / GUILDS_PER_EMBED);
        if (!embeds[chunkIndex]) {
            embeds[chunkIndex] = client.templateEmbed()
                .setTitle('🌐 Bot servers')
                .setDescription(
                    `**${guilds.length}** server(s) on this shard — sorted by members.\nJoin links are permanent when the bot can create or read them.`
                );
        }

        embeds[chunkIndex].addFields({
            name: `${i + 1}. ${guild.name}`,
            value: [
                `**Members:** ${guild.memberCount}`,
                `**Owner:** <@${guild.ownerId}>`,
                `**Join:** ${joinText}`,
                `**ID:** \`${guild.id}\``,
            ].join('\n'),
        });
    }

    if (embeds.length > 1) {
        embeds.forEach((e, idx) => {
            e.setFooter({ 
                text: `Page ${idx + 1}/${embeds.length} • ${client.config.discord.footer}`, 
                iconURL: client.user?.displayAvatarURL({ size: 1024 })
            });
        });
    }

    const output = new Discord.AttachmentBuilder(Buffer.from(lines.join('\n'), 'utf8'), {
        name: 'phantom-servers.txt',
    });

    await interaction.editReply({  
        embeds: embeds.slice(0, 10),
        files: [output],
    });
};
