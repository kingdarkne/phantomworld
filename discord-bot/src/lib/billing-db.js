/**
 * Read/write helper for HedystiaBilling MySQL (Phantom Hosting).
 * Uses BILLING_DB_* env vars already present on the Rex host.
 */

let pool = null;

function billingConfigured() {
  return !!(process.env.BILLING_DB_HOST && process.env.BILLING_DB_USER && process.env.BILLING_DB_NAME);
}

function getPool() {
  if (!billingConfigured()) {
    throw new Error('BILLING_DB_* env vars are not set');
  }
  if (pool) return pool;
  // eslint-disable-next-line global-require
  const mysql = require('mysql2/promise');
  pool = mysql.createPool({
    host: process.env.BILLING_DB_HOST,
    port: Number(process.env.BILLING_DB_PORT || 3306),
    user: process.env.BILLING_DB_USER,
    password: process.env.BILLING_DB_PASSWORD || '',
    database: process.env.BILLING_DB_NAME || 'billing',
    waitForConnections: true,
    connectionLimit: 4,
  });
  return pool;
}

async function query(sql, params = []) {
  const [rows] = await getPool().execute(sql, params);
  return rows;
}

async function listClients({ limit = 25, email } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 25, 1), 100);
  if (email) {
    return query(
      `SELECT id, email, first_name, last_name, user_id, credit, is_active, is_admin, created_at
       FROM clients WHERE email LIKE ? ORDER BY id DESC LIMIT ${lim}`,
      [`%${email}%`],
    );
  }
  return query(
    `SELECT id, email, first_name, last_name, user_id, credit, is_active, is_admin, created_at
     FROM clients ORDER BY id DESC LIMIT ${lim}`,
  );
}

async function getClientByEmail(email) {
  const rows = await query(`SELECT * FROM clients WHERE email = ? LIMIT 1`, [email]);
  return rows[0] || null;
}

async function getClientById(id) {
  const rows = await query(`SELECT * FROM clients WHERE id = ? LIMIT 1`, [Number(id)]);
  return rows[0] || null;
}

async function linkClientPanelUser(clientId, panelUserId) {
  await query(`UPDATE clients SET user_id = ? WHERE id = ?`, [
    Number(panelUserId),
    Number(clientId),
  ]);
}

async function listBillingServers({ limit = 25, clientId } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 25, 1), 100);
  if (clientId) {
    return query(
      `SELECT id, server_id, identifier, client_id, plan_id, server_name, nest_id, egg_id, node_id, status, due_date, created_at
       FROM servers WHERE client_id = ? ORDER BY id DESC LIMIT ${lim}`,
      [Number(clientId)],
    );
  }
  return query(
    `SELECT id, server_id, identifier, client_id, plan_id, server_name, nest_id, egg_id, node_id, status, due_date, created_at
     FROM servers ORDER BY id DESC LIMIT ${lim}`,
  );
}

async function getBillingServer(idOrIdentifier) {
  const raw = String(idOrIdentifier).trim();
  if (/^\d+$/.test(raw)) {
    const byId = await query(`SELECT * FROM servers WHERE id = ? OR server_id = ? LIMIT 1`, [
      Number(raw),
      Number(raw),
    ]);
    if (byId[0]) return byId[0];
  }
  const byIdent = await query(`SELECT * FROM servers WHERE identifier = ? LIMIT 1`, [raw]);
  return byIdent[0] || null;
}

async function markBillingServerDeleted(panelServerId) {
  await query(`UPDATE servers SET status = 2, updated_at = NOW() WHERE server_id = ?`, [
    Number(panelServerId),
  ]);
}

async function insertBillingServerRow({
  serverId,
  identifier,
  clientId,
  planId,
  planCycle,
  serverName,
  nestId,
  eggId,
  locationId,
  nodeId,
}) {
  await query(
    `INSERT INTO servers
      (server_id, identifier, client_id, plan_id, plan_cycle, due_date, payment_method, server_name, nest_id, egg_id, location_id, node_id, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY), 'admin', ?, ?, ?, ?, ?, 0, NOW(), NOW())`,
    [
      Number(serverId),
      identifier,
      Number(clientId),
      Number(planId),
      Number(planCycle),
      serverName,
      Number(nestId),
      Number(eggId),
      Number(locationId),
      Number(nodeId),
    ],
  );
}

async function listPlans() {
  return query(
    `SELECT id, name, description, ram, cpu, disk, swap, io, databases, backups, extra_ports, locations_nodes_id, nests_eggs_id, min_port, max_port
     FROM plans ORDER BY \`order\` ASC, id ASC`,
  );
}

async function getPlan(id) {
  const rows = await query(`SELECT * FROM plans WHERE id = ? LIMIT 1`, [Number(id)]);
  return rows[0] || null;
}

async function getPlanCycle(planId) {
  const rows = await query(
    `SELECT * FROM plan_cycles WHERE plan_id = ? ORDER BY id ASC LIMIT 1`,
    [Number(planId)],
  );
  return rows[0] || null;
}

async function listRecentInvoices({ limit = 15, clientId } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 15, 1), 50);
  if (clientId) {
    return query(
      `SELECT id, client_id, server_id, total, paid, due_date, payment_method, created_at
       FROM invoices WHERE client_id = ? ORDER BY id DESC LIMIT ${lim}`,
      [Number(clientId)],
    );
  }
  return query(
    `SELECT id, client_id, server_id, total, paid, due_date, payment_method, created_at
     FROM invoices ORDER BY id DESC LIMIT ${lim}`,
  );
}

function parseNestEgg(plan, preferred) {
  let list = [];
  try {
    list = JSON.parse(plan.nests_eggs_id || '[]');
  } catch {
    list = [];
  }
  const pick = preferred || list[0];
  if (!pick) throw new Error('Plan has no nest:egg options');
  const [nestId, eggId] = String(pick).split(':').map(Number);
  if (!nestId || !eggId) throw new Error(`Invalid nest:egg "${pick}"`);
  return { nestId, eggId };
}

function parseNode(plan, preferredNode) {
  let list = [];
  try {
    list = JSON.parse(plan.locations_nodes_id || '[]');
  } catch {
    list = [];
  }
  const pick = list[0];
  if (!pick && !preferredNode) throw new Error('Plan has no location:node options');
  const parts = String(pick || '1:1').split(':').map(Number);
  const locationId = parts[0] || 1;
  const nodeId = preferredNode || parts[1];
  if (!nodeId) throw new Error(`Invalid location:node "${pick}"`);
  return { locationId, nodeId };
}

module.exports = {
  billingConfigured,
  query,
  listClients,
  getClientByEmail,
  getClientById,
  linkClientPanelUser,
  listBillingServers,
  getBillingServer,
  markBillingServerDeleted,
  insertBillingServerRow,
  listPlans,
  getPlan,
  getPlanCycle,
  listRecentInvoices,
  parseNestEgg,
  parseNode,
};
