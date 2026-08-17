/**
 * Join welcome DMs + leave-reason feedback DMs for Phantom World.
 */
const fs = require('fs');
const path = require('path');
const {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
  ModalBuilder,
  StringSelectMenuBuilder,
  StringSelectMenuOptionBuilder,
  TextInputBuilder,
  TextInputStyle,
} = require('discord.js');

const LEAVE_REASON_SELECT_ID = 'phantom-leave-reason';
const LEAVE_FEEDBACK_MODAL_PREFIX = 'phantom-leave-feedback';
const FEEDBACK_LOG = path.join(process.cwd(), 'data', 'leave-feedback.jsonl');

const LEAVE_REASONS = [
  { value: 'not_enough', label: 'Not enough to do', emoji: '😴' },
  { value: 'hard_start', label: 'Hard to get started', emoji: '🧭' },
  { value: 'toxic', label: 'Toxicity / bad vibes', emoji: '😤' },
  { value: 'schedule', label: 'No time / schedule', emoji: '⏰' },
  { value: 'other_server', label: 'Joined another server', emoji: '🚪' },
  { value: 'not_for_me', label: 'Just not for me', emoji: '👋' },
  { value: 'other', label: 'Other', emoji: '💬' },
];

function enabled(flag, defaultOn = true) {
  const raw = process.env[flag];
  if (raw == null || raw === '') return defaultOn;
  return !['0', 'false', 'off', 'no'].includes(String(raw).toLowerCase());
}

function serverName() {
  return process.env.PHANTOM_SERVER_NAME || process.env.FIVEM_DISPLAY_NAME || 'Phantom World';
}

function cfxJoinUrl() {
  const id = process.env.CFX_SERVER_ID || '3m87mo';
  return id ? `https://cfx.re/join/${id}` : null;
}

function discordInviteUrl() {
  return (
    process.env.DISCORD_INVITE_URL ||
    process.env.DISCORD_SUPPORT_INVITE ||
    'https://discord.gg/zZSvmdUx'
  );
}

function reasonLabel(value) {
  return LEAVE_REASONS.find((r) => r.value === value)?.label || value || 'Unknown';
}

async function fetchStatusSafe() {
  try {
    const { getPhantomStatus } = require('../../aio-bridge/fivem-status');
    return await getPhantomStatus();
  } catch {
    return null;
  }
}

function appendFeedback(entry) {
  try {
    fs.mkdirSync(path.dirname(FEEDBACK_LOG), { recursive: true });
    fs.appendFileSync(FEEDBACK_LOG, `${JSON.stringify(entry)}\n`);
  } catch (err) {
    console.warn('[member-dm] failed to write feedback log:', err.message);
  }
}

async function postFeedbackToStaff(client, entry) {
  const channelId = process.env.LEAVE_FEEDBACK_CHANNEL_ID || process.env.BILLING_NOTIFY_CHANNEL_ID;
  const embed = new EmbedBuilder()
    .setColor(0xf59e0b)
    .setTitle('Leave feedback')
    .setDescription(
      [
        `**User:** ${entry.tag || 'Unknown'} (\`${entry.userId}\`)`,
        `**Server:** ${entry.guildName || entry.guildId}`,
        `**Reason:** ${entry.reasonLabel}`,
        entry.feedback ? `**Notes:** ${entry.feedback}` : '**Notes:** _(none)_',
      ].join('\n'),
    )
    .setTimestamp(new Date(entry.at));

  if (channelId) {
    try {
      const ch = await client.channels.fetch(channelId).catch(() => null);
      if (ch?.isTextBased?.()) {
        await ch.send({ embeds: [embed] });
        return;
      }
    } catch (err) {
      console.warn('[member-dm] staff channel send failed:', err.message);
    }
  }

  try {
    const hook = client.webhooks?.serverLogs;
    if (hook?.id && hook?.token) {
      const { WebhookClient } = require('discord.js');
      const wh = new WebhookClient({ id: hook.id, token: hook.token });
      await wh.send({ username: 'Leave Feedback', embeds: [embed] }).catch(() => {});
    }
  } catch (_) {}
}

