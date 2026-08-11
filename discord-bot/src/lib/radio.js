module.exports = {
    async startRadio(client, guildId, channelId, radioUrl) {
        console.log(`[RADIO] Starting radio for guild ${guildId} with URL: ${radioUrl}`);
        // DEBUG: Track radio execution
        console.log(`[RADIO] Executing startRadio for guild: ${guildId}`);
        
        if (!client.shoukaku) {
            throw new Error("Shoukaku is not initialized.");
        }
        
        const node = client.shoukaku.getIdealNode();
        if (!node) throw new Error("No Lavalink node available.");

        let player = client.shoukaku.players.get(guildId);
        
        if (!player) {
            try {
                player = await client.shoukaku.joinVoiceChannel({
                    guildId,
                    channelId,
                    shardId: client.guilds.cache.get(guildId)?.shardId || 0,
                    deaf: false
                });
                console.log(`[RADIO] New connection established.`);
            } catch (err) {
                console.error(`[RADIO] Join failed:`, err.message);
                throw err;
            }
        }

        // Standardized Resolution for Lavalink v4
        console.log(`[RADIO] Resolving: ${radioUrl}`);
        let result;
        try {
            // Set a timeout for the resolve operation to prevent hangs
            result = await Promise.race([
                node.rest.resolve(radioUrl),
                new Promise((_, reject) => setTimeout(() => reject(new Error("Resolution timeout (10s)")), 10000))
            ]);
        } catch (e) {
            console.error(`[RADIO] Resolve error:`, e.message);
        }
        
        let track;
        if (result) {
            // Lavalink v4 response structure
            if (result.loadType === 'track') track = result.data;
            else if (result.loadType === 'playlist') track = result.data.tracks[0];
            else if (result.loadType === 'search') track = result.data[0];
            else if (result.data && result.data.encoded) track = result.data;
        }

        // Fallback: If direct resolution fails, search YouTube
        if (!track) {
            console.log(`[RADIO] Direct link failed, searching YouTube...`);
            try {
                const ytSearch = await node.rest.resolve(`ytsearch:${radioUrl}`);
                if (ytSearch?.data?.[0]) track = ytSearch.data[0];
            } catch (searchErr) {
                console.error(`[RADIO] YouTube search fallback failed:`, searchErr.message);
            }
        }

        if (!track) throw new Error(`Radio stream could not be resolved.`);

        try {
            console.log(`[RADIO] Sending playTrack...`);
            // FIXED: Shoukaku v4 playTrack payload must be an object with an 'encoded' field
            // The previous code was sending the encoded string directly which Lavalink v4 rejects
            const encodedTrack = track.encoded || track.track || (typeof track === 'string' ? track : null);
            
            if (!encodedTrack) throw new Error("Could not find encoded track data.");

            await player.playTrack({ 
                track: { 
                    encoded: encodedTrack 
                } 
            });
            console.log(`[RADIO] Playback started.`);
        } catch (playError) {
            console.error(`[RADIO] PlayTrack failed:`, playError);
            throw new Error(`Failed to play the radio stream: ${playError.message}`);
        }

        return player;
    },

    async stopRadio(client, guildId) {
        if (!client.shoukaku) return;
        try {
            await client.shoukaku.leaveVoiceChannel(guildId);
        } catch (err) {
            console.error(`[RADIO] Stop failed:`, err.message);
        }
    }
};
