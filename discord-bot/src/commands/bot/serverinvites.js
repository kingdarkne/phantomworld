const { PermissionsBitField, EmbedBuilder } = require('discord.js');

module.exports = async (client, interaction, args) => {
    // Owner only — only the bot owner can use this command
    const ownerId = process.env.OWNER_ID || process.env.DISCORD_OWNER_USER_ID;
    if (interaction.user.id !== ownerId) {
        return client.errNormal({
            error: `This command is restricted to the **bot owner** only.`,
            type: 'editreply',
        }, interaction);
    }

    await client.simpleEmbed({
        desc: `🔍 Fetching invite links for all servers... please wait.`,
        type: 'editreply',
    }, interaction);

    const guilds = client.guilds.cache;
    const results = [];
    let successCount = 0;
    let failCount = 0;

    for (const [guildId, guild] of guilds) {
        try {
            // Fetch full guild data if needed
            const fullGuild = guild.available ? guild : await client.guilds.fetch(guildId).catch(() => null);
            if (!fullGuild) {
                results.push({ name: guild.name || 'Unknown', id: guildId, invite: null, reason: 'Guild unavailable' });
                failCount++;
                continue;
            }

            // Check if bot has CREATE_INSTANT_INVITE permission in any channel
            const me = fullGuild.members.me || await fullGuild.members.fetchMe().catch(() => null);
            if (!me) {
                results.push({ name: fullGuild.name, id: guildId, invite: null, reason: 'Cannot fetch bot member' });
                failCount++;
                continue;
            }

            // Find a suitable channel to create invite in
            const channel = fullGuild.channels.cache.find(ch =>
                (ch.type === 0 || ch.type === 2) && // Text or Voice
                ch.permissionsFor(me)?.has(PermissionsBitField.Flags.CreateInstantInvite) &&
                ch.permissionsFor(me)?.has(PermissionsBitField.Flags.ViewChannel)
            );

            if (!channel) {
                results.push({ name: fullGuild.name, id: guildId, invite: null, reason: 'No permission to create invite' });
                failCount++;
                continue;
            }

            // Create a permanent invite (or 7-day if permanent not allowed)
            const invite = await channel.createInvite({
                maxAge: 604800,    // 7 days
                maxUses: 0,        // Unlimited uses
                unique: false,
                reason: `Bot owner requested server invite list`,
            });

            results.push({
                name: fullGuild.name,
                id: guildId,
                memberCount: fullGuild.memberCount,
                invite: `https://discord.gg/${invite.code}`,
                channel: channel.name,
            });
            successCount++;

        } catch (err) {
            results.push({ name: guild.name || 'Unknown', id: guildId, invite: null, reason: err.message });
            failCount++;
        }
    }

    // Sort: successful invites first, then failures
    results.sort((a, b) => {
        if (a.invite && !b.invite) return -1;
        if (!a.invite && b.invite) return 1;
        return (a.name || '').localeCompare(b.name || '');
    });

    // Build paginated embeds (25 servers per embed due to Discord limits)
    const pageSize = 15;
    const pages = [];

    for (let i = 0; i < results.length; i += pageSize) {
        const chunk = results.slice(i, i + pageSize);
        const embed = new EmbedBuilder()
            .setTitle(`🌐 Bot Server Invites (${i / pageSize + 1}/${Math.ceil(results.length / pageSize)})`)
            .setColor(0x5865F2)
            .setDescription(
                `**Total Servers:** ${guilds.size} | ✅ **Got Invite:** ${successCount} | ❌ **No Permission:** ${failCount}\n\n` +
                chunk.map(r => {
                    if (r.invite) {
                        return `✅ **${r.name}** \`${r.id}\`\n┗ 👥 ${r.memberCount?.toLocaleString() || '?'} members | 📨 [Invite](${r.invite})`;
                    } else {
                        return `❌ **${r.name}** \`${r.id}\`\n┗ *${r.reason || 'No permission'}*`;
                    }
                }).join('\n\n')
            )
            .setFooter({ text: `Requested by ${interaction.user.tag}` })
            .setTimestamp();
        pages.push(embed);
    }

    if (pages.length === 0) {
        return client.errNormal({
            error: `The bot is not in any servers!`,
            type: 'editreply',
        }, interaction);
    }

    // Send first page as edit reply
    await interaction.editReply({   embeds: [pages[0]] });

    // Send remaining pages as follow-up messages (DM or same channel)
    for (let i = 1; i < pages.length; i++) {
        await interaction.followUp({   embeds: [pages[i]], ephemeral: true });
    }
};
