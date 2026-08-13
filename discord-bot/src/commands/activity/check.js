const Discord = require('discord.js');
const ActivityCheck = require("../../database/models/activityCheck");

module.exports = async (client, interaction, args) => {
    // Only bot owner/developers should run this.
    // Assuming you are the one who provided the credentials, I'll use your ID if I can find it, 
    // or check against a list in config. For now, let's check if the user has Administrator in a specific "Control" guild if applicable,
    // but better to use a hardcoded ID or config.
    
    const authorizedIds = ["854163109584044054", "413173364216168449"];
    if (!authorizedIds.includes(interaction.user.id)) {
        return client.errNormal({
            error: "Only the bot developer can run this command!",
            type: 'editreply'
        }, interaction);
    }

    const guilds = client.guilds.cache;
    let sentCount = 0;

    for (const [guildId, guild] of guilds) {
        try {
            const owner = await guild.fetchOwner();
            
            // Update or create record
            await ActivityCheck.findOneAndUpdate(
                { Guild: guildId },
                { Owner: owner.id, Status: 'Pending', LastCheck: new Date() },
                { upsert: true }
            );

            const embed = new Discord.EmbedBuilder()
                .setTitle("📢 Server Activity Check")
                .setDescription(`Hello! We are checking if **${guild.name}** is still active. Please reply with \`active\` to this DM to confirm.`)
                .setColor("#5865F2")
                .setFooter({ text: "If no reply is received, the bot may leave the server." });

            await owner.send({ embeds: [embed] });
            sentCount++;
        } catch (err) {
            console.error(`[ACTIVITY] Failed to DM owner of ${guild.name}:`, err.message);
        }
    }

    client.succNormal({
        text: `Started activity check for **${guilds.size}** servers. Successfully sent DMs to **${sentCount}** owners.`,
        type: 'editreply'
    }, interaction);
};
