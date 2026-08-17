const Discord = require('discord.js');
const roleSchema = require("../../database/models/joinRole");

function findMemberRole(guild) {
    return (
        guild.roles.cache.find((r) => /^member$/i.test(r.name)) ||
        guild.roles.cache.find((r) => /^members$/i.test(r.name)) ||
        guild.roles.cache.find((r) => /member/i.test(r.name) && !/staff|mod|admin|bot/i.test(r.name))
    );
}

module.exports = async (client, member) => {
    if (member.user.bot) return;

    // Configured welcome/join role (do not abort the rest of the handler if missing)
    try {
        const data = await roleSchema.findOne({ Guild: member.guild.id });
        if (data?.Role) {
            const role = member.guild.roles.cache.get(data.Role);
            if (role) member.roles.add(role).catch(() => {});
        }
    } catch (_) {}

    // Always try to apply the Member role
    try {
        const memberRole = findMemberRole(member.guild);
        if (memberRole && !member.roles.cache.has(memberRole.id)) {
            await member.roles.add(memberRole, 'Auto Member role').catch(() => {});
        }
    } catch (_) {}

    // Welcome DM when available
    try {
        const { sendWelcomeDm } = require('../../lib/member-lifecycle-dm');
        sendWelcomeDm(client, member).catch(() => {});
    } catch (_) {}

    // Server logging for member adds
    try {
        const serverlog = new Discord.WebhookClient({
            id: client.webhooks.serverLogs.id,
            token: client.webhooks.serverLogs.token,
        });

        let embedLogs = new Discord.EmbedBuilder()
            .setTitle(`📥 Member Joined`)
            .setDescription(`${member.user.tag} (${member.user.id}) has joined the server.`)
            .setColor(client.config.colors.success)
            .setTimestamp();

        serverlog.send({
            username: "Server Logs",
            embeds: [embedLogs],
        }).catch(() => {});
    } catch (_) {}
};
