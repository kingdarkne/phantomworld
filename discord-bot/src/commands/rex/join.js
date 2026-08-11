const { rexJoinListen } = require('../../lib/rex-listen.cjs');

module.exports = async (client, interaction) => {
  if (!interaction.deferred && !interaction.replied) {
    await interaction.deferReply().catch(() => {});
  }

  try {
    const result = await rexJoinListen(client, interaction);

    return client.embed(
      {
        title: `🤖・Rex is Listening`,
        desc:
          `Rex has joined <#${result.channelId}>!\n\n` +
          `Say **"Hey Rex"** + your question.\n` +
          `_Example: "Hey Rex, how do I join the server?"_`,
        fields: [
          { name: 'Wake Word', value: `\`Hey Rex\``, inline: true },
          { name: 'Tip', value: 'Speak clearly after the wake word', inline: true },
        ],
        type: 'editreply',
      },
      interaction,
    );
  } catch (err) {
    console.error('[Rex Join] Error:', err.message);
    return client.errNormal(
      {
        error: err.message || 'Rex failed to join. Try again in a moment.',
        type: 'editreply',
      },
      interaction,
    );
  }
};
