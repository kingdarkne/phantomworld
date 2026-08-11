#!/usr/bin/env bash
# Run once from KataBump Console after switching Node to 18:
#   bash fix-node-modules.sh
set -euo pipefail
cd /home/container
echo "Node: $(node -v)"
echo "Removing node_modules (fixes canvas / NODE_MODULE_VERSION mismatch)…"
rm -rf node_modules
echo "Installing dependencies…"
npm install --omit=dev
echo "Done. Restart the server or run: node index.js"
