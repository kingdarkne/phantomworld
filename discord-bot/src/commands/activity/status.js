const Discord = require('discord.js');
const ActivityCheck = require("../../database/models/activityCheck");

module.exports = async (client, interaction, args) => {
    const authorizedIds = ["854163109584044054", "413173364216168449"];
    if (!authorizedIds.includes(interaction.user.id)) {
        return client.errNormal({
            error: "Only the bot developer can run this command!",
            type: 'editreply'
        }, interaction);
    }

    const checks = await ActivityCheck.find({});
    
    if (checks.length === 0) {
        return client.errNormal({
            error: "No activity checks have been started yet.",
            type: 'editreply'
        }, interaction);
    }

    let statusList = checks.map(c => {
        const guild = client.guilds.cache.get(c.Guild);
        const name = guild ? guild.name : `Unknown (${c.Guild})`;
        const statusEmoji = c.Status === 'Active' ? '✅' : (c.Status === 'Pending' ? '⏳' : '❌');
        return `${statusEmoji} **${name}**: ${c.Status}`;
    }).join('\n');

    // Split if too long
    if (statusList.length > 2000) statusList = statusList.substring(0, 1990) + "...";

    const embed = new Discord.EmbedBuilder()
        .setTitle("📊 Activity Check Status")
        .setDescription(statusList || "No data available")
        .setColor("#5865F2")
        .setTimestamp();

    interaction.editReply({ embeds: [embed] });
};
