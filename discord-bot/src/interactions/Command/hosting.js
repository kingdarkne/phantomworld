const { SlashCommandBuilder } = require('discord.js');
const { requireHostingAdmin } = require('../../lib/hosting-auth');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('hosting')
    .setDescription('Phantom Hosting panel admin (owner only)')
    .addSubcommand((sub) =>
      sub.setName('help').setDescription('Show hosting admin commands'),
    )
    .addSubcommand((sub) =>
      sub
        .setName('user')
        .setDescription('Panel users: list / find / create / password / delete')
        .addStringOption((opt) =>
          opt
            .setName('action')
            .setDescription('What to do')
            .setRequired(true)
            .addChoices(
              { name: 'list', value: 'list' },
              { name: 'find', value: 'find' },
              { name: 'create', value: 'create' },
              { name: 'password', value: 'password' },
              { name: 'delete', value: 'delete' },
            ),
        )
        .addStringOption((opt) =>
          opt.setName('email').setDescription('User email (find/create/password/delete)'),
        )
        .addStringOption((opt) =>
          opt.setName('password').setDescription('Optional password (create/password)'),
        )
        .addIntegerOption((opt) =>
          opt.setName('id').setDescription('Panel user id (password/delete)'),
        ),
    )
    .addSubcommand((sub) =>
      sub
        .setName('server')
        .setDescription('Servers: list / info / create / delete / suspend / power / move')
        .addStringOption((opt) =>
          opt
            .setName('action')
            .setDescription('What to do')
            .setRequired(true)
            .addChoices(
              { name: 'list', value: 'list' },
              { name: 'info', value: 'info' },
              { name: 'create', value: 'create' },
              { name: 'delete', value: 'delete' },
              { name: 'suspend', value: 'suspend' },
              { name: 'unsuspend', value: 'unsuspend' },
              { name: 'power', value: 'power' },
              { name: 'move', value: 'move' },
            ),
        )
        .addStringOption((opt) =>
          opt.setName('target').setDescription('Server id, identifier, or name'),
        )
        .addStringOption((opt) =>
          opt.setName('email').setDescription('Owner email (create/move)'),
        )
        .addStringOption((opt) =>
          opt.setName('name').setDescription('Server name (create)'),
        )
        .addIntegerOption((opt) =>
          opt.setName('plan').setDescription('Billing plan id (create) — use /hosting plans'),
        )
        .addStringOption((opt) =>
          opt.setName('egg').setDescription('Optional nest:egg e.g. 6:16 (create)'),
        )
        .addIntegerOption((opt) =>
          opt.setName('node').setDescription('Optional node id (create)'),
        )
        .addStringOption((opt) =>
          opt
            .setName('signal')
            .setDescription('Power signal (power action)')
            .addChoices(
              { name: 'start', value: 'start' },
              { name: 'stop', value: 'stop' },
              { name: 'restart', value: 'restart' },
              { name: 'kill', value: 'kill' },
            ),
        ),
    )
    .addSubcommand((sub) =>
      sub.setName('plans').setDescription('List billing hosting plans'),
    )
    .addSubcommand((sub) =>
      sub
        .setName('billing')
        .setDescription('Billing DB clients / servers / invoices')
        .addStringOption((opt) =>
          opt
            .setName('view')
            .setDescription('What to show')
            .setRequired(true)
            .addChoices(
              { name: 'clients', value: 'clients' },
              { name: 'servers', value: 'servers' },
              { name: 'invoices', value: 'invoices' },
            ),
        )
        .addStringOption((opt) =>
          opt.setName('email').setDescription('Filter by client email'),
        ),
    )
    .addSubcommand((sub) =>
      sub
        .setName('logs')
        .setDescription('Show server status + recent billing activity')
        .addStringOption((opt) =>
          opt.setName('target').setDescription('Server id or identifier').setRequired(true),
        ),
    ),

  run: async (client, interaction) => {
    if (!(await requireHostingAdmin(client, interaction))) return;
    // Always ephemeral — may include panel passwords / customer emails.
    await interaction.deferReply({ ephemeral: true });
    client.loadSubcommands(client, interaction);
  },
};
