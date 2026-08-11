import { commandPrefix, createPrefixContext } from './context.js';
import { runCommand } from './handlers.js';
import { askAi } from './ai.js';

const ALIASES = {
  p: 'play',
  s: 'skip',
  q: 'queue',
  h: 'help',
  '?': '8ball',
  dminvite: 'dm-invite',
  'invite-dm': 'dm-invite',
  invite: 'dm-invite',
  tts: 'say',
  voice: 'say',
  speak: 'say',
};

export function startPrefixCommands(client, ctx) {
  const prefix = commandPrefix();
  const aiChannelId = process.env.DISCORD_AI_CHANNEL_ID || '';

  client.on('messageCreate', async (message) => {
    if (message.author.bot || !message.guild) return;

    const autoAi =
      aiChannelId &&
      message.channelId === aiChannelId &&
      !message.content.startsWith(prefix) &&
      message.content.trim().length > 2;

    if (autoAi) {
      try {
        const typing = message.channel.sendTyping?.();
        const answer = await askAi(message.content);
        if (typing) await typing;
        await message.reply(answer.slice(0, 2000));
      } catch (err) {
        console.warn('[prefix] AI channel reply failed:', err.message);
      }
      return;
    }

    if (!message.content.startsWith(prefix)) return;

    const body = message.content.slice(prefix.length).trim();
    if (!body) return;

    const args = body.split(/\s+/);
    const rawName = args.shift()?.toLowerCase();
    const name = ALIASES[rawName] || rawName;

    const c = createPrefixContext(message, [name, ...args], ctx);

    try {
      await runCommand(name, c);
    } catch (err) {
      const msg = err?.message || 'Command failed';
      console.warn(`[prefix] $${name} failed:`, msg);
      await message.reply(`Failed: ${msg}`).catch(() => {});
    }
  });

  console.log(`Prefix commands enabled (${prefix}help). AI auto-reply channel: ${aiChannelId || 'off'}`);
}
