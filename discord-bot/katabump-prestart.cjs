/**
 * Check node-canvas before full bot load (verify + image commands).
 */
function tryCanvas() {
  try {
    require('canvas');
    return true;
  } catch (err) {
    return err;
  }
}

const major = Number(process.version.slice(1).split('.')[0]);
if (major >= 24) {
  console.warn(
    '[Phantom World] Node',
    process.version,
    '— set KataBump Startup to Node **18** or **20**, delete `node_modules`, then Restart.',
  );
}

const canvasCheck = tryCanvas();
if (canvasCheck === true) {
  global.__PHANTOM_CANVAS_OK = true;
  console.log('[Phantom World] canvas OK for', process.version);
  return;
}

global.__PHANTOM_CANVAS_OK = false;
console.warn('[Phantom World] canvas failed:', canvasCheck.message);
console.warn(
  '[Phantom World] Bot will start, but verify captcha and some /images commands need Node 18 + fresh node_modules.',
);
console.warn('[Phantom World] See KATABUMP_NODE_FIX.md');
