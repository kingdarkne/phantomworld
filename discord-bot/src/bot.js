require('../env.loader');
const { Client, GatewayIntentBits, EmbedBuilder, Partials } = require('discord.js');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildVoiceStates,
        GatewayIntentBits.GuildMessageReactions,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.GuildEmojisAndStickers,
        GatewayIntentBits.GuildInvites,
        GatewayIntentBits.GuildPresences,
        GatewayIntentBits.DirectMessages,
        GatewayIntentBits.GuildModeration,
    ],
    partials: [
        Partials.Message,
        Partials.Channel,
        Partials.Reaction,
        Partials.User,
        Partials.GuildMember
    ]
});

// Emotes
client.emotes = {
    normal: {
        error: "❌",
        success: "✅",
        info: "ℹ️",
        tv: "📺",
        music: "🎵",
        clock: "🕒",
        volume: "🔊"
    }
};

// Core Functions
client.templateEmbed = function () {
    const embed = new EmbedBuilder()
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
        if (options.url) embed.setURL(options.url);
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
        console.error("[CORE] Embed reply error:", err.message);
    }
};

client.simpleEmbed = async function (options, interaction) {
    return client.embed(options, interaction);
};

client.errNormal = async function (options, interaction) {
    return client.embed({
        title: `${client.emotes.normal.error}・Error`,
        desc: options.error || options.text || "An unknown error occurred",
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

// Commands map
client.commands = new Map();

// Standardized Radio system (Shoukaku v4)
client.radio = require('./lib/radio.js');

// Standardized Player access (Shoukaku v4)
client.player = {
    // Legacy support for client.player.players.get()
    players: {
        get: (id) => client.shoukaku?.players.get(id)
    },
    get: (id) => client.shoukaku?.players.get(id),
    search: async (query, user) => {
        const node = client.shoukaku.getIdealNode();
        if (!node) throw new Error("No Lavalink node available.");
        const result = await node.rest.resolve(query);
        return {
            tracks: result?.data || result?.tracks || [],
            loadType: result?.loadType
        };
    }
};

client.on('ready', () => {
    console.log(`Bot is online as ${client.user.tag}`);
    console.log("[CORE] All functions are globally available and standardized on Shoukaku v4.");
});

module.exports = client;

// client.login() moved to index.js to ensure events are loaded first
