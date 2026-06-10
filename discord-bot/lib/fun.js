const EIGHT_BALL = [
  'Yes.', 'No.', 'Maybe.', 'Absolutely.', 'Not today.', 'Ask again later.',
  'Without a doubt.', 'Very doubtful.', 'Signs point to yes.', 'Nope.',
];

const JOKE_FALLBACK = [
  'Why did the scarecrow win an award? He was outstanding in his field.',
  'I told my server to chill. It said latency was already low.',
];

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

export async function fetchGifUrl(query) {
  const giphyKey = process.env.GIPHY_API_KEY;
  if (giphyKey && query) {
    const url = `https://api.giphy.com/v1/gifs/translate?api_key=${giphyKey}&s=${encodeURIComponent(query)}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
    if (res.ok) {
      const data = await res.json();
      const gif = data?.data?.images?.original?.url;
      if (gif) return gif;
    }
  }
  return await fetchRandomMemeUrl();
}

export function eightBallAnswer(question) {
  const q = question?.trim() || 'something';
  const answer = EIGHT_BALL[Math.floor(Math.random() * EIGHT_BALL.length)];
  return `🎱 **${q}**\n${answer}`;
}
