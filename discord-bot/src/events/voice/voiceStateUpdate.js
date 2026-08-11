const Discord = require('discord.js');
const voiceSchema = require("../../database/models/voice");
const channelSchema = require("../../database/models/voiceChannels");

module.exports = (client, oldState, newState) => {
    // Check if the user only changed mute/deaf state
    if (oldState.channelId === newState.channelId) {
        if (oldState.selfDeaf !== newState.selfDeaf) return;
        if (oldState.selfMute !== newState.selfMute) return;
        if (oldState.serverDeaf !== newState.serverDeaf) return;
        if (oldState.serverMute !== newState.serverMute) return;
        if (oldState.selfVideo !== newState.selfVideo) return;
        if (oldState.streaming !== newState.streaming) return;
    }

    const guildId = newState.guild.id || oldState.guild.id;

    voiceSchema.findOne({ Guild: guildId }, async (err, data) => {
        if (err) return console.error("[VOICE] DB Error:", err);
        if (!data) return;

        // Handling user leaving a channel
        if (oldState.channelId) {
            channelSchema.findOne({ Guild: guildId, Channel: oldState.channelId }, async (err, data2) => {
                if (data2) {
                    const channel = client.channels.cache.get(data2.Channel);
                    if (channel) {
                        const memberCount = channel.members.size;
                        if (memberCount === 0) {
                            if (data.ChannelCount > 0) {
                                data.ChannelCount -= 1;
                                await data.save().catch(() => {});
                            }
                            await channelSchema.deleteOne({ Channel: oldState.channelId }).catch(() => {});
                            await channel.delete().catch(() => {});
                        }
                    }
                }
            });
        }

        // Handling user joining the "Join to Create" channel
        if (newState.channelId === data.Channel) {
            const user = await client.users.fetch(newState.id);
            const member = newState.guild.members.cache.get(user.id);
            if (!member) return;

            if (data.ChannelCount) {
                data.ChannelCount += 1;
            } else {
                data.ChannelCount = 1;
            }
            await data.save();

            let channelName = data.ChannelName || "{emoji} {member}'s Channel";
            channelName = channelName.replace(`{emoji}`, "🔊")
                .replace(`{channel name}`, `Voice ${data.ChannelCount}`)
                .replace(`{channel count}`, `${data.ChannelCount}`)
                .replace(`{member}`, user.username)
                .replace(`{member tag}`, user.tag);

            try {
                const channel = await newState.guild.channels.create({
                    name: channelName,
                    type: Discord.ChannelType.GuildVoice,
                    parent: data.Category || null,
                });

                await member.voice.setChannel(channel);

                await new channelSchema({
                    Guild: guildId,
                    Channel: channel.id,
                }).save();
            } catch (createErr) {
                console.error("[VOICE] Error creating channel:", createErr);
            }
        }
    });
};