/**
 * Build + send welcome DM when someone joins.
 */
async function sendWelcomeDm(client, member) {
  if (!enabled('MEMBER_WELCOME_DM', true)) return { skipped: true, reason: 'disabled' };
  if (!member || member.user?.bot) return { skipped: true, reason: 'bot' };

  const name = serverName();
  const join = cfxJoinUrl();
  const invite = discordInviteUrl();
  const status = await fetchStatusSafe();
  const players = status?.playerCount;
  const max = status?.maxPlayers ?? 48;
  const guildName = member.guild?.name || name;

  const embed = new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle(`Welcome to ${guildName} ✨`)
    .setDescription(
      [
        `Hey **${member.user.username}** — glad you made it.`,
        '',
        `You're now part of **${name}**, a serious FiveM roleplay city with active staff, events, and a full Discord toolkit (Rex voice AI, music, tickets, and 400+ commands).`,
        '',
        '### Jump in',
        join ? `**FiveM connect:** ${join}` : 'Ask in Discord for the current connect link.',
        typeof players === 'number' ? `**Players online now:** ${players}/${max}` : null,
        `**Community invite:** ${invite}`,
        '',
        '### Quick tips',
        '• Type `/help` for the full command menu',
        '• `/rex join` then say **"Hey Rex"** in VC for voice help',
        '• `/phantomstatus` for live server status',
        '• Open a ticket if you need staff',
        '',
        '_See you in the city — have fun, stay chill, and make a story._',
      ]
        .filter((line) => line != null)
        .join('\n'),
    )
    .setThumbnail(member.guild?.iconURL?.({ size: 256 }) || null)
    .setFooter({ text: `${name} · Thanks for joining` })
    .setTimestamp();

  const row = new ActionRowBuilder();
  if (join) {
    row.addComponents(
      new ButtonBuilder().setStyle(ButtonStyle.Link).setLabel('Connect on FiveM').setURL(join),
    );
  }
  if (invite) {
    row.addComponents(
      new ButtonBuilder().setStyle(ButtonStyle.Link).setLabel('Open Discord').setURL(invite),
    );
  }

  try {
    await member.send({
      embeds: [embed],
      components: row.components.length ? [row] : [],
    });
    console.log(`[member-dm] welcome sent to ${member.user.tag} (${member.id})`);
    return { ok: true };
  } catch (err) {
    console.warn(`[member-dm] welcome DM failed for ${member.id}:`, err.message);
    return { ok: false, error: err.message };
  }
}

/**
 * Build + send leave survey DM (reason dropdown + later feedback modal).
 */
async function sendLeaveFeedbackDm(client, member) {
  if (!enabled('MEMBER_LEAVE_DM', true)) return { skipped: true, reason: 'disabled' };
  if (!member || member.user?.bot) return { skipped: true, reason: 'bot' };

  const name = serverName();
  const guildName = member.guild?.name || name;
  const guildId = member.guild?.id || 'unknown';

  const embed = new EmbedBuilder()
    .setColor(0xf97316)
    .setTitle(`Sorry to see you go`)
    .setDescription(
      [
        `Hey **${member.user.username}** — you left **${guildName}**.`,
        '',
        'We’d love a quick bit of honesty so we can improve.',
        '**Pick a reason below**, then you can add optional written feedback.',
        '',
        `You’re always welcome back: ${discordInviteUrl()}`,
        cfxJoinUrl() ? `FiveM: ${cfxJoinUrl()}` : null,
      ]
        .filter(Boolean)
        .join('\n'),
    )
    .setFooter({ text: `${name} · Leave feedback` })
    .setTimestamp();

  const select = new StringSelectMenuBuilder()
    .setCustomId(`${LEAVE_REASON_SELECT_ID}:${guildId}`)
    .setPlaceholder('Why did you leave?')
    .addOptions(
      LEAVE_REASONS.map((r) =>
        new StringSelectMenuOptionBuilder()
          .setLabel(r.label)
          .setValue(r.value)
          .setEmoji(r.emoji)
          .setDescription(`Left because: ${r.label}`.slice(0, 100)),
      ),
    );

  try {
    await member.send({
      embeds: [embed],
      components: [new ActionRowBuilder().addComponents(select)],
    });
    console.log(`[member-dm] leave survey sent to ${member.user.tag} (${member.id})`);
    return { ok: true };
  } catch (err) {
    console.warn(`[member-dm] leave DM failed for ${member.id}:`, err.message);
    return { ok: false, error: err.message };
  }
}

