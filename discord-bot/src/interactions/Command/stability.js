const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { computeStability, attemptRemediation } = require('../../lib/fivem-stability');
const { isHostingAdmin } = require('../../lib/hosting-auth');

function colorForScore(score) {
  if (score >= 95) return 0x22c55e;
  if (score >= 85) return 0x84cc16;
  if (score >= 70) return 0xf59e0b;
  if (score >= 50) return 0xf97316;
  return 0xef4444;
}

function buildEmbed(report, title) {
  const joinId = process.env.CFX_SERVER_ID || '';
  const blockers =
    report.blockers.length > 0
      ? report.blockers.slice(0, 12).join('\n')
      : '_Nothing — stability is at/near 100%._';

  const factorLines = report.factors
    .map((f) => `${f.ok ? '✅' : '❌'} **${f.label}**${f.penalty ? ` (−${f.penalty})` : ''}\n${f.detail}`)
    .join('\n\n');

  const embed = new EmbedBuilder()
    .setColor(colorForScore(report.score))
    .setTitle(title || `FiveM Stability — ${report.score}% (${report.grade})`)
    .setDescription(
      [
        `**${report.status?.serverName || 'Phantom World'}** · ${report.online ? '🟢 Online' : '🔴 Offline'}`,
        `Players: **${report.status?.playerCount ?? 0}/${report.status?.maxPlayers ?? 48}**`,
        joinId ? `[Connect](https://cfx.re/join/${joinId})` : null,
        '',
        `### Blocking 100%`,
        blockers,
      ]
        .filter(Boolean)
        .join('\n'),
    )
    .addFields({
      name: 'All factors',
      value: factorLines.slice(0, 1024) || '—',
    })
    .setFooter({ text: 'Use /stability fix to attempt safe remediations' })
    .setTimestamp();

  if (report.actions?.length) {
    embed.addFields({
      name: 'Suggested fixes',
      value: report.actions.map((a) => `• ${a.label} _(${a.risk})_`).join('\n').slice(0, 1024),
    });
  }

  return embed;
}

module.exports = {
  data: new SlashCommandBuilder()
    .setName('stability')
    .setDescription('FiveM server stability % — factors + fix attempts')
    .addSubcommand((sub) =>
      sub.setName('check').setDescription('Show current stability % and everything blocking 100%'),
    )
    .addSubcommand((sub) =>
      sub
        .setName('fix')
        .setDescription('Try to improve stability (safe remediations; restart only if empty+offline)')
        .addBooleanOption((opt) =>
          opt
            .setName('restart_if_empty')
            .setDescription('Allow FX restart if server is offline and 0 players (owner only)'),
        ),
    ),

  run: async (client, interaction) => {
    const sub = interaction.options.getSubcommand();

    try {
      if (sub === 'check') {
        const report = await computeStability();
        return interaction.editReply({ embeds: [buildEmbed(report)] });
      }

      if (sub === 'fix') {
        const wantRestart = interaction.options.getBoolean('restart_if_empty') === true;
        if (wantRestart && !isHostingAdmin(interaction.user.id)) {
          return interaction.editReply({
            content: 'Only the bot owner can allow FX restarts from `/stability fix`.',
          });
        }

        await interaction.editReply({ content: 'Running stability probes + safe remediations…' });
        const result = await attemptRemediation(client, { allowRestart: wantRestart });
        const embed = buildEmbed(result.after, `Stability after fix — ${result.after.score}%`);
        embed.addFields({
          name: 'Remediation log',
          value: [
            `Before: **${result.before.score}%** → After: **${result.after.score}%**`,
            `Applied: ${result.applied.join(', ') || 'none'}`,
            ...result.notes.map((n) => `• ${n}`),
          ]
            .join('\n')
            .slice(0, 1024),
        });
        return interaction.editReply({ content: null, embeds: [embed] });
      }

      return interaction.editReply({ content: 'Unknown subcommand' });
    } catch (err) {
      return interaction.editReply({ content: `Stability failed: ${err.message || err}` });
    }
  },
};
