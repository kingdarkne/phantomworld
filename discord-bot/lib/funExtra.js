const waifu = (type) => `https://api.waifu.pics/sfw/${type}`;

async function json(url) {
  const res = await fetch(url, { signal: AbortSignal.timeout(12000) });
  if (!res.ok) throw new Error(`API HTTP ${res.status}`);
  return res.json();
}

export async function funHug(targetTag) {
  const data = await json(waifu('hug'));
  return { content: `**Hugs** ${targetTag}!`, image: data.url };
}

export async function funKiss(targetTag) {
  const data = await json(waifu('kiss'));
  return { content: `**Kisses** ${targetTag}!`, image: data.url };
}

export async function funPat(targetTag) {
  const data = await json(waifu('pat'));
  return { content: `**Pats** ${targetTag}`, image: data.url };
}

export async function funSlap(targetTag) {
  const data = await json(waifu('slap'));
  return { content: `**Slaps** ${targetTag}!`, image: data.url };
}

export async function funMeme() {
  const data = await json('https://meme-api.com/gimme');
  return {
    title: data.title || 'Meme',
    image: data.url,
    url: data.postLink,
    footer: data.subreddit ? `r/${data.subreddit}` : undefined,
  };
}

export function funHowGay(userTag) {
  const pct = Math.floor(Math.random() * 101);
  return `${userTag} is **${pct}%** gay 🌈`;
}

export function funLoveMeter(a, b) {
  const pct = Math.floor(Math.random() * 101);
  return `**${a}** + **${b}** = **${pct}%** love`;
}

export async function funFact() {
  const data = await json('https://uselessfacts.jsph.pl/api/v2/facts/random?language=en');
  return data.text || 'No fact today.';
}

export async function funDog() {
  const data = await json('https://dog.ceo/api/breeds/image/random');
  return data.message;
}

export async function funCat() {
  const data = await json('https://api.thecatapi.com/v1/images/search');
  return data?.[0]?.url || null;
}

export function funRoast(targetTag) {
  const roasts = [
    `${targetTag}'s Wi-Fi password is probably "password".`,
    `${targetTag} brings a knife to a gunfight and still loses.`,
    `${targetTag}'s favorite game is lag simulator.`,
    `${targetTag} has the reaction time of a Windows update.`,
    `${targetTag} could get lost in a one-block Minecraft world.`,
  ];
  return roasts[Math.floor(Math.random() * roasts.length)];
}

export async function funAscii(text) {
  const figlet = await import('figlet');
  const fn = figlet.default || figlet;
  return await new Promise((resolve, reject) => {
    fn.text(String(text).slice(0, 24), { font: 'Standard' }, (err, data) => {
      if (err) reject(err);
      else resolve(data);
    });
  });
}
