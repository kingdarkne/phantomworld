import fs from 'fs';
import path from 'path';
import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  ChannelType,
  EmbedBuilder,
  PermissionFlagsBits,
} from 'discord.js';

const storeFile = path.join(process.cwd(), 'data', 'tickets.json');

function load() {
  try {
    return JSON.parse(fs.readFileSync(storeFile, 'utf8'));
  } catch {
    return { guilds: {} };
  }
}

function save(data) {
  fs.mkdirSync(path.dirname(storeFile), { recursive: true });
  fs.writeFileSync(storeFile, JSON.stringify(data, null, 2));
}

function guildCfg(data, guildId) {
  if (!data.guilds[guildId]) {
    data.guilds[guildId] = { categoryId: null, roleId: null, logId: null, count: 0, open: {} };
  }
  return data.guilds[guildId];
}

export function ticketSetup({ guildId, categoryId, roleId, logId = null }) {
  const data = load();
  const g = guildCfg(data, guildId);
  g.categoryId = categoryId;
  g.roleId = roleId;
  g.logId = logId;
  save(data);
  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Tickets configured')
    .setDescription(
      `**Category:** <#${categoryId}>\n**Support role:** <@&${roleId}>${logId ? `\n**Logs:** <#${logId}>` : ''}\n\nUsers can run \`/ticket create\` or \`$ticket create\`.`,
    );
}

export async function ticketCreate({ guild, member, reason = 'No reason provided', client }) {
  const data = load();
  const g = guildCfg(data, guild.id);
  if (!g.categoryId || !g.roleId) {
    throw new Error('Tickets are not set up. An admin must run `/ticket setup` first.');
  }
  const existing = Object.values(g.open || {}).find((t) => t.creatorId === member.id);
  if (existing) {
    throw new Error(`You already have an open ticket: <#${existing.channelId}>`);
  }

  const category = await guild.channels.fetch(g.categoryId).catch(() => null);
  if (!category) throw new Error('Ticket category is missing — run `/ticket setup` again.');

  g.count = (g.count || 0) + 1;
  const ticketNo = String(g.count).padStart(4, '0');
  const channelName = `ticket-${ticketNo}`;

  const channel = await guild.channels.create({
    name: channelName,
    type: ChannelType.GuildText,
    parent: category.id,
    permissionOverwrites: [
      { id: guild.id, deny: [PermissionFlagsBits.ViewChannel] },
      {
        id: member.id,
        allow: [
          PermissionFlagsBits.ViewChannel,
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.AttachFiles,
          PermissionFlagsBits.ReadMessageHistory,
        ],
      },
      {
        id: g.roleId,
        allow: [
          PermissionFlagsBits.ViewChannel,
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.AttachFiles,
          PermissionFlagsBits.ReadMessageHistory,
          PermissionFlagsBits.ManageMessages,
        ],
      },
      {
        id: guild.members.me.id,
        allow: [
          PermissionFlagsBits.ViewChannel,
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.ManageChannels,
          PermissionFlagsBits.ReadMessageHistory,
        ],
      },
    ],
  });

  g.open[channel.id] = {
    channelId: channel.id,
    creatorId: member.id,
    ticketNo,
    reason,
    createdAt: new Date().toISOString(),
  };
  save(data);

  const row = new ActionRowBuilder().addComponents(
    new ButtonBuilder().setCustomId('ticket:close').setLabel('Close').setEmoji('🔒').setStyle(ButtonStyle.Danger),
    new ButtonBuilder().setCustomId('ticket:claim').setLabel('Claim').setEmoji('✋').setStyle(ButtonStyle.Primary),
  );

  const embed = new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle(`Ticket #${ticketNo}`)
    .setDescription(
      `Thanks for opening a ticket, ${member}.\nSupport will be with you shortly.\n\n**Reason:** ${reason}`,
    )
    .setFooter({ text: 'Close · Claim' });

  await channel.send({ content: `${member} · <@&${g.roleId}>`, embeds: [embed], components: [row] });

  if (g.logId) {
    const log = await client.channels.fetch(g.logId).catch(() => null);
    if (log?.isTextBased()) {
      await log.send({
        embeds: [
          new EmbedBuilder()
            .setColor(0x2ee6c5)
            .setTitle('Ticket opened')
            .setDescription(`**Channel:** ${channel}\n**User:** ${member}\n**Reason:** ${reason}`),
        ],
      });
    }
  }

  return { channel, embed: new EmbedBuilder().setColor(0x2ee6c5).setDescription(`Ticket created: ${channel}`) };
}

