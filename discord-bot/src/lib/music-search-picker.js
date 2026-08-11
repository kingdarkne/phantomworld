const Discord = require('discord.js');

function isUrl(query) {
    return /^https?:\/\//i.test(String(query || '').trim());
}

function normalizeLoadType(loadType) {
    const t = String(loadType || '').toLowerCase();
    if (t === 'error' || t === 'load_failed') return 'error';
    if (t === 'empty' || t === 'no_matches') return 'empty';
    if (t === 'playlist' || t === 'playlist_loaded') return 'playlist';
    if (t === 'search' || t === 'search_result') return 'search';
    if (t === 'track' || t === 'track_loaded') return 'track';
    return t;
}

function formatDuration(ms) {
    const sec = Math.max(0, Math.floor((Number(ms) || 0) / 1000));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${String(s).padStart(2, '0')}`;
}

/**
 * Resolve the encoded track string from a Lavalink track object.
 * Shoukaku v4 playTrack() expects: { track: { encoded: "..." } }
 * This helper extracts the raw base64 encoded string safely.
 */
function getEncodedString(trackObj) {
    if (!trackObj) return null;
    // If it's already a plain string (base64 encoded track), return it directly
    if (typeof trackObj === 'string') return trackObj;
    // Shoukaku v4 track object shape: { encoded: "...", info: {...} }
    if (typeof trackObj.encoded === 'string') return trackObj.encoded;
    // Legacy shape fallback
    if (typeof trackObj.track === 'string') return trackObj.track;
    return null;
}

async function queueAndNotify(client, interaction, player, track) {
    if (!player.queue) {
        player.queue = {
            current: null,
            tracks: [],
            add: function(t) {
                if (Array.isArray(t)) this.tracks.push(...t);
                else this.tracks.push(t);
            }
        };
    }

    player.queue.add(track);

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
        title: `${client.emotes.normal.music}・${track.info?.title || track.title || 'Music'}`,
        url: track.info?.uri || track.uri,
        desc: 'The song has been added to the queue!',
        fields: [
            { name: '👤┆Requested By', value: `${track.requester || interaction.user}`, inline: true },
            { name: '🎬┆Author', value: `${track.info?.author || track.author || 'Unknown'}`, inline: true },
        ],
        type: 'editreply',
    }, interaction);
}

async function presentSearchPicker(client, interaction, player, res, max = 10) {
    const tracks = (res.data || res.tracks || []).slice(0, max);
    if (!tracks.length) return null;

    const select = new Discord.StringSelectMenuBuilder()
        .setCustomId('phantom_music_search')
        .setPlaceholder('Choose a song…')
        .addOptions(
            tracks.map((track, idx) => ({
                label: (track.info?.title || track.title || 'Unknown').slice(0, 100),
                description: `${track.info?.author || track.author || 'Unknown'}`.slice(0, 100),
                value: String(idx),
            })),
        );

    const row = new Discord.ActionRowBuilder().addComponents(select);

    await client.embed({
        title: '🔍・Search results',
        desc: 'Please select a song from the menu below.',
        components: [row],
        type: 'editreply',
    }, interaction);

    try {
        const pick = await interaction.channel.awaitMessageComponent({ 
            filter: i => i.customId === 'phantom_music_search' && i.user.id === interaction.user.id, 
            time: 30000 
        });
        const index = Number(pick.values[0]);
        await pick.deferUpdate();
        
        await interaction.editReply({ components: [] }).catch(() => {});
        
        return tracks[index];
    } catch (e) {
        await interaction.editReply({ components: [] }).catch(() => {});
        return null;
    }
}

async function performMultiPlatformSearch(client, interaction, query) {
    const node = client.shoukaku.getIdealNode();
    if (!node) throw new Error("No music nodes available.");

    const isLink = isUrl(query);
    if (isLink) {
        const res = await node.rest.resolve(query);
        if (normalizeLoadType(res.loadType) !== 'empty' && normalizeLoadType(res.loadType) !== 'error') return res;
    }

    // Try YouTube Search
    console.log(`[MUSIC] Searching YouTube for: ${query}`);
    let res;
    try {
        res = await node.rest.resolve(`ytsearch:${query}`);
    } catch (e) {
        console.error(`[MUSIC] YouTube search error:`, e.message);
        res = { loadType: 'error' };
    }
    
    // Switch to SoundCloud if YouTube fails
    const type = normalizeLoadType(res?.loadType);
    if (type === 'empty' || type === 'error' || !res?.data?.length) {
        console.log(`[MUSIC] YouTube failed/empty, trying SoundCloud...`);
        try {
            res = await node.rest.resolve(`scsearch:${query}`);
        } catch (scErr) {
            console.error(`[MUSIC] SoundCloud search error:`, scErr.message);
            return null;
        }
    }

    return res;
}

module.exports = {
    isUrl,
    normalizeLoadType,
    formatDuration,
    getEncodedString,
    queueAndNotify,
    presentSearchPicker,
    performMultiPlatformSearch,
};
