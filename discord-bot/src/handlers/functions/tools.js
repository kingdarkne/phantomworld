const Discord = require('discord.js');

module.exports = (client) => {
    console.log("[TOOLS] Loading core functions...");

    // Define emotes if missing
    if (!client.emotes) client.emotes = {};
    if (!client.emotes.normal) {
        client.emotes.normal = {
            error: "❌",
            success: "✅",
            tv: "📺"
        };
    }

    client.templateEmbed = function () {
        const embed = new Discord.EmbedBuilder()
            .setColor(client.config?.colors?.normal || "#5865F2")
            .setTimestamp();
        
        const footerText = client.config?.discord?.footer || "Phantom World";
        if (client.user) {
            embed.setFooter({ 
                text: footerText, 
                iconURL: client.user.displayAvatarURL() 
            });
        } else {
            embed.setFooter({ text: footerText });
        }
        return embed;
    };

    client.embed = async function (options, interaction) {
        const type = options.type || 'reply';
        const content = options.content || null;
        const embeds = options.embeds || [];
        const components = options.components || [];

        if (options.title || options.desc || options.fields) {
            const embed = client.templateEmbed();
            if (options.title) embed.setTitle(options.title);
            if (options.desc) embed.setDescription(options.desc);
            if (options.color) embed.setColor(options.color);
            if (options.fields) embed.addFields(options.fields);
            if (options.image) embed.setImage(options.image);
            if (options.thumb) embed.setThumbnail(options.thumb);
            embeds.push(embed);
        }

        const data = {
            content: content,
            embeds: embeds,
            components: components,
            fetchReply: true
        };

        try {
            if (type === 'reply') {
                if (interaction.deferred || interaction.replied) {
                    return await interaction.editReply(data);
                } else {
                    return await interaction.reply(data);
                }
            } else if (type === 'editreply') {
                return await interaction.editReply(data);
            } else if (type === 'ephemeral') {
                data.ephemeral = true;
                if (interaction.deferred || interaction.replied) {
                    return await interaction.editReply(data);
                } else {
                    return await interaction.reply(data);
                }
            }
        } catch (err) {
            console.error("[TOOLS] Embed reply error:", err.message);
        }
    };

    // Explicitly define simpleEmbed
    client.simpleEmbed = async function (options, interaction) {
        return client.embed(options, interaction);
    };

    client.errNormal = async function (options, interaction) {
        return client.embed({
            title: `${client.emotes.normal.error}・Error`,
            desc: options.error || "An unknown error occurred",
            color: client.config?.colors?.error || "#ED4245",
            type: options.type || 'ephemeral'
        }, interaction);
    };

    client.succNormal = async function (options, interaction) {
        return client.embed({
            title: `${client.emotes.normal.success}・Success`,
            desc: options.text || "Operation successful",
            color: client.config?.colors?.success || "#57F287",
            type: options.type || 'reply'
        }, interaction);
    };

    console.log("[TOOLS] Core functions loaded: client.embed, client.simpleEmbed, client.errNormal, client.succNormal");
};
