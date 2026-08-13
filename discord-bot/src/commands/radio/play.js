const Discord = require('discord.js');
const Schema = require("../../database/models/music");

module.exports = async (client, interaction, args) => {
    // Ensure the interaction is deferred if it hasn't been already
    if (!interaction.deferred && !interaction.replied) {
        if (!interaction.deferred && !interaction.replied) await interaction.deferReply().catch(() => {});
    }

    let channel = interaction.member.voice?.channel;
    if (!channel) return client.errNormal({ text: `You're not in a voice channel!`, type: 'editreply' }, interaction);

    // Using a direct audio stream URL which is much more likely to be resolved by Lavalink than YouTube
    const radioUrl = "http://icecast.radiofrance.fr/fip-midfi.mp3"; // FIP Radio (Direct Stream)
    const radioName = "FIP Radio";
    const radioWebsite = "https://www.radiofrance.fr/fip";

    try {
        // Start radio using Shoukaku
        await client.radio.startRadio(
            client,
            interaction.guild.id,
            channel.id,
            radioUrl
        );

        // Save to DB
        try {
            const data = await Schema.findOne({ Guild: interaction.guild.id });
            if (data) {
                data.Channel = channel.id;
                await data.save();
            } else {
                await new Schema({
                    Guild: interaction.guild.id,
                    Channel: channel.id,
                }).save();
            }
        } catch (dbErr) {
            console.error("[RADIO] Database error:", dbErr.message);
        }

        client.embed({
            title: `📻・Started radio`,
            desc: `Radio has started successfully \nTo make the bot leave do: \`/radio stop\``,
            fields: [
                { name: "👤┆Started By", value: `${interaction.user}`, inline: true },
                { name: "📺┆Channel", value: `${channel}`, inline: true },
                { name: "🎶┆Radio Station", value: `[${radioName}](${radioWebsite})`, inline: true },
            ],
            type: 'editreply'
        }, interaction);

        // Webhook logging
        if (client.webhooks?.voiceLogs) {
            const webhookClientLogs = new Discord.WebhookClient({
                id: client.webhooks.voiceLogs.id,
                token: client.webhooks.voiceLogs.token,
            });

            let embed = new Discord.EmbedBuilder()
                .setTitle(`📻・Started radio`)
                .setDescription(`Radio has started successfully`)
                .addFields(
                    { name: "👤┆Started By", value: `${interaction.user}`, inline: true },
                    { name: "📺┆Channel", value: `${channel}`, inline: true },
                    { name: "⚙️┆Guild", value: `${interaction.guild.name}`, inline: true },
                )
                .setColor(client.config?.colors?.normal || "#5865F2")
                .setTimestamp();

            webhookClientLogs.send({ username: 'Bot Logs', embeds: [embed] }).catch(() => {});
        }
    } catch (error) {
        console.error("[RADIO] Error starting radio:", error);
        client.errNormal({
            error: `Failed to start radio: ${error.message}`,
            type: 'editreply'
        }, interaction);
    }
};
