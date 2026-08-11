module.exports = async (client, interaction) => {
    const available = client.isMusicServiceAvailable();

    const lines = [
        '`/music play` — Search and play a song',
        '`/music pause` · `/music resume` · `/music stop`',
        '`/music skip` · `/music previous` · `/music queue`',
        '`/music shuffle` · `/music loop` · `/music volume`',
        '`/music lyrics` · `/music bassboost` · `/music seek`',
    ];

    const embed = client.templateEmbed()
        .setTitle('🎵 Music commands')
        .setDescription(lines.join('\n'));

    if (!available) {
        embed.addFields({
            name: 'Status',
            value:
                '**Coming soon** — Lavalink on the Phantom World VPS is not set up yet. Playback commands will show a friendly notice until staff enable it.',
        });
        embed.setColor(client.config.colors.error);
    } else {
        embed.setColor(client.config.colors.normal);
    }

    return client.embed({
        embeds: [embed],
        type: 'editreply',
    }, interaction);
};
