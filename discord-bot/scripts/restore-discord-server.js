/**
 * Phantom World Discord restore after Noobie nuke:
 * - Recreate deleted categories/channels
 * - Post hosting plans into our-plans
 * - Remove Member, give Phantom | Civilian to all humans
 * - Perms: civilians view+type only; spam+announcements view-only; staff staff-only
 */
require('dotenv').config({ path: '/home/container/.env' });
const {
  Client,
  GatewayIntentBits,
  ChannelType,
  PermissionFlagsBits,
  EmbedBuilder,
} = require('discord.js');

const GID = '1472275444257783984';
const MEMBER_ID = '1522386919902937210';
const CIVILIAN_ID = '1472295618935259372'; // Phantom | Civilian

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

function findByName(guild, name) {
  const n = String(name).toLowerCase();
  return guild.channels.cache.find((c) => c.name.toLowerCase() === n || c.name.includes(name.replace(/[┊・]/g, '')));
}

async function ensureCategory(guild, name, position) {
  let cat = guild.channels.cache.find(
    (c) => c.type === ChannelType.GuildCategory && c.name === name,
  );
  if (!cat) {
    cat = await guild.channels.create({
      name,
      type: ChannelType.GuildCategory,
      reason: 'Rex restore after nuke',
    });
    console.log('CREATED_CAT', cat.name, cat.id);
    await sleep(400);
  }
  if (typeof position === 'number') {
    await cat.setPosition(position).catch(() => {});
  }
  return cat;
}

async function ensureChannel(guild, {
  name,
  type = ChannelType.GuildText,
  parentId = null,
  topic = undefined,
}) {
  let ch = guild.channels.cache.find(
    (c) => c.name === name && c.type === type && (!parentId || c.parentId === parentId),
  );
  if (!ch) {
    ch = guild.channels.cache.find((c) => c.name === name && c.type === type);
  }
  if (!ch) {
    ch = await guild.channels.create({
      name,
      type,
      parent: parentId || undefined,
      topic,
      reason: 'Rex restore after nuke',
    });
    console.log('CREATED_CH', ch.name, ch.id, 'parent', parentId);
    await sleep(450);
  } else if (parentId && ch.parentId !== parentId) {
    await ch.setParent(parentId, { lockPermissions: false }).catch(() => {});
    console.log('MOVED_CH', ch.name, '->', parentId);
  }
  return ch;
}

function publicOverwrites(guild, civilianId, staffRoleIds, mode = 'chat') {
  // mode: chat = view+type; view = view only; staff = staff only
  const everyone = guild.id;
  const overwrites = [
    {
      id: everyone,
      deny: [
        PermissionFlagsBits.ViewChannel,
        PermissionFlagsBits.SendMessages,
        PermissionFlagsBits.CreatePublicThreads,
        PermissionFlagsBits.CreatePrivateThreads,
        PermissionFlagsBits.SendMessagesInThreads,
      ],
    },
  ];

  if (mode === 'staff') {
    for (const id of staffRoleIds) {
      overwrites.push({
        id,
        allow: [
          PermissionFlagsBits.ViewChannel,
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.ReadMessageHistory,
          PermissionFlagsBits.AttachFiles,
          PermissionFlagsBits.EmbedLinks,
          PermissionFlagsBits.ManageMessages,
        ],
      });
    }
    return overwrites;
  }

  if (mode === 'view') {
    overwrites.push({
      id: civilianId,
      allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.ReadMessageHistory],
      deny: [
        PermissionFlagsBits.SendMessages,
        PermissionFlagsBits.AddReactions,
        PermissionFlagsBits.CreatePublicThreads,
        PermissionFlagsBits.CreatePrivateThreads,
        PermissionFlagsBits.SendMessagesInThreads,
        PermissionFlagsBits.AttachFiles,
        PermissionFlagsBits.MentionEveryone,
      ],
    });
  } else {
    // chat: view + type only
    overwrites.push({
      id: civilianId,
      allow: [
        PermissionFlagsBits.ViewChannel,
        PermissionFlagsBits.SendMessages,
        PermissionFlagsBits.ReadMessageHistory,
      ],
      deny: [
        PermissionFlagsBits.AddReactions,
        PermissionFlagsBits.AttachFiles,
        PermissionFlagsBits.EmbedLinks,
        PermissionFlagsBits.CreatePublicThreads,
        PermissionFlagsBits.CreatePrivateThreads,
        PermissionFlagsBits.SendMessagesInThreads,
        PermissionFlagsBits.UseExternalEmojis,
        PermissionFlagsBits.UseExternalStickers,
        PermissionFlagsBits.MentionEveryone,
        PermissionFlagsBits.ManageMessages,
        PermissionFlagsBits.ManageChannels,
      ],
    });
  }

  for (const id of staffRoleIds) {
    overwrites.push({
      id,
      allow: [
        PermissionFlagsBits.ViewChannel,
        PermissionFlagsBits.SendMessages,
        PermissionFlagsBits.ReadMessageHistory,
        PermissionFlagsBits.ManageMessages,
        PermissionFlagsBits.AttachFiles,
        PermissionFlagsBits.EmbedLinks,
      ],
    });
  }
  return overwrites;
}

