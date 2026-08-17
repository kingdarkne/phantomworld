const Discord = require("discord.js");
const { sendLeaveFeedbackDm } = require("../../lib/member-lifecycle-dm");

module.exports = async (client, member) => {
    // Ask why they left (dropdown + optional feedback). Best-effort — DMs may fail if closed.
    sendLeaveFeedbackDm(client, member).catch((err) => {
        console.warn("[guildMemberRemove] leave DM error:", err.message);
    });

    // Server logging for member removals
    const serverlog = new Discord.WebhookClient({
        id: client.webhooks.serverLogs.id,
        token: client.webhooks.serverLogs.token,
    });

    let embedLogs = new Discord.EmbedBuilder()
        .setTitle(`📤 Member Left`)
        .setDescription(`${member.user.tag} (${member.user.id}) has left the server.`)
        .setColor(client.config.colors.error)
        .setTimestamp();

    serverlog.send({
        username: "Server Logs",
        embeds: [embedLogs],
    }).catch(() => {});
};
