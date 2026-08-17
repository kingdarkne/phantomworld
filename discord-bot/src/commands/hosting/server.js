const { EmbedBuilder } = require('discord.js');
const panel = require('../../lib/panel-api');
const billing = require('../../lib/billing-db');

async function resolveOwnerUserId(email) {
  let user = await panel.findUserByEmail(email);
  if (user) return user.attributes.id;

  if (billing.billingConfigured()) {
    const client = await billing.getClientByEmail(email);
    if (client?.user_id) return client.user_id;
  }

  const password = panel.randomPassword(16);
  const created = await panel.createUser({
    email,
    username: panel.sanitizeUsername(email),
    firstName: email.split('@')[0].slice(0, 20) || 'Customer',
    lastName: 'User',
    password,
  });
  const id = created.attributes.id;
  if (billing.billingConfigured()) {
    const client = await billing.getClientByEmail(email);
    if (client && !client.user_id) await billing.linkClientPanelUser(client.id, id);
  }
  return { id, password };
}

module.exports = async (client, interaction) => {
  const action = interaction.options.getString('action');
  const target = interaction.options.getString('target');
  const email = interaction.options.getString('email');
  const name = interaction.options.getString('name');
  const planId = interaction.options.getInteger('plan');
  const eggOpt = interaction.options.getString('egg');
  const nodeOpt = interaction.options.getInteger('node');
  const signal = interaction.options.getString('signal') || 'restart';

  try {
    if (action === 'list') {
      const data = await panel.listServers({ perPage: 30 });
      const lines = (data.data || []).slice(0, 25).map((s) => {
        const a = s.attributes;
        const sus = a.suspended ? ' ⏸' : '';
        return `\`${a.id}\` \`${a.identifier}\` ${a.name}${sus} · user ${a.user}`;
      });
      return interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x3b82f6)
            .setTitle('Panel servers')
            .setDescription(lines.join('\n') || 'No servers'),
        ],
      });
    }

    if (action === 'info') {
      if (!target) throw new Error('target is required');
      const data = await panel.findServer(target);
      const a = data.attributes;
      let resources = null;
      try {
        resources = await panel.getClientServerResources(a.identifier);
      } catch (_) {
        /* client key may lack access */
      }
      const embed = new EmbedBuilder()
        .setColor(a.suspended ? 0xf59e0b : 0x22c55e)
        .setTitle(a.name)
        .setDescription(
          [
            `**ID:** ${a.id}`,
            `**Identifier:** \`${a.identifier}\``,
            `**UUID:** \`${a.uuid}\``,
            `**Owner user id:** ${a.user}`,
            `**Node:** ${a.node}`,
            `**Suspended:** ${a.suspended ? 'yes' : 'no'}`,
            resources
              ? `**State:** ${resources.attributes?.current_state || 'unknown'} · CPU ${resources.attributes?.resources?.cpu_absolute ?? '?'}%`
              : null,
            `[Panel](${panel.panelUrl()}/admin/servers/view/${a.id})`,
          ]
            .filter(Boolean)
            .join('\n'),
        );
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'create') {
      if (!email) throw new Error('email is required');
      if (!name) throw new Error('name is required');
      if (!planId) throw new Error('plan is required — run /hosting plans');
      if (!billing.billingConfigured()) throw new Error('Billing DB is not configured');

      const plan = await billing.getPlan(planId);
      if (!plan) throw new Error(`Unknown plan id ${planId}`);
      const cycle = await billing.getPlanCycle(planId);
      if (!cycle) throw new Error(`Plan ${planId} has no billing cycle`);

      let clientRow = await billing.getClientByEmail(email);
      if (!clientRow) {
        throw new Error(
          `No billing client for ${email}. Create them in billing first, or register on the billing site.`,
        );
      }

      const owner = await resolveOwnerUserId(email);
      const ownerId = typeof owner === 'object' ? owner.id : owner;
      const tempPass = typeof owner === 'object' ? owner.password : null;

      const { nestId, eggId } = billing.parseNestEgg(plan, eggOpt || null);
      const { locationId, nodeId } = billing.parseNode(plan, nodeOpt || null);

      const eggRes = await panel.getEgg(nestId, eggId);
      const eggAttrs = eggRes.attributes;
      const environment = {};
      for (const v of eggAttrs.relationships?.variables?.data || []) {
        environment[v.attributes.env_variable] = v.attributes.default_value;
      }

      const allocationId = await panel.findFreeAllocation(nodeId, {
        minPort: plan.min_port,
        maxPort: plan.max_port,
      });
      if (!allocationId) throw new Error(`No free allocations on node ${nodeId}`);

      const created = await panel.createServer({
        name,
        user: ownerId,
        egg: eggId,
        docker_image: eggAttrs.docker_image,
        startup: eggAttrs.startup,
        environment,
        limits: {
          cpu: plan.cpu,
          memory: plan.ram,
          swap: plan.swap,
          disk: plan.disk,
          io: plan.io,
        },
        feature_limits: {
          databases: plan.databases,
          backups: plan.backups,
          allocations: (plan.extra_ports || 0) + 1,
        },
        allocation: { default: allocationId },
      });

      const attrs = created.attributes;
      await billing.insertBillingServerRow({
        serverId: attrs.id,
        identifier: attrs.identifier,
        clientId: clientRow.id,
        planId: plan.id,
        planCycle: cycle.id,
        serverName: name,
        nestId,
        eggId,
        locationId,
        nodeId,
      });

      const embed = new EmbedBuilder()
        .setColor(0x22c55e)
        .setTitle('Server created')
        .setDescription(
          [
            `**Name:** ${attrs.name}`,
            `**ID:** ${attrs.id}`,
            `**Identifier:** \`${attrs.identifier}\``,
            `**Owner:** ${email} (panel user ${ownerId})`,
            `**Plan:** ${plan.name} (#${plan.id})`,
            tempPass ? `**New panel password:** \`${tempPass}\`` : null,
            `[Panel](${panel.panelUrl()}/server/${attrs.identifier})`,
          ]
            .filter(Boolean)
            .join('\n'),
        );
      return interaction.editReply({ embeds: [embed] });
    }

    if (action === 'delete') {
      if (!target) throw new Error('target is required');
      const data = await panel.findServer(target);
      const a = data.attributes;
      await panel.deleteServer(a.id, { force: true });
      if (billing.billingConfigured()) {
        await billing.markBillingServerDeleted(a.id).catch(() => {});
      }
      return interaction.editReply({
        content: `Deleted server **${a.name}** (\`${a.identifier}\` / id ${a.id}).`,
      });
    }

    if (action === 'suspend' || action === 'unsuspend') {
      if (!target) throw new Error('target is required');
      const data = await panel.findServer(target);
      const a = data.attributes;
      if (action === 'suspend') await panel.suspendServer(a.id);
      else await panel.unsuspendServer(a.id);
      return interaction.editReply({
        content: `${action === 'suspend' ? 'Suspended' : 'Unsuspended'} **${a.name}** (\`${a.identifier}\`).`,
      });
    }

    if (action === 'power') {
      if (!target) throw new Error('target is required');
      const data = await panel.findServer(target);
      const a = data.attributes;
      await panel.powerServer(a.identifier, signal);
      return interaction.editReply({
        content: `Sent **${signal}** to **${a.name}** (\`${a.identifier}\`).`,
      });
    }

    if (action === 'move') {
      if (!target) throw new Error('target is required');
      if (!email) throw new Error('email is required (new owner)');
      const data = await panel.findServer(target);
      const a = data.attributes;
      const owner = await resolveOwnerUserId(email);
      const ownerId = typeof owner === 'object' ? owner.id : owner;
      await panel.updateServerDetails(a.id, {
        name: a.name,
        user: ownerId,
        description: a.description || '',
      });
      if (billing.billingConfigured()) {
        const client = await billing.getClientByEmail(email);
        const row = await billing.getBillingServer(a.identifier);
        if (client && row) {
          await billing.query(`UPDATE servers SET client_id = ? WHERE id = ?`, [
            client.id,
            row.id,
          ]);
        }
      }
      return interaction.editReply({
        content: `Moved **${a.name}** (\`${a.identifier}\`) → ${email} (panel user ${ownerId}).`,
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
