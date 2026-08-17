const { EmbedBuilder } = require('discord.js');
const panel = require('../../lib/panel-api');
const billing = require('../../lib/billing-db');

module.exports = async (client, interaction) => {
  const target = interaction.options.getString('target');

  try {
    const data = await panel.findServer(target);
    const a = data.attributes;

    let resourcesLine = 'Resources: (client API unavailable)';
    try {
      const res = await panel.getClientServerResources(a.identifier);
      const r = res.attributes;
      resourcesLine = `**State:** ${r.current_state}\n**CPU:** ${r.resources?.cpu_absolute ?? '?'}%\n**Mem:** ${Math.round((r.resources?.memory_bytes || 0) / 1024 / 1024)}MB\n**Disk:** ${Math.round((r.resources?.disk_bytes || 0) / 1024 / 1024)}MB`;
    } catch (err) {
      resourcesLine = `Resources: ${err.message}`;
    }

    let billingBlock = '';
    if (billing.billingConfigured()) {
      const row = await billing.getBillingServer(a.identifier);
      if (row) {
        const clientRow = await billing.getClientById(row.client_id);
        const invoices = await billing.listRecentInvoices({
          limit: 5,
          clientId: row.client_id,
        });
        billingBlock = [
          '',
          '**Billing**',
          `Row #${row.id} · plan ${row.plan_id} · due ${row.due_date || '—'} · status ${row.status}`,
          clientRow ? `Client: ${clientRow.email} (#${clientRow.id})` : null,
          invoices.length
            ? invoices
                .map(
                  (i) =>
                    `· invoice #${i.id} $${Number(i.total).toFixed(2)} ${i.paid ? 'paid' : 'unpaid'}`,
                )
                .join('\n')
            : 'No invoices',
        ]
          .filter(Boolean)
          .join('\n');
      } else {
        billingBlock = '\n**Billing:** no matching servers row';
      }
    }

    const embed = new EmbedBuilder()
      .setColor(a.suspended ? 0xf59e0b : 0x22c55e)
      .setTitle(`Logs / status — ${a.name}`)
      .setDescription(
        [
          `**Panel id:** ${a.id} · \`${a.identifier}\``,
          `**Owner user:** ${a.user}`,
          `**Suspended:** ${a.suspended ? 'yes' : 'no'}`,
          resourcesLine,
          billingBlock,
          '',
          `_Console stream is in the panel UI. Rex shows status + billing activity here._`,
          `[Open server](${panel.panelUrl()}/server/${a.identifier})`,
        ].join('\n'),
      )
      .setTimestamp();

    return interaction.editReply({ embeds: [embed] });
  } catch (err) {
    return client.errNormal(
      { error: err.message || String(err), type: 'editreply' },
      interaction,
    );
  }
};
