// Simple fake progress so the screen feels alive until FiveM hides it
(function () {
  const progressText = document.getElementById('progress-text');
  let p = 0;

  const interval = setInterval(() => {
    if (p >= 99) {
      clearInterval(interval);
      return;
    }
    p += Math.floor(Math.random() * 4);
    if (p > 99) p = 99;
    if (progressText) {
      progressText.textContent = p + '%';
    }
  }, 800);
})();

// Volume control (slightly lower by default)
const music = document.getElementById('music');
if (music) {
  music.volume = 0.25;
}

// Optional: try City of Dreams music; if missing, keep music.ogg.
// This prevents the loading screen from breaking when the new files aren't present yet.
if (music && music.dataset && music.dataset.altSrc) {
  const altSrc = music.dataset.altSrc;
  const altAudio = new Audio();
  altAudio.src = altSrc;

  const startAlt = () => {
    // Attempt to switch; if autoplay is blocked, it'll silently fail and music.ogg will stay.
    music.src = altSrc;
    music.play().catch(() => {});
  };

  // `canplaythrough` means the browser can actually play it (not just that it exists).
 altAudio.addEventListener('canplaythrough', startAlt);
  altAudio.addEventListener('error', () => {
    // Keep default music.ogg
  });
}

// Optional: hide translucent City of Dreams background video if the file is missing.
const bgVideo = document.getElementById('bgVideo');
if (bgVideo) {
  bgVideo.addEventListener('error', () => {
    bgVideo.style.display = 'none';
  });
}

