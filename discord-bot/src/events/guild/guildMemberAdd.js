const Discord = require('discord.js');
const roleSchema = require("../../database/models/joinRole");
const { findMemberRole } = require('../../lib/ensure-staff-roles');

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

    // Always try to apply Phantom Civilian (and strip legacy Member)
    try {
        const memberRole = findMemberRole(member.guild);
        const legacy = member.guild.roles.cache.find((r) => /^member$/i.test(r.name) && r.id !== memberRole?.id);
        if (legacy && member.roles.cache.has(legacy.id)) {
            await member.roles.remove(legacy, 'Auto: strip legacy Member').catch(() => {});
        }
        if (memberRole && !member.roles.cache.has(memberRole.id)) {
            await member.roles.add(memberRole, 'Auto Phantom Civilian').catch(() => {});
        }
    } catch (_) {}

    // Welcome DM when available
    try {
        const { sendWelcomeDm } = require('../../lib/member-lifecycle-dm');
        sendWelcomeDm(client, member).catch(() => {});
    } catch (_) {}

    // Unbanned users who could not be DMed (no mutual guild) — welcome on rejoin
    try {
        const { deliverPendingWelcomeOnJoin } = require('../../lib/unban-welcome');
        deliverPendingWelcomeOnJoin(member).catch(() => {});
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
