const { EmbedBuilder } = require('discord.js');
const { panelUrl } = require('../../lib/panel-api');

module.exports = async (client, interaction) => {
  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle('Phantom Hosting — Rex admin')
    .setDescription(
      [
        `Panel: ${panelUrl()}`,
        'Billing: https://billing.phantom-chicken.com',
        '',
        '**Owner-only** commands (use from your phone when you cannot open the panel):',
        '',
        '`/hosting user` — list / find / create / password / delete panel users',
        '`/hosting server` — list / info / create / delete / suspend / unsuspend / power / move',
        '`/hosting plans` — billing plan ids for create',
        '`/hosting billing` — clients, servers, invoices from billing DB',
        '`/hosting logs` — server status + recent invoices',
        '',
        'Passwords are shown **ephemerally** (only you can see them).',
        'Destructive actions (delete) permanently remove panel servers.',
      ].join('\n'),
    )
    .setTimestamp();

  return interaction.editReply({ embeds: [embed] });
};
