const Discord = require("discord.js");

module.exports = async (client, member) => {
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
