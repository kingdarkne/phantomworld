/*
  ------------------------------------------------------------------------------------------------
    Next Death - Advanced death system
  ------------------------------------------------------------------------------------------------
  _   _ ________   _________ _____ ____  _____  ______ 
 | \ | |  ____\ \ / /__   __/ ____/ __ \|  __ \|  ____|
 |  \| | |__   \ V /   | | | |   | |  | | |__) | |__   
 | . ` |  __|   > <    | | | |   | |  | |  _  /|  __|  
 | |\  | |____ / . \   | | | |___| |__| | | \ \| |____ 
 |_| \_|______/_/ \_\  |_|  \_____\____/|_|  \_\______|                                                       
                                                       
  ------------------------------------------------------------------------------------------------
    Created for Nextcore Studio by Junnho
  ------------------------------------------------------------------------------------------------
    
    Author: Nextcore Studio
    Copyright © 2025 Junnho. All rights reserved.
    Copyright © 2025 Nextcore Studio. All rights reserved.
    License: EULA (see LICENSE file)
    
    Documentation: https://www.nextcorestudio.com/docs/next-death/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-death/?from=homepage
    Tebex: https://nextcorestudio.tebex.io/package/7057654

--------------------------------------------------------------------------------------------------
*/

const overlay = document.getElementById('overlay');
const panel = document.querySelector('.panel');
const bleedoutValue = document.getElementById('bleedoutValue');
const early = document.getElementById('early');
const earlyValue = document.getElementById('earlyValue');
const called = document.getElementById('called');
const bleedoutBar = document.getElementById('bleedoutBar');
const earlyBar = document.getElementById('earlyBar');
const centerTitle = document.getElementById('centerTitle');
const centerInfo = document.getElementById('centerInfo');
const bottomBar = document.getElementById('bottomBar');
const damageVignette = document.getElementById('damage-vignette');
const centerEarlyValue = document.getElementById('centerEarlyValue');
const callBtn = document.getElementById('callBtn');
const respawnBtn = document.getElementById('respawnBtn');

var translations = {};
var currentLocale = 'en';

function _(key, ...args) {
    const text = translations[key] || key;
    if (args.length > 0) {
        return text.replace(/%s/g, () => args.shift());
    }
    return text;
}

function setTranslations(newTranslations, locale) {
    translations = newTranslations || {};
    currentLocale = locale || 'en';
    updateMainUITexts();
}

function updateMainUITexts() {
    if (centerTitle) centerTitle.textContent = _('you_are_unconscious');
    const centerHint = document.getElementById('centerHint');
    if (centerHint) centerHint.textContent = _('it_will_take_time');
    if (called) called.textContent = _('alert_sent_to_ems');
    if (callBtn) callBtn.innerHTML = _('call_emergency_services') + ' <span class="hintSmall">(E)</span>';
    if (respawnBtn) respawnBtn.innerHTML = _('respawn') + ' <span class="hintSmall">(R)</span>';
}

const blink = document.getElementById('blink');
const eyelidTop = document.getElementById('eyelidTop');
const eyelidBottom = document.getElementById('eyelidBottom');
const blinkVignette = document.getElementById('blinkVignette');
const eyeEllipse = document.getElementById('eyeEllipse');
let eyeOpenRx = eyeEllipse ? Number(eyeEllipse.getAttribute('rx')) || 520 : 520;
let eyeOpenRy = eyeEllipse ? Number(eyeEllipse.getAttribute('ry')) || 360 : 360;

let allowEarly = true;
let blinkTimer = null;
let blinkActive = false;
let blinkRunning = false;
const defaultBlink = { minIntervalMs: 700, maxIntervalMs: 1600, durationMs: 2800, closedPauseMs: 700, vignetteOpacity: 0.5 };
const blinkProfiles = [
    
    { minIntervalMs: 800, maxIntervalMs: 1800, durationMs: 3200, closedPauseMs: 800 },
    { minIntervalMs: 900, maxIntervalMs: 2000, durationMs: 3600, closedPauseMs: 900 },
    { minIntervalMs: 1000, maxIntervalMs: 2200, durationMs: 4000, closedPauseMs: 1000 },
    { minIntervalMs: 1200, maxIntervalMs: 2500, durationMs: 4500, closedPauseMs: 1200 },
];

function pickRandomProfile() {
    return blinkProfiles[Math.floor(Math.random() * blinkProfiles.length)];
}
let blinkCfg = { ...defaultBlink };

