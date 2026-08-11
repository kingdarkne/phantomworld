import { EmbedBuilder } from 'discord.js';

export function coinFlip() {
  return Math.random() < 0.5 ? '🪙 Heads' : '🪙 Tails';
}

export function rollDice(max) {
  const n = Math.max(2, Math.min(1000, Number(max) || 6));
  return `🎲 Rolled **${Math.floor(Math.random() * n) + 1}** (1–${n})`;
}

export function pickChoice(optionsText) {
  const parts = optionsText.split(/,|\|/).map((s) => s.trim()).filter(Boolean);
  if (parts.length < 2) throw new Error('Give at least 2 options separated by commas.');
  return `🎯 **${parts[Math.floor(Math.random() * parts.length)]}**`;
}

export async function buildAvatarEmbed(user) {
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(user.displayName || user.username)
    .setImage(user.displayAvatarURL({ size: 512 }))
    .setTimestamp();
}

export function buildPoll(question, optionsText) {
  const opts = optionsText.split(/,|\|/).map((s) => s.trim()).filter(Boolean).slice(0, 5);
  if (opts.length < 2) throw new Error('Poll needs at least 2 options.');
  const emojis = ['1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣'];
  const lines = opts.map((o, i) => `${emojis[i]} ${o}`);
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle('📊 ' + question)
    .setDescription(lines.join('\n'))
    .setFooter({ text: 'React with numbers in chat or use options as discussion' });
}
