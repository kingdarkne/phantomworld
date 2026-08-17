/**
 * Offline smoke for panel + billing helpers (no Discord).
 * Run inside Rex container: node scripts/smoke-hosting.js
 */
require('dotenv').config({ path: '/home/container/.env' });
require('dotenv').config();

const panel = require('../src/lib/panel-api');
const billing = require('../src/lib/billing-db');

(async () => {
  console.log('PANEL', panel.panelUrl());
  console.log('APP_KEY', panel.appKey() ? `set(${panel.appKey().length})` : 'MISSING');
  console.log('CLIENT_KEY', panel.clientKey() ? `set(${panel.clientKey().length})` : 'MISSING');
  console.log('BILLING', billing.billingConfigured());

  const users = await panel.listUsers({ perPage: 3 });
  console.log(
    'users',
    (users.data || []).map((u) => `${u.attributes.id}:${u.attributes.email}`),
  );

  const servers = await panel.listServers({ perPage: 5 });
  console.log(
    'servers',
    (servers.data || []).map((s) => `${s.attributes.id}:${s.attributes.identifier}:${s.attributes.name}`),
  );

  if (billing.billingConfigured()) {
    const plans = await billing.listPlans();
    console.log(
      'plans',
      plans.slice(0, 5).map((p) => `${p.id}:${p.name}`),
    );
    const clients = await billing.listClients({ limit: 5 });
    console.log(
      'clients',
      clients.map((c) => `${c.id}:${c.email}`),
    );
  }

  const first = servers.data?.[0]?.attributes;
  if (first && panel.clientKey()) {
    try {
      const res = await panel.getClientServerResources(first.identifier);
      console.log('resources', first.identifier, res.attributes?.current_state);
    } catch (e) {
      console.log('resources_fail', e.message);
    }
  }

  console.log('SMOKE_OK');
  process.exit(0);
})().catch((err) => {
  console.error('SMOKE_FAIL', err);
  process.exit(1);
});
