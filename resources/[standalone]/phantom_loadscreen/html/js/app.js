(() => {
  const $ = (id) => document.getElementById(id);
  const stages = [
    { at: 0.05, text: 'Saying hey to the city…' },
    { at: 0.2, text: 'Loading Phantom World…' },
    { at: 0.4, text: 'Spinning up vehicles & props…' },
    { at: 0.6, text: 'Syncing your session…' },
    { at: 0.8, text: 'Almost there — get ready…' },
    { at: 0.95, text: 'Welcome in!' },
  ];

  let tipIndex = 0;
  let musicOn = true;
  let lastFraction = 0;

  function applyConfig() {
    const c = window.Config || {};
    $('brand').textContent = c.brand || 'Phantom World';
    $('tagline').textContent = c.tagline || '';
    $('welcome').textContent = c.welcome || '';
    $('discord-label').textContent = c.discordLabel || 'Discord';
    $('cfx-label').textContent = c.cfxLabel || 'CFX Join';
    $('host').textContent = c.host || '';
    $('cta-discord').dataset.url = c.discord || '';
    $('cta-join').dataset.url = c.cfxJoin || '';
    if (c.backgroundImage) {
      $('sky').style.setProperty('--bg-image', `url("${c.backgroundImage}")`);
      $('sky').style.backgroundImage = `linear-gradient(160deg, rgba(7,16,24,.35), rgba(7,16,24,.72)), url("${c.backgroundImage}")`;
    }
    const audio = $('bgm');
    if (c.music && c.music.enabled) {
      audio.src = c.music.src;
      audio.volume = c.music.volume ?? 0.28;
      musicOn = true;
      tryPlay();
    } else {
      musicOn = false;
      $('music-btn').textContent = 'Music · Off';
    }
    rotateTip(true);
  }

  function rotateTip(instant) {
    const tips = (Config && Config.tips) || [];
    if (!tips.length) return;
    const el = $('tip');
    const next = () => {
      el.textContent = tips[tipIndex % tips.length];
      tipIndex += 1;
      el.classList.remove('is-fading');
    };
    if (instant) {
      next();
      return;
    }
    el.classList.add('is-fading');
    setTimeout(next, 320);
  }

  function setProgress(fraction) {
    fraction = Math.max(0, Math.min(1, Number(fraction) || 0));
    if (fraction + 0.0001 < lastFraction) return;
    lastFraction = fraction;
    const pct = Math.floor(fraction * 100);
    $('bar-fill').style.width = pct + '%';
    $('pct').textContent = pct + '%';
    $('bar-fill').parentElement.setAttribute('aria-valuenow', String(pct));
    let status = stages[0].text;
    for (const s of stages) {
      if (fraction >= s.at) status = s.text;
    }
    $('status').textContent = status;
  }

  function tryPlay() {
    const audio = $('bgm');
    if (!musicOn) return;
    const p = audio.play();
    if (p && p.catch) p.catch(() => {});
  }

  function toggleMusic() {
    const audio = $('bgm');
    musicOn = !musicOn;
    if (musicOn) {
      $('music-btn').textContent = 'Music · On';
      tryPlay();
    } else {
      audio.pause();
      $('music-btn').textContent = 'Music · Off';
    }
  }

  function openExternal(url) {
    if (!url) return;
    // FiveM loadscreen: invokeNative opens default browser
    try {
      if (typeof window.invokeNative === 'function') {
        window.invokeNative('openUrl', url);
        return;
      }
    } catch (_) {}
    window.open(url, '_blank');
  }

  window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.eventName === 'loadProgress' || data.eventName === 'loadProgressEvent') {
      setProgress(data.loadFraction);
    }
  });

  // Native handlers also fire as global handlers in some builds
  const handlers = {
    loadProgress(data) {
      setProgress(data && data.loadFraction);
    },
  };
  window.addEventListener('message', (e) => {
    const d = e.data;
    if (d && handlers[d.eventName]) handlers[d.eventName](d);
  });

  document.addEventListener('DOMContentLoaded', () => {
    applyConfig();
    $('music-btn').addEventListener('click', toggleMusic);
    document.querySelectorAll('.cta').forEach((el) => {
      el.addEventListener('click', (ev) => {
        ev.preventDefault();
        openExternal(el.dataset.url);
      });
    });
    // First gesture unlocks audio in CEF
    document.body.addEventListener('click', tryPlay, { once: true });
    setInterval(() => rotateTip(false), 6500);
    // Soft fake progress until real events arrive (keeps UI alive on slow handshakes)
    let soft = 0;
    const softTimer = setInterval(() => {
      if (lastFraction > 0.15) {
        clearInterval(softTimer);
        return;
      }
      soft = Math.min(0.12, soft + 0.004);
      if (soft > lastFraction) setProgress(soft);
    }, 400);
  });
})();