function msToClock(ms) {
    const total = Math.max(0, Math.floor(ms / 1000));
    const m = Math.floor(total / 60).toString().padStart(2, '0');
    const s = (total % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
}

function postNui(event, body) {
    try {
        window.fetch(`https://next_death/${event}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) });
    } catch (_) {   }
}

function openExternalUrl(url) {
    if (!url) return;
    try {
        if (typeof window.invokeNative === 'function') {
            window.invokeNative('openUrl', url);
        } else {
            window.open(url, '_blank');
        }
    } catch (_) {
        try { window.open(url, '_blank'); } catch (__) { }
    }
}

function applyBlinkVars() {
    if (!blink) return;
    blink.style.setProperty('--blink-duration', ((blinkCfg && blinkCfg.durationMs) || 900) + 'ms');
    const vg = Math.max(0, Math.min(1, (blinkCfg && blinkCfg.vignetteOpacity) ?? 0.38));
    blink.style.setProperty('--vignette-opacity', String(vg));
}

function scheduleBlink() {
    if (!blinkActive) return;
    const profile = pickRandomProfile();
    const { minIntervalMs, maxIntervalMs, durationMs, closedPauseMs } = profile;
    blinkCfg = { ...blinkCfg, minIntervalMs, maxIntervalMs, durationMs, closedPauseMs };
    if (blink) blink.style.setProperty('--blink-duration', String(durationMs) + 'ms');
    const min = Math.max(300, (blinkCfg && blinkCfg.minIntervalMs) || 700);
    const max = Math.max(min + 300, (blinkCfg && blinkCfg.maxIntervalMs) || 1600);
    const delay = Math.floor(Math.random() * (max - min + 1)) + min;
    clearTimeout(blinkTimer);
    blinkTimer = setTimeout(doBlink, delay);
}

function animateEye(closeDurationMs, openDurationMs) {
    if (!eyeEllipse) return Promise.resolve();
    const startRy = eyeOpenRy;
    const endRy = 0.001;
    const startRx = eyeOpenRx;
    const endRx = eyeOpenRx;

    const easeIn = (t) => t * t;
    const easeOut = (t) => 1 - Math.pow(1 - t, 2);

    const setEllipse = (rx, ry) => {
        eyeEllipse.setAttribute('rx', String(Math.max(0.001, rx)));
        eyeEllipse.setAttribute('ry', String(Math.max(0.001, ry)));
    };

    const setVignetteOpacity = (opacity) => {
        if (blink) blink.style.setProperty('--vignette-opacity', String(opacity));
    };

    setEllipse(startRx, startRy);

    return new Promise((resolve) => {
        const t0 = performance.now();
        const stepClose = (now) => {
            if (!blinkActive) { resolve(); return; }
            const t = Math.min(1, (now - t0) / Math.max(1, closeDurationMs));
            const k = easeIn(t);
            const ry = startRy + (endRy - startRy) * k;
            const vignetteOpacity = 0.5 + (0.5 * k);
            setEllipse(startRx, ry);
            setVignetteOpacity(vignetteOpacity);
            if (t < 1) {
                requestAnimationFrame(stepClose);
            } else {
                const t1 = performance.now();
                const stepOpen = (now2) => {
                    if (!blinkActive) { resolve(); return; }
                    const tO = Math.min(1, (now2 - t1) / Math.max(1, openDurationMs));
                    const kO = easeOut(tO);
                    const ryO = endRy + (startRy - endRy) * kO;
                    const vignetteOpacity = 1.0 - (0.5 * kO);
                    setEllipse(startRx, ryO);
                    setVignetteOpacity(vignetteOpacity);
                    if (tO < 1) requestAnimationFrame(stepOpen); else resolve();
                };
                requestAnimationFrame(stepOpen);
            }
        };
        requestAnimationFrame(stepClose);
    });
}

function doBlink() {
    if (!blinkActive || !blink || blinkRunning) return;
    blinkRunning = true;
    const total = Math.max(800, (blinkCfg && blinkCfg.durationMs) || 1800);
    const closedPause = Math.max(0, (blinkCfg && blinkCfg.closedPauseMs) || 260);
    const half = Math.floor((total - closedPause) / 2);
    animateEye(half, half).then(() => {
        blinkRunning = false;
        if (!blinkActive) return;
        setTimeout(() => {
            if (!blinkActive) return;
            scheduleBlink();
        }, closedPause);
    });
}

function startBlinking(cfg) {
    blinkActive = true;
    const initial = pickRandomProfile();
    const merged = { ...defaultBlink, ...initial, ...(cfg && typeof cfg === 'object' ? cfg : {}) };
    merged.vignetteOpacity = defaultBlink.vignetteOpacity;
    blinkCfg = merged;
    applyBlinkVars();
    clearTimeout(blinkTimer);
    if (blink) blink.classList.add('active');
    setTimeout(doBlink, 250);
    scheduleBlink();
}

function stopBlinking() {
    blinkActive = false;
    clearTimeout(blinkTimer);
    blinkRunning = false;
    if (blink) {
        blink.classList.remove('blink');
        blink.classList.remove('active');
        blink.style.setProperty('--vignette-opacity', '0');
        if (eyeEllipse) {
            eyeEllipse.setAttribute('rx', String(eyeOpenRx));
            eyeEllipse.setAttribute('ry', String(eyeOpenRy));
        }
    }
}

function forceStopBlinking() {
    blinkActive = false;
    clearTimeout(blinkTimer);
    blinkRunning = false;
    if (blink) {
        blink.classList.remove('blink');
        blink.classList.remove('active');
        blink.style.setProperty('--vignette-opacity', '0');
        if (eyeEllipse) {
            eyeEllipse.setAttribute('rx', String(eyeOpenRx));
            eyeEllipse.setAttribute('ry', String(eyeOpenRy));
        }
        blink.style.removeProperty('--blink-duration');
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') {
        allowEarly = !!data.allowEarly;
        if (data.translations) {
            setTranslations(data.translations, data.locale);
        }
        overlay.classList.remove('hidden');
        if (panel) panel.classList.add('show');
        if (centerTitle) centerTitle.style.opacity = '0.7';
        if (centerInfo) centerInfo.style.opacity = '0.7';
        startBlinking(data && data.blink);
        called.style.display = 'none';
        if (respawnBtn) { respawnBtn.disabled = true; respawnBtn.classList.remove('enabled'); }
        if (!allowEarly) {
            if (early) early.style.display = 'none';
            if (centerEarlyValue) centerEarlyValue.style.display = 'none';
        } else {
            if (early) early.style.display = '';
            if (centerEarlyValue) centerEarlyValue.style.display = '';
        }
    } else if (data.action === 'update') {
        const bleedClock = msToClock(data.remainBleed || 0);
        if (bleedoutValue) bleedoutValue.textContent = bleedClock;
        if (typeof data.bleedoutMs === 'number' && (bleedoutBar || bottomBar)) {
            const total = Math.max(1, data.bleedoutMs);
            const remain = Math.max(0, data.remainBleed || 0);
            const pct = Math.max(0, Math.min(100, Math.round(((total - remain) / total) * 100)));
            if (bleedoutBar) bleedoutBar.style.width = pct + '%';
            if (bottomBar) bottomBar.style.width = pct + '%';
        }
        const earlyClock = msToClock(data.remainEarly || 0);
        const canRespawn = allowEarly && (data.remainEarly || 0) <= 0;
        if (allowEarly) {
            if (earlyValue) earlyValue.textContent = earlyClock;
            if (centerEarlyValue) centerEarlyValue.textContent = earlyClock;
            if (typeof data.earlyMs === 'number' && earlyBar) {
                const totalE = Math.max(1, data.earlyMs);
                const remainE = Math.max(0, data.remainEarly || 0);
                const pctE = Math.max(0, Math.min(100, Math.round(((totalE - remainE) / totalE) * 100)));
                earlyBar.style.width = pctE + '%';
            }
            if (centerEarlyValue) centerEarlyValue.style.display = '';
        } else {
            if (centerEarlyValue) centerEarlyValue.style.display = 'none';
        }
        if (respawnBtn) {
            respawnBtn.disabled = !canRespawn;
            respawnBtn.classList.toggle('enabled', canRespawn);
        }
    } else if (data.action === 'called') {
        called.style.display = '';
    } else if (data.action === 'close') {
        if (panel) panel.classList.remove('show');
        if (centerTitle) centerTitle.style.opacity = '0';
        if (centerInfo) centerInfo.style.opacity = '0';
        forceStopBlinking();
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 220);
    } else if (data.action === 'forceStopBlinking') {
        forceStopBlinking();
    } else if (data.action === 'showDamageVignette') {
        showDamageVignette(data);
    } else if (data.action === 'hideDamageVignette') {
        hideDamageVignette();
    } else if (data.action === 'showHelpMessage') {
        showHelpMessages(data.messages || []);
    } else if (data.action === 'hideHelpMessage') {
        hideHelpMessagesInteraction();
    }
});

if (callBtn) {
    callBtn.addEventListener('click', () => postNui('callEMS'));
}
if (respawnBtn) {
    respawnBtn.addEventListener('click', () => postNui('respawn'));
}

document.addEventListener('DOMContentLoaded', function () {
    try { postNui('uiReady'); } catch (_) { }
});

document.addEventListener('click', function (event) {
    if (!event || !event.target || typeof event.target.closest !== 'function') return;
    const link = event.target.closest('.discord-link');
    if (!link) return;

    event.preventDefault();
    const url = link.getAttribute('href');
    if (!url) return;

    openExternalUrl(url);
});

function showDamageVignette(data) {
    if (damageVignette) {
        if (data && data.color && data.opacity) {
            const opacity = data.opacity / 100;
            const colorMap = {
                'black': `rgba(0, 0, 0, ${opacity})`,
                'red': `rgba(255, 0, 0, ${opacity})`,
                'blue': `rgba(0, 0, 255, ${opacity})`,
                'green': `rgba(0, 255, 0, ${opacity})`,
                'yellow': `rgba(255, 255, 0, ${opacity})`,
                'purple': `rgba(128, 0, 128, ${opacity})`,
                'orange': `rgba(255, 165, 0, ${opacity})`,
                'pink': `rgba(255, 192, 203, ${opacity})`,
                'cyan': `rgba(0, 255, 255, ${opacity})`,
                'white': `rgba(255, 255, 255, ${opacity})`
            };

            const color = colorMap[data.color] || colorMap['black'];

            const gradient = `radial-gradient(ellipse at center, 
                transparent 0%, 
                transparent 40%, 
                ${color.replace(/[\d.]+\)$/, (opacity * 0.1).toFixed(2) + ')')} 55%, 
                ${color.replace(/[\d.]+\)$/, (opacity * 0.2).toFixed(2) + ')')} 65%, 
                ${color.replace(/[\d.]+\)$/, (opacity * 0.4).toFixed(2) + ')')} 75%, 
                ${color.replace(/[\d.]+\)$/, (opacity * 0.6).toFixed(2) + ')')} 85%, 
                ${color.replace(/[\d.]+\)$/, (opacity * 0.8).toFixed(2) + ')')} 95%, 
                ${color} 100%)`;

            damageVignette.style.background = gradient;

            damageVignette.style.animation = 'vignetteAppear 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94), vignettePulse 0.1s ease-out';
        }

        damageVignette.classList.add('show');
        setTimeout(() => {
            if (damageVignette.classList.contains('show')) {
                damageVignette.style.animation += ', vignetteShake 0.1s ease-in-out';
            }
        }, 50);
    }
}

function hideDamageVignette() {
    if (damageVignette) {
        damageVignette.style.animation = 'vignetteDisappear 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)';

        setTimeout(() => {
            damageVignette.classList.remove('show');
            damageVignette.style.animation = '';
        }, 300);
    }
}

let currentHelpMessages = null;

function showHelpMessages(messages) {
    if (!messages || messages.length === 0) {
        hideHelpMessagesInteraction();
        return;
    }
    currentHelpMessages = messages;
    const container = document.getElementById('help-messages');
    if (!container) return;

    container.style.display = 'flex';

    container.innerHTML = '';

    messages.forEach(function (msg) {
        const messageDiv = document.createElement('div');
        messageDiv.className = 'help-message';

        if (msg.icon) {
            const iconDiv = document.createElement('div');
            iconDiv.className = 'help-icon';
            iconDiv.innerHTML = msg.icon;
            messageDiv.appendChild(iconDiv);
        }

        const textDiv = document.createElement('div');
        textDiv.className = 'help-text';

        let textContent = '';
        if (msg.key) {
            textContent = '<span class="help-key">' + msg.key + '</span> ' + (msg.text || '');
        } else {
            textContent = msg.text || '';
        }
        textDiv.innerHTML = textContent;
        messageDiv.appendChild(textDiv);

        container.appendChild(messageDiv);
    });
}

function hideHelpMessagesInteraction() {
    const container = document.getElementById('help-messages');
    if (!container) return;

    const messages = container.querySelectorAll('.help-message');
    if (messages.length === 0) return;

    messages.forEach(function (msg) {
        msg.style.opacity = '0';
        msg.style.transform = 'translateY(20px)';
        setTimeout(function () {
            if (msg.parentNode) {
                msg.parentNode.removeChild(msg);
            }
        }, 300);
    });
    currentHelpMessages = null;
}