async function applyOverwrites(ch, overwrites) {
  try {
    await ch.permissionOverwrites.set(overwrites, 'Rex restore: civilian view/type + staff');
  } catch (err) {
    console.warn('PERM_FAIL', ch.name, err.message);
  }
}

function hostingPlanEmbed() {
  return new EmbedBuilder()
    .setColor(0x111827)
    .setTitle('📦 Phantom World — Hosting Plans')
    .setDescription(
      [
        'Choose a plan that fits your city. Open a ticket in **🎫┊open-ticket** to order or upgrade.',
        '',
        '### 🌱 Starter',
        '• Entry FiveM / Discord bot hosting',
        '• Ideal for small communities getting started',
        '• Core support via tickets',
        '',
        '### 🚀 Growth',
        '• More slots / resources for active cities',
        '• Priority support window',
        '• Better performance headroom',
        '',
        '### 👑 Pro / Custom',
        '• High-pop / dedicated-style setups',
        '• Custom resource limits & add-ons',
        '• Direct staff coordination',
        '',
        '_Exact pricing & availability: ask in tickets or check **💰┊pricing**._',
        'Connect FiveM: `https://cfx.re/join/' + (process.env.CFX_SERVER_ID || '3m87mo') + '`',
      ].join('\n'),
    )
    .setFooter({ text: 'Phantom World · Our Plans' })
    .setTimestamp();
}

