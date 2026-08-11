const {
    isMusicServiceAvailable,
    getMusicUnavailableReason,
} = require('../../lib/vps-services');

module.exports = (client) => {
    client.isMusicServiceAvailable = () => isMusicServiceAvailable(client);

    /**
     * Reply with a friendly embed when music/Lavalink is not ready.
     * @returns {Promise<boolean>} true if the interaction was handled (caller should stop).
     */
    client.ensureMusicAvailable = async function (interaction) {
        if (isMusicServiceAvailable(client)) return false;

        const reason = getMusicUnavailableReason(client);
        const embed = client.templateEmbed();

        if (reason === 'not_connected') {
            embed
                .setTitle('🎵 Music server offline')
                .setDescription(
                    'Lavalink on the Phantom World VPS is enabled but **not connected** right now.\n\n' +
                        'The bot cannot search or play songs until Lavalink is running and reachable. Try again in a few minutes.'
                )
                .addFields({
                    name: 'Staff',
                    value:
                        'Check Lavalink on the VPS, firewall/tunnel, and `LAVALINK_HOST` / `LAVALINK_PASSWORD` on KataBump.',
                });
        } else {
            embed
                .setTitle('🎵 Music — coming soon')
                .setDescription(
                    'Phantom World music uses **self-hosted Lavalink** on our VPS. That is **not set up yet**, so song search and playback are temporarily disabled.'
                )
                .addFields(
                    {
                        name: 'Still works',
                        value: 'Moderation, tickets, games, economy, `/radio`, soundboard, and everything else.',
                    },
                    {
                        name: 'When the VPS is ready',
                        value:
                            'Staff will run Lavalink on the VPS and set `LAVALINK_SELF_HOST=true` plus host, port, and password on the bot host.',
                    }
                );
        }

        embed.setColor(client.config.colors.error);

        await client.embed({
            embeds: [embed],
            type: 'editreply',
        }, interaction);

        return true;
    };
};
