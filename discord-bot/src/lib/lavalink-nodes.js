const {
    isSelfHostedLavalinkEnabled,
    isPublicLavalinkFallbackEnabled,
    LAVALINK_PUBLIC_DEFAULT_HOST,
} = require('./vps-services');

/**
 * Lavalink node list for erela.js (KataBump bot).
 * Music stays disabled until LAVALINK_SELF_HOST=true (VPS Lavalink live).
 * Optional LAVALINK_USE_PUBLIC=true uses the public fallback node for testing only.
 */
function parseLavalinkNodes() {
    if (!isSelfHostedLavalinkEnabled() && !isPublicLavalinkFallbackEnabled()) {
        return [];
    }

    const raw = process.env.LAVALINK_NODES;
    if (raw?.trim()) {
        try {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed) && parsed.length) {
                return parsed.map((n, i) => ({
                    identifier: n.identifier || n.name || `node-${i + 1}`,
                    host: n.host,
                    port: Number(n.port),
                    password: n.password || n.auth,
                    secure: n.secure !== false && n.secure !== 'false' && n.secure !== 0,
                }));
            }
        } catch {
            console.warn('[Lavalink] LAVALINK_NODES is not valid JSON — using LAVALINK_HOST');
        }
    }

    const host = process.env.LAVALINK_HOST || LAVALINK_PUBLIC_DEFAULT_HOST;

    return [
        {
            identifier: 'primary',
            host,
            port: parseInt(process.env.LAVALINK_PORT, 10) || 443,
            password: process.env.LAVALINK_PASSWORD || 'https://dsc.gg/ajidevserver',
            secure: process.env.LAVALINK_SECURE !== 'false' && process.env.LAVALINK_SECURE !== '0',
        },
    ];
}

module.exports = { parseLavalinkNodes };
