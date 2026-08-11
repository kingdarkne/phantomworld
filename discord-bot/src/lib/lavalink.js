import { Shoukaku, Connectors } from 'shoukaku';

/** @type {Shoukaku | null} */
let shoukaku = null;

function parseNodesFromEnv() {
  const raw = process.env.LAVALINK_NODES;
  if (raw?.trim()) {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length) return parsed;
    } catch {
      console.warn('LAVALINK_NODES is not valid JSON — using defaults');
    }
  }

  const host = process.env.LAVALINK_HOST || 'lavalinkv4.serenetia.com';
  const port = Number(process.env.LAVALINK_PORT || 443);
  const password = process.env.LAVALINK_PASSWORD || 'https://dsc.gg/ajidevserver';
  const secure = process.env.LAVALINK_SECURE !== 'false' && process.env.LAVALINK_SECURE !== '0';

  const nodes = [
    {
      name: 'primary',
      url: `${host}:${port}`,
      auth: password,
      secure,
    },
  ];

  // Fallback public Lavalink v4 nodes (jirayu and others often go offline)
  const fallbacks = [
    {
      name: 'serenetia-v4',
      url: 'lavalinkv4.serenetia.com:443',
      auth: 'https://dsc.gg/ajidevserver',
      secure: true,
    },
    {
      name: 'jirayu',
      url: 'lavalink.jirayu.net:443',
      auth: 'youshallnotpass',
      secure: true,
    },
  ];

  for (const fb of fallbacks) {
    const dup = nodes.some((n) => n.url === fb.url && n.auth === fb.auth);
    if (!dup) nodes.push(fb);
  }

  return nodes;
}

export function initLavalink(client) {
  const nodes = parseNodesFromEnv();

  shoukaku = new Shoukaku(new Connectors.DiscordJS(client), nodes, {
    moveOnDisconnect: false,
    resume: true,
    reconnectTries: 8,
    reconnectInterval: 4000,
    restTimeout: 60_000,
    voiceConnectionTimeout: 30_000,
  });

  shoukaku.on('ready', (name) => {
    const node = shoukaku.nodes.get(name);
    const url = node?.url || name;
    console.log(`Lavalink node "${name}" connected (${url})`);
  });

  shoukaku.on('error', (name, error) => {
    console.warn(`Lavalink node "${name}" error:`, error?.message || error);
  });

  shoukaku.on('close', (name, code, reason) => {
    console.warn(`Lavalink node "${name}" closed (${code}):`, reason || 'no reason');
  });

  shoukaku.on('disconnect', (name, count) => {
    console.warn(`Lavalink node "${name}" disconnected (attempt ${count})`);
  });

  console.log(
    `Lavalink: ${nodes.length} node(s) configured — ${nodes.map((n) => n.name).join(', ')}`,
  );

  return shoukaku;
}

export function getLavalink() {
  return shoukaku;
}

export function lavalinkReady() {
  return Boolean(shoukaku?.getIdealNode());
}

/** Wait for any Lavalink node (music /play). */
export function waitForLavalink(ms = 25_000) {
  if (lavalinkReady()) return Promise.resolve(true);
  return new Promise((resolve) => {
    const start = Date.now();
    const tick = () => {
      if (lavalinkReady()) {
        resolve(true);
        return;
      }
      if (Date.now() - start >= ms) {
        resolve(false);
        return;
      }
      setTimeout(tick, 500);
    };
    tick();
  });
}
