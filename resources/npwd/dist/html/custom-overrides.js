// Lightweight NPWD NUI overrides (no rebuild required).
// - Adds a safe "restart" handler that clears corrupted settings storage
// - Leaves the app logic untouched

(function () {
  function isPhoneRestartMessage(data) {
    if (!data || typeof data !== 'object') return false;
    // NPWD client sends: { app: 'PHONE', method: 'phoneRestart', data: {} }
    return data.app === 'PHONE' && data.method === 'phoneRestart';
  }

  async function clearNpwdStorage() {
    try {
      localStorage.clear();
    } catch (_) {}

    // Best-effort: clear indexedDB databases commonly used by NPWD/Mantine/localforage
    try {
      if (window.indexedDB && indexedDB.databases) {
        const dbs = await indexedDB.databases();
        await Promise.all(
          (dbs || []).map((db) => {
            if (!db || !db.name) return;
            try {
              indexedDB.deleteDatabase(db.name);
            } catch (_) {}
          })
        );
      }
    } catch (_) {}
  }

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!isPhoneRestartMessage(data)) return;

    // Clear storage then hard reload to rebuild defaults.
    clearNpwdStorage().finally(() => {
      try {
        location.reload();
      } catch (_) {}
    });
  });

  // Show "icon names" on the home grid by adding tooltips + small labels.
  // We can’t reliably target NPWD’s internal components without rebuilding,
  // so we do a best-effort pass over clickable icon buttons in the phone screen.
  function getLabelForEl(el) {
    if (!el) return null;
    const aria = el.getAttribute('aria-label');
    if (aria && aria.trim()) return aria.trim();
    const title = el.getAttribute('title');
    if (title && title.trim()) return title.trim();
    const txt = (el.textContent || '').trim();
    if (txt && txt.length <= 24) return txt;
    return null;
  }

  function ensureIconLabel(el) {
    if (!el || el.nodeType !== 1) return;
    if (el.dataset.npwdLabeled === '1') return;

    const label = getLabelForEl(el);
    if (!label) return;

    // tooltip on hover
    if (!el.getAttribute('title')) el.setAttribute('title', label);

    // Add a tiny label under icon if element seems like an icon-only button
    const hasTextNodes = Array.from(el.childNodes || []).some(
      (n) => n.nodeType === Node.TEXT_NODE && (n.textContent || '').trim().length > 0
    );
    if (!hasTextNodes) {
      const tag = document.createElement('div');
      tag.className = 'npwd-icon-label';
      tag.textContent = label;
      el.appendChild(tag);
    }

    el.dataset.npwdLabeled = '1';
  }

  function labelPass() {
    const root = document.getElementById('root');
    if (!root) return;
    // common clickable icon patterns: buttons, role buttons, anchors
    const els = root.querySelectorAll('button,[role="button"],a');
    els.forEach((el) => {
      // only inside the phone screen if possible
      const inPhone = el.closest && el.closest('.PhoneScreen');
      if (!inPhone) return;
      ensureIconLabel(el);
    });
  }

  // keep it updated as React renders
  const mo = new MutationObserver(() => {
    try {
      labelPass();
    } catch (_) {}
  });
  try {
    mo.observe(document.documentElement, { childList: true, subtree: true });
  } catch (_) {}

  // initial pass
  setTimeout(labelPass, 2500);
})();

