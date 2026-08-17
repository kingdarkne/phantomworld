/**
 * Pterodactyl Application (+ optional Client) API for Phantom Hosting panel.
 * Credentials: PANEL_URL, PANEL_APP_API_KEY, PANEL_CLIENT_API_KEY
 */

function panelUrl() {
  return String(process.env.PANEL_URL || 'https://panel.phantom-chicken.com').replace(/\/$/, '');
}

function appKey() {
  return process.env.PANEL_APP_API_KEY || process.env.PTERODACTYL_APP_API_KEY || '';
}

function clientKey() {
  return process.env.PANEL_CLIENT_API_KEY || process.env.PTERODACTYL_CLIENT_API_KEY || '';
}

function requireAppKey() {
  if (!appKey()) throw new Error('PANEL_APP_API_KEY is not set');
}

async function appRequest(method, path, { query, body } = {}) {
  requireAppKey();
  const url = new URL(`${panelUrl()}${path.startsWith('/') ? path : `/${path}`}`);
  if (query) {
    for (const [k, v] of Object.entries(query)) {
      if (v != null && v !== '') url.searchParams.set(k, String(v));
    }
  }
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${appKey()}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: body != null ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  if (!res.ok) {
    const detail =
      json?.errors?.map((e) => e.detail || e.code).join('; ') ||
      json?.error ||
      text.slice(0, 400) ||
      res.statusText;
    const err = new Error(`Panel API ${res.status}: ${detail}`);
    err.status = res.status;
    err.body = json;
    throw err;
  }
  return json;
}

async function clientRequest(method, path, { body } = {}) {
  if (!clientKey()) throw new Error('PANEL_CLIENT_API_KEY is not set');
  const url = `${panelUrl()}${path.startsWith('/') ? path : `/${path}`}`;
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${clientKey()}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: body != null ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  if (!res.ok) {
    const detail =
      json?.errors?.map((e) => e.detail || e.code).join('; ') ||
      text.slice(0, 400) ||
      res.statusText;
    throw new Error(`Panel Client API ${res.status}: ${detail}`);
  }
  return json;
}

async function listUsers({ page = 1, perPage = 50, email } = {}) {
  const query = { page, per_page: perPage };
  if (email) query['filter[email]'] = email;
  return appRequest('GET', '/api/application/users', { query });
}

async function findUserByEmail(email) {
  const data = await listUsers({ email, perPage: 10 });
  const hit = (data.data || []).find(
    (u) => String(u.attributes?.email || '').toLowerCase() === String(email).toLowerCase(),
  );
  return hit || null;
}

async function getUser(id) {
  return appRequest('GET', `/api/application/users/${id}`);
}

async function createUser({ email, username, firstName, lastName, password, rootAdmin = false }) {
  return appRequest('POST', '/api/application/users', {
    body: {
      email,
      username,
      first_name: firstName || 'Customer',
      last_name: lastName || 'User',
      password,
      root_admin: !!rootAdmin,
    },
  });
}

async function updateUser(id, patch) {
  return appRequest('PATCH', `/api/application/users/${id}`, { body: patch });
}

async function deleteUser(id) {
  return appRequest('DELETE', `/api/application/users/${id}`);
}

async function listServers({ page = 1, perPage = 50 } = {}) {
  return appRequest('GET', '/api/application/servers', {
    query: { page, per_page: perPage },
  });
}

async function getServer(id) {
  return appRequest('GET', `/api/application/servers/${id}?include=allocations,user`);
}

async function findServer(idOrIdentifier) {
  const raw = String(idOrIdentifier).trim();
  if (/^\d+$/.test(raw)) {
    try {
      return await getServer(raw);
    } catch (_) {
      /* fall through */
    }
  }
  const listed = await listServers({ perPage: 100 });
  const hit = (listed.data || []).find(
    (s) =>
      String(s.attributes?.identifier) === raw ||
      String(s.attributes?.uuid || '').startsWith(raw) ||
      String(s.attributes?.name || '').toLowerCase() === raw.toLowerCase(),
  );
  if (!hit) throw new Error(`Server not found: ${raw}`);
  return getServer(hit.attributes.id);
}

async function deleteServer(id, { force = true } = {}) {
  return appRequest('DELETE', `/api/application/servers/${id}${force ? '?force=true' : ''}`);
}

async function suspendServer(id) {
  return appRequest('POST', `/api/application/servers/${id}/suspend`);
}

async function unsuspendServer(id) {
  return appRequest('POST', `/api/application/servers/${id}/unsuspend`);
}

async function updateServerDetails(id, { name, user, externalId, description }) {
  const body = {};
  if (name != null) body.name = name;
  if (user != null) body.user = Number(user);
  if (externalId != null) body.external_id = externalId;
  if (description != null) body.description = description;
  return appRequest('PATCH', `/api/application/servers/${id}/details`, { body });
}

async function getEgg(nestId, eggId) {
  return appRequest('GET', `/api/application/nests/${nestId}/eggs/${eggId}?include=variables`);
}

async function listNodeAllocations(nodeId, page = 1) {
  return appRequest('GET', `/api/application/nodes/${nodeId}/allocations`, {
    query: { page },
  });
}

async function findFreeAllocation(nodeId, { minPort, maxPort } = {}) {
  let page = 1;
  let pages = 1;
  while (page <= pages) {
    const data = await listNodeAllocations(nodeId, page);
    pages = data.meta?.pagination?.total_pages || 1;
    for (const alloc of data.data || []) {
      const a = alloc.attributes;
      if (a.assigned) continue;
      if (minPort && a.port < minPort) continue;
      if (maxPort && a.port > maxPort) continue;
      return a.id;
    }
    page += 1;
  }
  return null;
}

async function createServer(payload) {
  return appRequest('POST', '/api/application/servers', { body: payload });
}

async function powerServer(identifier, signal) {
  // Client API uses short identifier
  return clientRequest('POST', `/api/client/servers/${identifier}/power`, {
    body: { signal },
  });
}

async function getClientServerResources(identifier) {
  return clientRequest('GET', `/api/client/servers/${identifier}/resources`);
}

function randomPassword(len = 16) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%';
  let out = '';
  for (let i = 0; i < len; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}

function sanitizeUsername(email) {
  const local = String(email).split('@')[0] || 'user';
  let username = local.replace(/[^A-Za-z0-9]/g, '') + Math.random().toString(36).slice(2, 6);
  if (!username || /^admin/i.test(username)) username = `user${Math.random().toString(36).slice(2, 8)}`;
  return username.slice(0, 32);
}

module.exports = {
  panelUrl,
  appKey,
  clientKey,
  listUsers,
  findUserByEmail,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  listServers,
  getServer,
  findServer,
  deleteServer,
  suspendServer,
  unsuspendServer,
  updateServerDetails,
  getEgg,
  findFreeAllocation,
  createServer,
  powerServer,
  getClientServerResources,
  randomPassword,
  sanitizeUsername,
};
