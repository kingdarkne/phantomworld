const {
  createMessageInteraction,
  listCommandFiles,
  parseValuesFromArgs,
  HARD_ALIASES,
} = require('../../lib/prefixBridge');

module.exports = (client) => {
  let maps = null;
  const ensureMaps = () => {
    if (!maps) maps = listCommandFiles();
    return maps;
  };

  /**
   * Resolve `$cmd ...` into a slash category + optional subcommand.
   */
  client.resolvePrefixRoute = function resolvePrefixRoute(command, args) {
    const { byLeaf, categories } = ensureMaps();
    const hard = HARD_ALIASES[command];
    if (hard) {
      if (hard.needsSub) {
        const sub = args[0]?.toLowerCase();
        if (!sub) return { error: `Usage: $${command} <subcommand> ...` };
        return {
          category: hard.category,
          sub,
          restArgs: args.slice(1),
          topLevel: false,
        };
      }
      if (hard.topLevel) {
        return { category: hard.category, sub: hard.sub, restArgs: args, topLevel: true };
      }
      return { category: hard.category, sub: hard.sub, restArgs: args, topLevel: false };
    }

    // `$moderation ban ...`
    if (categories.has(command) || client.commands?.has(command)) {
      const sub = args[0]?.toLowerCase() || null;
      const slash = client.commands?.get(command);
      const hasSubs = Boolean(slash?.data?.options?.length);
      if (hasSubs && !sub && command !== 'help') {
        return { error: `Usage: $${command} <subcommand> ... — try \`/help\` or \`$${command} help\`` };
      }
      return {
        category: command,
        sub: hasSubs ? sub : null,
        restArgs: hasSubs ? args.slice(1) : args,
        topLevel: !hasSubs,
      };
    }

    // Unique leaf: `$ban` when only moderation/ban.js exists as preferred hard alias already.
    const hits = byLeaf.get(command) || [];
    if (hits.length === 1) {
      return { category: hits[0].category, sub: hits[0].sub, restArgs: args, topLevel: false };
    }
    if (hits.length > 1) {
      const opts = hits.map((h) => `$${h.category} ${h.sub}`).slice(0, 8).join(', ');
      return { error: `\`$${command}\` is ambiguous. Use one of: ${opts}` };
    }

    return null;
  };

  client.runPrefixCommand = async function runPrefixCommand(message, command, args) {
    const route = client.resolvePrefixRoute(command, args);
    if (!route) return false;
    if (route.error) {
      await message.reply(route.error).catch(() => {});
      return true;
    }

    const slash = client.commands?.get(route.category);
    if (!slash || typeof slash.run !== 'function') {
      await message
        .reply(`Unknown command \`$${command}\`. Try \`$help\` or \`/help\`.`)
        .catch(() => {});
      return true;
    }

    const values = parseValuesFromArgs(route.restArgs, message);
    // Music play song option name is "song"
    if (route.category === 'music' && route.sub === 'play' && route.restArgs.length) {
      values.strings.song = route.restArgs.join(' ');
    }
    // Volume level
    if (route.category === 'music' && route.sub === 'volume' && route.restArgs[0]) {
      const n = Number(route.restArgs[0]);
      if (Number.isFinite(n)) {
        values.strings.volume = String(n);
        values.integers.volume = n;
        values.numbers.volume = n;
        values.strings.amount = String(n);
        values.integers.amount = n;
      }
    }
    // DM invite by id(s)
    if (route.category === 'dminvite' && route.restArgs.length) {
      values.strings.ids = route.restArgs.join(' ');
    }
    // $ask / $say text options
    if (route.category === 'ask' && route.restArgs.length) {
      values.strings.question = route.restArgs.join(' ');
    }
    if (route.category === 'say' && route.restArgs.length) {
      values.strings.text = route.restArgs.join(' ');
    }
    // $rex ask <question>
    if (route.category === 'rex' && route.sub === 'ask' && route.restArgs.length) {
      values.strings.question = route.restArgs.join(' ');
    }
    // $rex voice <pick>
    if (route.category === 'rex' && route.sub === 'voice' && route.restArgs[0]) {
      values.strings.pick = route.restArgs[0];
    }
    // $rex mode on|off
    if (route.category === 'rex' && route.sub === 'mode' && route.restArgs[0]) {
      values.strings.setting = route.restArgs[0];
    }
    // Fun text commands
    if (route.restArgs.length && !values.strings.text) {
      values.strings.text = route.restArgs.join(' ');
    }

    const interaction = createMessageInteraction(message, {
      commandName: route.category,
      subcommand: route.topLevel ? null : route.sub,
      values,
    });

    console.log(
      `[prefix] $${command} → /${route.category}${route.sub ? ` ${route.sub}` : ''} by ${message.author.tag}`,
    );

    try {
      await slash.run(client, interaction, route.restArgs);
    } catch (err) {
      console.error(`[prefix] $${command} failed:`, err.message);
      const fail = `Failed: ${err.message}`.slice(0, 1800);
      if (interaction.deferred || interaction.replied) {
        await interaction.editReply({ content: fail }).catch(() =>
          message.reply(fail).catch(() => {}),
        );
      } else {
        await message.reply(fail).catch(() => {});
      }
    }
    return true;
  };

  console.log('[prefixBridge] Prefix command bridge ready ($ + slash surface)');
};
