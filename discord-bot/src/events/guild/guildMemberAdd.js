const Discord = require('discord.js');
const roleSchema = require("../../database/models/joinRole");
const { sendWelcomeDm } = require("../../lib/member-lifecycle-dm");

module.exports = async (client, member) => {
    const data = await roleSchema.findOne({ Guild: member.guild.id })
    if (data) {
        const role = member.guild.roles.cache.get(data.Role);
        if (role) {
            member.roles.add(role).catch(() => { });
        }
    }

    // Welcome ad + details via DM (skips bots; ignores closed DMs)
    sendWelcomeDm(client, member).catch((err) => {
        console.warn('[guildMemberAdd] welcome DM error:', err.message);
    });

    // Server logging for member adds
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
};
