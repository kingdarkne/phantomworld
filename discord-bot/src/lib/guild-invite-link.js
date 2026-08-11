const { ChannelType } = require('discord.js');

/**
 * Get or create a permanent join link for a guild.
 * @param {import('discord.js').Guild} guild 
 * @returns {Promise<string|null>}
 */
async function getGuildJoinLink(guild) {
    try {
        // 1. Try to find an existing vanity URL
        if (guild.vanityURLCode) return `https://discord.gg/${guild.vanityURLCode}`;

        // 2. Try to find an existing permanent invite in cache
        const invites = await guild.invites.fetch().catch(() => null);
        if (invites) {
            const permanent = invites.find(i => !i.expiresAt && !i.temporary);
            if (permanent) return permanent.url;
        }

        // 3. Try to create a new one in a public channel
        const channel = guild.channels.cache.find(c => 
            c.type === ChannelType.GuildText && 
            guild.members.me.permissionsIn(c).has(['CreateInstantInvite', 'ViewChannel'])
        );

        if (channel) {
            const invite = await channel.createInvite({
                maxAge: 0, // permanent
                maxUses: 0,
                unique: false,
                reason: 'Bot Server List Request'
            }).catch(() => null);

            if (invite) return invite.url;
        }

        return null;
    } catch (err) {
        return null;
    }
}

module.exports = { getGuildJoinLink };
