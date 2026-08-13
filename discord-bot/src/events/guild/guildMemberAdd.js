const Discord = require('discord.js');
const roleSchema = require("../../database/models/joinRole");

module.exports = async (client, member) => {
    try {
        const data = await roleSchema.findOne({ Guild: member.guild.id });
        if (data) {
            const role = member.guild.roles.cache.get(data.Role);
            if (role) {
                await member.roles.add(role).catch(() => {});
            }
        }
    } catch (err) {
        console.warn('[guildMemberAdd] join role failed:', err?.message || err);
    }

    try {
        const wh = client.webhooks?.serverLogs;
        if (!wh?.id || !wh?.token || wh.token === 'REPLACE_ME') return;

        const serverlog = new Discord.WebhookClient({
            id: wh.id,
            token: wh.token,
        });

        const embedLogs = new Discord.EmbedBuilder()
            .setTitle(`📥 Member Joined`)
            .setDescription(`${member.user.tag} (${member.user.id}) has joined the server.`)
            .setColor(client.config?.colors?.success || 0x57F287)
            .setTimestamp();

        await serverlog.send({
            username: "Server Logs",
            embeds: [embedLogs],
        }).catch(() => {});
    } catch (err) {
        console.warn('[guildMemberAdd] webhook failed:', err?.message || err);
    }
};