client.once('clientReady', async () => {
  const guild = await client.guilds.fetch(GID);
  await guild.channels.fetch();
  await guild.roles.fetch();

  const civilian = guild.roles.cache.get(CIVILIAN_ID);
  if (!civilian) throw new Error('Phantom | Civilian role missing');

  const staffRoleIds = [...guild.roles.cache.values()]
    .filter((r) =>
      /staff|mod|admin|founder|owner|management|dev/i.test(r.name) &&
      !/civilian|member|bot|jail|announce/i.test(r.name),
    )
    .map((r) => r.id);

  // Always include Co-Founder + Founders + Staff Team
  for (const id of [
    '1472295497149579491',
    '1472295495794954365',
    '1472295517060071485',
  ]) {
    if (!staffRoleIds.includes(id) && guild.roles.cache.has(id)) staffRoleIds.push(id);
  }

  console.log('STAFF_ROLES', staffRoleIds.length);

  // --- Categories ---
  const welcomeLounge = await ensureCategory(guild, 'WELCOME LOUNGE', 0);
  const phantomHq = await ensureCategory(guild, 'PHANTOM HQ', 1);
  const clientServices = guild.channels.cache.get('1522386949510402131')
    || await ensureCategory(guild, 'CLIENT SERVICES', 2);
  const communityHub = guild.channels.cache.get('1522386962038784020')
    || await ensureCategory(guild, 'COMMUNITY HUB', 3);
  const partners = await ensureCategory(guild, 'PARTNERS & GROWTH', 4);
  const aiguild = await ensureCategory(guild, '🤝 • AiGuild Partners', 5);
  const staffOps = guild.channels.cache.get('1522386993299067043')
    || await ensureCategory(guild, 'STAFF OPERATIONS', 6);
  const customVoice = await ensureCategory(guild, 'Custom voice', 7);

  // --- Recreate deleted channels ---
  const created = {};
  const specs = [
    { key: 'announcements', name: '📢┊𝚊𝚗𝚗𝚘𝚞𝚗𝚌𝚎𝚖𝚎𝚗𝚝𝚜', type: ChannelType.GuildAnnouncement, parentId: welcomeLounge.id },
    { key: 'welcome', name: '🎉┊𝚠𝚎𝚕𝚌𝚘𝚖𝚎', type: ChannelType.GuildText, parentId: welcomeLounge.id },
    { key: 'faq', name: '❓┊𝚏𝚊𝚚', type: ChannelType.GuildText, parentId: welcomeLounge.id },
    { key: 'pricing', name: '💰┊𝚙𝚛𝚒𝚌𝚒𝚗𝚐', type: ChannelType.GuildText, parentId: phantomHq.id },
    { key: 'features', name: '⚡┊𝚏𝚎𝚊𝚝𝚞𝚛𝚎𝚜', type: ChannelType.GuildText, parentId: phantomHq.id },
    { key: 'plans', name: '📦┊𝚘𝚞𝚛-𝚙𝚕𝚊𝚗𝚜', type: ChannelType.GuildText, parentId: phantomHq.id },
    { key: 'billing', name: '⚠️┊𝚋𝚒𝚕𝚕𝚒𝚗𝚐-𝚒𝚜𝚜𝚞𝚎𝚜', type: ChannelType.GuildText, parentId: clientServices.id },
    { key: 'reviews', name: '🏆┊𝚛𝚎𝚟𝚒𝚎𝚠𝚜', type: ChannelType.GuildText, parentId: communityHub.id },
    { key: 'gaming', name: '🔊┊gaming-zone', type: ChannelType.GuildVoice, parentId: communityHub.id },
    { key: 'partnerInfo', name: '🤝┊𝚙𝚊𝚛𝚝𝚗𝚎𝚛-𝚒𝚗𝚏𝚘', type: ChannelType.GuildText, parentId: partners.id },
    { key: 'affiliate', name: '🌐┊𝚊𝚏𝚏𝚒𝚕𝚒𝚊𝚝𝚎-𝚕𝚒𝚗𝚔𝚜', type: ChannelType.GuildText, parentId: partners.id },
    { key: 'haveMore', name: '📣・have-more-members', type: ChannelType.GuildText, parentId: aiguild.id },
    { key: 'staffVoice', name: '🔊┊staff-voice', type: ChannelType.GuildVoice, parentId: staffOps.id },
    { key: 'modLog', name: '📋┊𝚖𝚘𝚍-𝚕𝚘𝚐', type: ChannelType.GuildText, parentId: staffOps.id },
    { key: 'welcomeAlt', name: 'welcome', type: ChannelType.GuildText, parentId: welcomeLounge.id },
  ];

  for (const s of specs) {
    created[s.key] = await ensureChannel(guild, s);
  }

  // Move orphan HQ channels under PHANTOM HQ
  for (const id of [
    '1522386937317687447', // about-us
    '1522386945890582569', // service-status
    '1522386947773960373', // changelog
  ]) {
    const ch = guild.channels.cache.get(id);
    if (ch && ch.parentId !== phantomHq.id) {
      await ch.setParent(phantomHq.id, { lockPermissions: false }).catch(() => {});
      console.log('MOVED_ORPHAN', ch.name);
    }
  }

  // Move Create Voice under Custom voice
  const createVoice = guild.channels.cache.get('1522897871748468787');
  if (createVoice) {
    await createVoice.setParent(customVoice.id, { lockPermissions: false }).catch(() => {});
  }

  // Hosting plans message
  const plansCh = created.plans;
  if (plansCh?.isTextBased?.()) {
    await plansCh.send({
      content: '**Phantom World hosting plans are back.**',
      embeds: [hostingPlanEmbed()],
    });
    console.log('POSTED_PLANS', plansCh.id);
  }

  // --- Permission pass ---
  await guild.channels.fetch();

  for (const ch of guild.channels.cache.values()) {
    if (ch.type === ChannelType.GuildCategory) continue;
    if (ch.isThread?.()) continue;

    const name = ch.name;
    let mode = 'chat';
    if (ch.parentId === staffOps.id || /staff|mod-log|admin-room|alerts/i.test(name)) {
      mode = 'staff';
    } else if (
      ch.type === ChannelType.GuildAnnouncement ||
      /announcement/i.test(name) ||
      /spam/i.test(name)
    ) {
      mode = 'view';
    }

    const ows = publicOverwrites(guild, civilian.id, staffRoleIds, mode);
    await applyOverwrites(ch, ows);
    console.log('PERMS', mode, name);
    await sleep(250);
  }

  // Categories: hide @everyone, show civilian
  for (const ch of guild.channels.cache.values()) {
    if (ch.type !== ChannelType.GuildCategory) continue;
    const mode = ch.id === staffOps.id ? 'staff' : 'chat';
    await applyOverwrites(ch, publicOverwrites(guild, civilian.id, staffRoleIds, mode === 'staff' ? 'staff' : 'chat'));
    await sleep(200);
  }

  // --- Role swap: remove Member, give Civilian ---
  console.log('ROLE_SWAP_START');
  let given = 0;
  let stripped = 0;
  let scanned = 0;
  // Paginate members via REST-ish cache refresh
  try {
    await guild.members.fetch();
  } catch (e) {
    console.warn('members.fetch', e.message);
  }

  for (const m of guild.members.cache.values()) {
    if (m.user.bot) continue;
    scanned++;
    try {
      if (m.roles.cache.has(MEMBER_ID)) {
        await m.roles.remove(MEMBER_ID, 'Rex restore: replace Member with Phantom Civilian');
        stripped++;
      }
      if (!m.roles.cache.has(CIVILIAN_ID) && !m.roles.cache.has('1538834892820058172')) {
        // skip Jail role holders? still give civilian under jail? user said everyone — give civilian unless jailed
        if (m.roles.cache.has('1538834892820058172')) continue;
        await m.roles.add(CIVILIAN_ID, 'Rex restore: Phantom Civilian');
        given++;
      }
    } catch (err) {
      console.warn('ROLE_FAIL', m.user.tag, err.message);
    }
    if (scanned % 25 === 0) await sleep(500);
  }

  console.log(JSON.stringify({
    done: true,
    scanned,
    memberRemoved: stripped,
    civilianGiven: given,
    plansChannel: plansCh?.id,
    announcements: created.announcements?.id,
  }));

  await client.destroy();
  process.exit(0);
});

client.login(process.env.DISCORD_TOKEN);