export async function ticketClose({ guild, channel, closer, client }) {
  const data = load();
  const g = guildCfg(data, guild.id);
  const ticket = g.open?.[channel.id];
  if (!ticket) throw new Error('This is not an open ticket channel.');

  const isStaff =
    closer.permissions?.has(PermissionFlagsBits.ManageChannels) ||
    closer.roles?.cache?.has(g.roleId);
  if (!isStaff && closer.id !== ticket.creatorId) {
    throw new Error('Only the ticket owner or support staff can close this.');
  }

  delete g.open[channel.id];
  save(data);

  if (g.logId) {
    const log = await client.channels.fetch(g.logId).catch(() => null);
    if (log?.isTextBased()) {
      await log.send({
        embeds: [
          new EmbedBuilder()
            .setColor(0xef4444)
            .setTitle(`Ticket #${ticket.ticketNo} closed`)
            .setDescription(`**Closed by:** ${closer}\n**Channel:** \`#${channel.name}\``),
        ],
      });
    }
  }

  await channel.send({ embeds: [new EmbedBuilder().setColor(0xef4444).setDescription(`Ticket closed by ${closer}. Deleting in 5s…`)] });
  setTimeout(() => channel.delete('Ticket closed').catch(() => {}), 5000);
  return true;
}

export async function ticketAdd({ guild, channel, moderator, targetUser }) {
  const data = load();
  const g = guildCfg(data, guild.id);
  if (!g.open?.[channel.id]) throw new Error('This is not an open ticket channel.');
  if (!moderator.permissions?.has(PermissionFlagsBits.ManageChannels) && !moderator.roles?.cache?.has(g.roleId)) {
    throw new Error('Support staff only.');
  }
  await channel.permissionOverwrites.edit(targetUser.id, {
    ViewChannel: true,
    SendMessages: true,
    ReadMessageHistory: true,
    AttachFiles: true,
  });
  return new EmbedBuilder().setColor(0x2ee6c5).setDescription(`Added ${targetUser} to the ticket.`);
}

export async function ticketRemove({ guild, channel, moderator, targetUser }) {
  const data = load();
  const g = guildCfg(data, guild.id);
  const ticket = g.open?.[channel.id];
  if (!ticket) throw new Error('This is not an open ticket channel.');
  if (!moderator.permissions?.has(PermissionFlagsBits.ManageChannels) && !moderator.roles?.cache?.has(g.roleId)) {
    throw new Error('Support staff only.');
  }
  if (targetUser.id === ticket.creatorId) throw new Error("Can't remove the ticket creator.");
  await channel.permissionOverwrites.delete(targetUser.id);
  return new EmbedBuilder().setColor(0xf59e0b).setDescription(`Removed ${targetUser} from the ticket.`);
}

export function ticketPanelPayload() {
  const row = new ActionRowBuilder().addComponents(
    new ButtonBuilder()
      .setCustomId('ticket:create')
      .setLabel('Open Ticket')
      .setEmoji('🎫')
      .setStyle(ButtonStyle.Success),
  );
  const embed = new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Support Tickets')
    .setDescription('Need help? Click **Open Ticket** and a private channel will be created for you.');
  return { embeds: [embed], components: [row] };
}

export async function handleTicketButton(interaction) {
  const id = interaction.customId;
  if (!id?.startsWith('ticket:')) return false;

  if (id === 'ticket:create') {
    await interaction.deferReply({ ephemeral: true });
    const { channel } = await ticketCreate({
      guild: interaction.guild,
      member: interaction.member,
      reason: 'Opened from panel',
      client: interaction.client,
    });
    await interaction.editReply(`Ticket created: ${channel}`);
    return true;
  }
  if (id === 'ticket:close') {
    await interaction.deferReply({ ephemeral: true });
    await ticketClose({
      guild: interaction.guild,
      channel: interaction.channel,
      closer: interaction.member,
      client: interaction.client,
    });
    await interaction.editReply('Closing ticket…');
    return true;
  }
  if (id === 'ticket:claim') {
    await interaction.reply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2ee6c5)
          .setDescription(`✋ ${interaction.member} claimed this ticket.`),
      ],
    });
    return true;
  }
  return false;
}
