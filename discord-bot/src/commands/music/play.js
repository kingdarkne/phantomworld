const Discord = require('discord.js');
const {
    normalizeLoadType,
    queueAndNotify,
    presentSearchPicker,
    isUrl,
    getEncodedString,
    performMultiPlatformSearch,
} = require('../../lib/music-search-picker');

module.exports = async (client, interaction, args) => {
    const channel = interaction.member.voice.channel;
    if (!channel) return client.errNormal({
        error: `You're not in a voice channel!`,
        type: 'editreply',
    }, interaction);

    if (!channel.joinable) return client.errNormal({
        error: `That channel isn\'t joinable`,
        type: 'editreply',
    }, interaction);

    // Get or create player using Shoukaku
    let player = client.shoukaku.players.get(interaction.guild.id);

    // Robust voice channel check
    if (player) {
        const botVoiceChannelId = player.voiceChannelIdId;
        if (botVoiceChannelId && channel.id !== botVoiceChannelId) {
            const botInChannel = interaction.guild.members.me.voice.channel;
            if (botInChannel && channel.id !== botInChannel.id) {
                return client.errNormal({
                    error: `You are not in the same voice channel!`,
                    type: 'editreply',
                }, interaction);
            }
        }
    }

    if (!player) {
        try {
            player = await client.shoukaku.joinVoiceChannel({
                guildId: interaction.guild.id,
                channelId: channel.id,
                shardId: interaction.guild.shardId || 0,
                deaf: true
            });
            
            if (!player.queue) {
                player.queue = {
                    current: null,
                    tracks: [],
                    add: function(track) {
                        if (Array.isArray(track)) this.tracks.push(...track);
                        else this.tracks.push(track);
                    }
                };
            }
        } catch (err) {
            console.error("[MUSIC] Join error:", err);
            return client.errNormal({
                error: `Could not join the voice channel.`,
                type: 'editreply',
            }, interaction);
        }
    }

    const rawQuery = interaction.options.getString('song');

    client.simpleEmbed({
        desc: `🔎┆Searching...`,
        type: 'editreply',
    }, interaction);

    try {
        const res = await performMultiPlatformSearch(client, interaction, rawQuery);
        
        if (!res) {
            return client.errNormal({
                error: `No music was found for your search on any platform.`,
                type: 'editreply',
            }, interaction);
        }

        const loadType = normalizeLoadType(res.loadType);
        const tracks = res.data || res.tracks;

        if (loadType === 'playlist') {
            const playlistTracks = tracks.tracks || tracks;
            player.queue.add(playlistTracks);
            
            if (!player.track) {
                const first = player.queue.tracks.shift();
                player.queue.current = first;
                const encodedStr = getEncodedString(first);
                if (encodedStr) {
                    // Shoukaku v4 requires: { track: { encoded: "base64string" } }
                    await player.playTrack({ track: { encoded: encodedStr } });
                }
            }
            
            await client.embed({
                title: `${client.emotes.normal.music}・Playlist`,
                desc: `Added **${playlistTracks.length}** tracks to the queue.`,
                type: 'editreply',
            }, interaction);
            return;
        }

        const textSearch = !isUrl(rawQuery);
        const shouldPick = textSearch && (tracks.length > 1);

        let track;
        if (loadType === 'search' || shouldPick) {
            track = await presentSearchPicker(client, interaction, player, res, 10);
            if (!track) return;
        } else {
            track = Array.isArray(tracks) ? tracks[0] : tracks;
        }

        track.requester = interaction.user;
        await queueAndNotify(client, interaction, player, track);

    } catch (searchErr) {
        console.error("[MUSIC] Search execution error:", searchErr);
        return client.errNormal({
            error: `An unexpected error occurred while searching.`,
            type: 'editreply',
        }, interaction);
    }
};
