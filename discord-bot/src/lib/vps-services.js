/**
 * Phantom World — features that need a VPS (self-hosted Lavalink, etc.)
 */

const LAVALINK_PUBLIC_DEFAULT_HOST = 'lavalinkv4.serenetia.com';

function isTruthyEnv(val) {
    if (val == null || val === '') return false;
    const v = String(val).trim().toLowerCase();
    return v === 'true' || v === '1' || v === 'yes' || v === 'on';
}

function isSelfHostedLavalinkEnabled() {
    return isTruthyEnv(process.env.LAVALINK_SELF_HOST);
}

function isPublicLavalinkFallbackEnabled() {
    return isTruthyEnv(process.env.LAVALINK_USE_PUBLIC);
}

function isLavalinkNodeConnected(client) {
    // Check Shoukaku nodes (v4)
    if (client?.shoukaku?.nodes) {
        // Shoukaku v4 nodes is a Map
        for (const node of client.shoukaku.nodes.values()) {
            if (node.state === 1) return true; // 1 = CONNECTED
        }
    }
    
    // Fallback for old system if still used anywhere
    const nodes = client?.player?.nodes;
    if (nodes) {
        if (typeof nodes.filter === 'function') {
            return nodes.filter((n) => n.connected).length > 0;
        }
        if (Array.isArray(nodes)) {
            return nodes.some((n) => n.connected);
        }
    }
    
    return false;
}

/**
 * Music (/music) is available only when self-hosted Lavalink is enabled and a node is connected.
 */
function isMusicServiceAvailable(client) {
    if (!isSelfHostedLavalinkEnabled()) return false;
    return isLavalinkNodeConnected(client);
}

function getMusicUnavailableReason(client) {
    if (!isSelfHostedLavalinkEnabled()) return 'not_configured';
    if (!isLavalinkNodeConnected(client)) return 'not_connected';
    return null;
}

module.exports = {
    LAVALINK_PUBLIC_DEFAULT_HOST,
    isTruthyEnv,
    isSelfHostedLavalinkEnabled,
    isPublicLavalinkFallbackEnabled,
    isLavalinkNodeConnected,
    isMusicServiceAvailable,
    getMusicUnavailableReason,
};
