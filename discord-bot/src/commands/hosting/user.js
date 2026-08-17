const { EmbedBuilder } = require('discord.js');
const panel = require('../../lib/panel-api');
const billing = require('../../lib/billing-db');

module.exports = async (client, interaction) => {
  const action = interaction.options.getString('action');
  const email = interaction.options.getString('email');
  const passwordOpt = interaction.options.getString('password');
  const idOpt = interaction.options.getInteger('id');

  try {
    if (action === 'list') {
      const data = await panel.listUsers({ perPage: 25 });
      const lines = (data.data || []).slice(0, 20).map((u) => {
        const a = u.attributes;
        return `\`${a.id}\` ${a.email} (@${a.username})${a.root_admin ? ' **ADMIN**' : ''}`;
      });
      const embed = new EmbedBuilder()
        .setColor(0x3b82f6)
        .setTitle('Panel users')
        .setDescription(lines.join('\n') || 'No users')
        .setFooter({ text: `Total page size ${data.data?.length || 0}` });
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'find') {
      if (!email) throw new Error('email is required for find');
      const user = await panel.findUserByEmail(email);
      if (!user) throw new Error(`No panel user for ${email}`);
      const a = user.attributes;
      let billingNote = '';
      if (billing.billingConfigured()) {
        const c = await billing.getClientByEmail(email);
        if (c) {
          billingNote = `\nBilling client #${c.id} · panel link user_id=${c.user_id || 'none'} · credit=${c.credit}`;
        }
      }
      const embed = new EmbedBuilder()
        .setColor(0x3b82f6)
        .setTitle(`User ${a.email}`)
        .setDescription(
          [
            `**ID:** ${a.id}`,
            `**Username:** ${a.username}`,
            `**Name:** ${a.first_name} ${a.last_name}`,
            `**Root admin:** ${a.root_admin ? 'yes' : 'no'}`,
            `**2FA:** ${a['2fa'] ? 'yes' : 'no'}`,
            billingNote,
            `[Open panel](${panel.panelUrl()}/admin/users/view/${a.id})`,
          ]
            .filter(Boolean)
            .join('\n'),
        );
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'create') {
      if (!email) throw new Error('email is required for create');
      const existing = await panel.findUserByEmail(email);
      if (existing) throw new Error(`Panel user already exists (id ${existing.attributes.id})`);
      const password = passwordOpt || panel.randomPassword(16);
      const username = panel.sanitizeUsername(email);
      const created = await panel.createUser({
        email,
        username,
        firstName: email.split('@')[0].slice(0, 20) || 'Customer',
        lastName: 'User',
        password,
        rootAdmin: false,
      });
      const a = created.attributes;
      if (billing.billingConfigured()) {
        const c = await billing.getClientByEmail(email);
        if (c && !c.user_id) {
          await billing.linkClientPanelUser(c.id, a.id);
        }
      }
      const embed = new EmbedBuilder()
        .setColor(0x22c55e)
        .setTitle('Panel user created')
        .setDescription(
          [
            `**Email:** ${a.email}`,
            `**Username:** ${a.username}`,
            `**ID:** ${a.id}`,
            `**Password:** \`${password}\``,
            '',
            'Save this password — it is only shown once here.',
          ].join('\n'),
        );
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'password') {
      let userId = idOpt;
      if (!userId) {
        if (!email) throw new Error('email or id is required');
        const user = await panel.findUserByEmail(email);
        if (!user) throw new Error(`No panel user for ${email}`);
        userId = user.attributes.id;
      }
      const full = await panel.getUser(userId);
      const a = full.attributes;
      if (a.root_admin) throw new Error('Refusing to reset password on a root_admin account');
      const password = passwordOpt || panel.randomPassword(16);
      await panel.updateUser(userId, {
        email: a.email,
        username: a.username,
        first_name: a.first_name,
        last_name: a.last_name,
        password,
      });
      const embed = new EmbedBuilder()
        .setColor(0xf59e0b)
        .setTitle('Password reset')
        .setDescription(
          [
            `**User:** ${a.email} (\`${a.id}\`)`,
            `**New password:** \`${password}\``,
            '',
            'Shown only to you (ephemeral).',
          ].join('\n'),
        );
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'delete') {
      let userId = idOpt;
      if (!userId) {
        if (!email) throw new Error('email or id is required');
        const user = await panel.findUserByEmail(email);
        if (!user) throw new Error(`No panel user for ${email}`);
        userId = user.attributes.id;
      }
      const full = await panel.getUser(userId);
      if (full.attributes.root_admin) throw new Error('Refusing to delete root_admin');
      await panel.deleteUser(userId);
      return interaction.editReply({
        content: `Deleted panel user **${full.attributes.email}** (\`${userId}\`).`,
      });
    }

    throw new Error(`Unknown action: ${action}`);
  } catch (err) {
    return client.errNormal(
      { error: err.message || String(err), type: 'editreply' },
      interaction,
    );
  }
};
