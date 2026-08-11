function truthy(v) {
  return v === 'true' || v === '1';
}

function parseLavalinkNodes() {
  const nodes = [];

  const raw = process.env.LAVALINK_NODES;
  if (raw?.trim()) {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        for (const [i, n] of parsed.entries()) {
          const host = n.host || (typeof n.url === 'string' ? n.url.split(':')[0] : null);
          const port = Number(n.port || (typeof n.url === 'string' ? n.url.split(':').pop() : 2333));
          if (!host) continue;
          nodes.push({
            identifier: n.identifier || n.name || `node-${i}`,
            host,
            port,
            password: n.password || n.auth || 'youshallnotpass',
            secure: truthy(String(n.secure)),
          });
        }
      }
    } catch (e) {
      console.warn('[Lavalink] LAVALINK_NODES JSON invalid:', e.message);
    }
  }

  const selfHost = process.env.LAVALINK_SELF_HOST !== 'false';
  if (selfHost && process.env.LAVALINK_HOST) {
    nodes.push({
      identifier: 'primary',
      host: process.env.LAVALINK_HOST,
      port: Number(process.env.LAVALINK_PORT || 2333),
      password: process.env.LAVALINK_PASSWORD || 'youshallnotpass',
      secure: truthy(process.env.LAVALINK_SECURE || 'false'),
    });
  }

  const usePublic =
    process.env.LAVALINK_USE_PUBLIC === 'true' || (nodes.length === 0 && selfHost === false);

  if (usePublic || process.env.LAVALINK_USE_PUBLIC === 'true') {
    const fallbacks = [
      {
        identifier: 'jirayu',
        host: 'lavalink.jirayu.net',
        port: 443,
        password: 'youshallnotpass',
        secure: true,
      },
      {
        identifier: 'serenetia',
        host: 'lavalinkv4.serenetia.com',
        port: 443,
        password: 'https://dsc.gg/ajidevserver',
        secure: true,
      },
    ];
    for (const fb of fallbacks) {
      if (!nodes.some((n) => n.host === fb.host)) nodes.push(fb);
    }
  }

  if (!nodes.length) {
    console.warn(
      '[Lavalink] No nodes — set LAVALINK_HOST + LAVALINK_SELF_HOST=true, or LAVALINK_USE_PUBLIC=true',
    );
  } else {
    console.log(
      `[Lavalink] ${nodes.length} node(s): ${nodes.map((n) => `${n.identifier}@${n.host}:${n.port}`).join(', ')}`,
    );
  }

  return nodes;
}

module.exports = { parseLavalinkNodes };
