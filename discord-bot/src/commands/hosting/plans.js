const { EmbedBuilder } = require('discord.js');
const billing = require('../../lib/billing-db');

module.exports = async (client, interaction) => {
  try {
    if (!billing.billingConfigured()) {
      throw new Error('BILLING_DB_* is not configured on Rex');
    }
    const plans = await billing.listPlans();
    const lines = plans.map((p) => {
      let eggs = '';
      try {
        const arr = JSON.parse(p.nests_eggs_id || '[]');
        eggs = arr.slice(0, 3).join(', ');
      } catch {
        eggs = '?';
      }
      return `\`${p.id}\` **${p.name}** — ${p.ram}MB RAM / ${p.cpu}% CPU / ${p.disk}MB · eggs: ${eggs}`;
    });

    const embed = new EmbedBuilder()
      .setColor(0x8b5cf6)
      .setTitle('Billing plans')
      .setDescription(
        (lines.join('\n') || 'No plans') +
          '\n\nUse `/hosting server action:create plan:<id> email:… name:…`',
      );
    return interaction.editReply({ embeds: [embed] });
  } catch (err) {
    return client.errNormal(
      { error: err.message || String(err), type: 'editreply' },
      interaction,
    );
  }
};