function parseLeaveSelectId(customId) {
  if (!customId?.startsWith(`${LEAVE_REASON_SELECT_ID}:`) && customId !== LEAVE_REASON_SELECT_ID) {
    return null;
  }
  const parts = String(customId).split(':');
  return { guildId: parts[1] || 'unknown' };
}

function parseLeaveModalId(customId) {
  if (!customId?.startsWith(`${LEAVE_FEEDBACK_MODAL_PREFIX}:`)) return null;
  const parts = String(customId).split(':');
  // phantom-leave-feedback:reason:guildId
  return { reason: parts[1] || 'other', guildId: parts[2] || 'unknown' };
}

async function handleLeaveReasonSelect(client, interaction) {
  const parsed = parseLeaveSelectId(interaction.customId);
  if (!parsed) return false;

  const reason = interaction.values?.[0] || 'other';
  const modal = new ModalBuilder()
    .setCustomId(`${LEAVE_FEEDBACK_MODAL_PREFIX}:${reason}:${parsed.guildId}`)
    .setTitle('Optional feedback');

  const input = new TextInputBuilder()
    .setCustomId('leave_feedback_text')
    .setLabel('Anything else we should know?')
    .setStyle(TextInputStyle.Paragraph)
    .setRequired(false)
    .setMaxLength(1000)
    .setPlaceholder('Optional — what could we do better?');

  modal.addComponents(new ActionRowBuilder().addComponents(input));
  await interaction.showModal(modal);

  // Also record the reason immediately in case they close the modal
  const entry = {
    at: new Date().toISOString(),
    userId: interaction.user.id,
    tag: interaction.user.tag,
    guildId: parsed.guildId,
    reason,
    reasonLabel: reasonLabel(reason),
    feedback: null,
    stage: 'reason_selected',
  };
  appendFeedback(entry);
  return true;
}

async function handleLeaveFeedbackModal(client, interaction) {
  const parsed = parseLeaveModalId(interaction.customId);
  if (!parsed) return false;

  const feedback = interaction.fields.getTextInputValue('leave_feedback_text')?.trim() || '';
  const entry = {
    at: new Date().toISOString(),
    userId: interaction.user.id,
    tag: interaction.user.tag,
    guildId: parsed.guildId,
    guildName: client.guilds.cache.get(parsed.guildId)?.name,
    reason: parsed.reason,
    reasonLabel: reasonLabel(parsed.reason),
    feedback: feedback || null,
    stage: 'feedback_submitted',
  };
  appendFeedback(entry);
  await postFeedbackToStaff(client, entry);

  const thanks = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle('Thanks for the feedback')
    .setDescription(
      [
        `**Reason:** ${entry.reasonLabel}`,
        feedback ? `**Your notes:** ${feedback}` : 'No extra notes — that’s totally fine.',
        '',
        `If you ever want to return: ${discordInviteUrl()}`,
        cfxJoinUrl() ? `FiveM: ${cfxJoinUrl()}` : null,
      ]
        .filter(Boolean)
        .join('\n'),
    )
    .setFooter({ text: serverName() })
    .setTimestamp();

  await interaction.reply({ embeds: [thanks] });
  return true;
}

module.exports = {
  LEAVE_REASON_SELECT_ID,
  LEAVE_FEEDBACK_MODAL_PREFIX,
  LEAVE_REASONS,
  sendWelcomeDm,
  sendLeaveFeedbackDm,
  handleLeaveReasonSelect,
  handleLeaveFeedbackModal,
  parseLeaveSelectId,
  parseLeaveModalId,
};
