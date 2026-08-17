/**
 * Rolling store for FiveM stability signals (errors, stuck, restarts).
 * Written by aio-bridge; read by /stability.
 */
const fs = require('fs');
const path = require('path');

const STORE_PATH = path.join(process.cwd(), 'data', 'stability-events.json');
const MAX_EVENTS = 200;

function load() {
  try {
    const raw = JSON.parse(fs.readFileSync(STORE_PATH, 'utf8'));
    return Array.isArray(raw.events) ? raw.events : [];
  } catch {
    return [];
  }
}

function save(events) {
  fs.mkdirSync(path.dirname(STORE_PATH), { recursive: true });
  fs.writeFileSync(STORE_PATH, JSON.stringify({ updatedAt: Date.now(), events }, null, 2));
}

function recordEvent(entry) {
  const events = load();
  events.push({
    at: Date.now(),
    category: String(entry.category || 'info').toLowerCase(),
    title: String(entry.title || '').slice(0, 120),
    description: String(entry.description || '').slice(0, 240),
  });
  while (events.length > MAX_EVENTS) events.shift();
  save(events);
  return events.length;
}

function recentEvents({ sinceMs = 60 * 60 * 1000 } = {}) {
  const cutoff = Date.now() - sinceMs;
  return load().filter((e) => e.at >= cutoff);
}

function countByCategory(sinceMs) {
  const counts = {};
  for (const e of recentEvents({ sinceMs })) {
    counts[e.category] = (counts[e.category] || 0) + 1;
  }
  return counts;
}

module.exports = {
  recordEvent,
  recentEvents,
  countByCategory,
  STORE_PATH,
};
