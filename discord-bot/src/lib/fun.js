import { EmbedBuilder } from 'discord.js';

const EIGHT_BALL = [
  'Yes.', 'No.', 'Maybe.', 'Absolutely.', 'Not today.', 'Ask again later.',
  'Without a doubt.', 'Very doubtful.', 'Signs point to yes.', 'Nope.',
];

const JOKE_FALLBACK = [
  'Why did the scarecrow win an award? He was outstanding in his field.',
  'I told my server to chill. It said latency was already low.',
];

function giphyKey() {
  return process.env.GIPHY_API_KEY || process.env.GIPHY_TOKEN || '';
}

/**
 * AIO-style Giphy random/translate (from ALL-IN-ONE gif.js — REST, no giphy-api package).
 */
export async function fetchAioGif(searchText) {
  const term = (searchText || 'funny').trim() || 'funny';
  const key = giphyKey();

  if (key) {
    const endpoint = `https://api.giphy.com/v1/gifs/translate?api_key=${key}&s=${encodeURIComponent(term)}`;
    try {
      const res = await fetch(endpoint, { signal: AbortSignal.timeout(10_000) });
      if (res.ok) {
        const data = await res.json();
        const item = data?.data;
        const url =
          item?.images?.original?.url ||
          (item?.id ? `https://media1.giphy.com/media/${item.id}/giphy.gif` : null);
        if (url) {
          return { url, source: 'giphy', title: `📺・${term} Gif` };
        }
      }
    } catch {
      // fall through
    }

    try {
      const randomRes = await fetch(
        `https://api.giphy.com/v1/gifs/random?api_key=${key}&tag=${encodeURIComponent(term)}`,
        { signal: AbortSignal.timeout(10_000) },
      );
      if (randomRes.ok) {
        const data = await randomRes.json();
        const item = data?.data;
        const url =
          item?.images?.original?.url ||
          (item?.id ? `https://media1.giphy.com/media/${item.id}/giphy.gif` : null);
        if (url) return { url, source: 'giphy', title: `📺・${term} Gif` };
      }
    } catch {
      // fall through
    }
  }

  const url = await fetchRandomMemeUrl();
  return { url, source: 'reddit', title: term ? `📺・${term} Gif` : 'Random meme' };
}

export function buildGifEmbed({ url, source, title }) {
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(title || '📺・Gif')
    .setImage(url)
    .setFooter({ text: source === 'giphy' ? 'Giphy (AIO-style)' : 'Reddit r/memes fallback' });
}

export async function fetchJoke() {
  try {
    const res = await fetch('https://official-joke-api.appspot.com/random_joke', {
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) throw new Error('joke api');
    const data = await res.json();
    return `${data.setup}\n\n${data.punchline}`;
  } catch {
    return JOKE_FALLBACK[Math.floor(Math.random() * JOKE_FALLBACK.length)];
  }
}

export async function fetchRandomMemeUrl() {
  const res = await fetch('https://www.reddit.com/r/memes/hot.json?limit=50', {
    headers: { 'User-Agent': 'PhantomWorldBot/1.0' },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error('reddit fetch failed');
  const data = await res.json();
  const posts = (data?.data?.children || [])
    .map((c) => c.data)
    .filter((p) => {
      const url = p.url || '';
      return (
        !p.over_18 &&
        (url.includes('i.redd.it') || url.includes('i.imgur.com') || /\.(gif|jpg|jpeg|png|webp)$/i.test(url))
      );
    });
  if (!posts.length) throw new Error('no memes found');
  return posts[Math.floor(Math.random() * posts.length)].url;
}

/** @deprecated use fetchAioGif */
export async function fetchGifUrl(query) {
  return fetchAioGif(query);
}

export function eightBallAnswer(question) {
  const q = question?.trim() || 'something';
  const answer = EIGHT_BALL[Math.floor(Math.random() * EIGHT_BALL.length)];
  return `🎱 **${q}**\n${answer}`;
}
