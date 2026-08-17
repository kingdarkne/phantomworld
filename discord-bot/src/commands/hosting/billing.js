const { EmbedBuilder } = require('discord.js');
const billing = require('../../lib/billing-db');

module.exports = async (client, interaction) => {
  const view = interaction.options.getString('view');
  const email = interaction.options.getString('email');

  try {
    if (!billing.billingConfigured()) {
      throw new Error('BILLING_DB_* is not configured on Rex');
    }

    if (view === 'clients') {
      const rows = await billing.listClients({ limit: 20, email: email || undefined });
      const lines = rows.map(
        (c) =>
          `\`${c.id}\` ${c.email} · panel=${c.user_id || '—'} · $${Number(c.credit).toFixed(2)} · ${c.is_active ? 'active' : 'off'}`,
      );
      return interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x3b82f6)
            .setTitle('Billing clients')
            .setDescription(lines.join('\n') || 'No clients'),
        ],
      });
    }

    if (view === 'servers') {
      let clientId;
      if (email) {
        const c = await billing.getClientByEmail(email);
        if (!c) throw new Error(`No billing client for ${email}`);
        clientId = c.id;
      }
      const rows = await billing.listBillingServers({ limit: 25, clientId });
      const lines = rows.map(
        (s) =>
          `\`${s.id}\` ${s.server_name} · panel=${s.server_id || '—'} \`${s.identifier || '—'}\` · client ${s.client_id} · status ${s.status}`,
      );
      return interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x3b82f6)
            .setTitle('Billing servers')
            .setDescription(lines.join('\n') || 'No servers'),
        ],
      });
    }

    if (view === 'invoices') {
      let clientId;
      if (email) {
        const c = await billing.getClientByEmail(email);
        if (!c) throw new Error(`No billing client for ${email}`);
        clientId = c.id;
      }
      const rows = await billing.listRecentInvoices({ limit: 20, clientId });
      const lines = rows.map(
        (i) =>
          `\`${i.id}\` client ${i.client_id} · $${Number(i.total).toFixed(2)} · ${i.paid ? 'PAID' : 'UNPAID'} · ${i.due_date || 'no due'}`,
      );
      return interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xf59e0b)
            .setTitle('Recent invoices')
            .setDescription(lines.join('\n') || 'No invoices'),
        ],
      });
    }

    throw new Error(`Unknown view: ${view}`);
  } catch (err) {
    return client.errNormal(
      { error: err.message || String(err), type: 'editreply' },
      interaction,
    );
  }
};
