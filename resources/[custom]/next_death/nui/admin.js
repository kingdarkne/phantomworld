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

let adminMenuOpen = false;
let latestAdminConfig = null;
let respawnLocationsDraft = [];

const DEFAULT_RESPAWN_POINT = Object.freeze({
    label: 'Hospital',
    x: 298.44,
    y: -584.89,
    z: 43.26,
    heading: 70.0
});

if (typeof translations === 'undefined') {
    var translations = {};
}
if (typeof currentLocale === 'undefined') {
    var currentLocale = 'en';
}

if (typeof _ === 'undefined') {
    function _(key, ...args) {
        const text = translations[key] || key;
        if (args.length > 0) {
            return text.replace(/%s/g, () => args.shift());
        }
        return text;
    }
}

if (typeof setTranslations === 'undefined') {
    function setTranslations(newTranslations, locale) {
        translations = newTranslations || {};
        currentLocale = locale || 'en';
    }
}

function translateOrFallback(key, fallback, ...args) {
    const translated = _(key, ...args);
    if (!translated || translated === key) {
        if (args.length > 0) {
            let index = 0;
            return String(fallback || key).replace(/%s/g, () => String(args[index++] ?? ''));
        }
        return fallback || key;
    }
    return translated;
}

function defaultRespawnPointLabel(index) {
    return translateOrFallback('respawn_point', 'Point %s', index + 1);
}

function defaultHospitalLabel() {
    return translateOrFallback('hospital_label', 'Hospital');
}

function updateAdminUITexts() {
    const elementsToTranslate = document.querySelectorAll('#app [data-translate]');
    elementsToTranslate.forEach(element => {
        const key = element.getAttribute('data-translate');
        if (key) {
            element.textContent = _(key);
        }
    });

    updateDiscordFooter();
    updateTimerWarningState();
}

function debounce(func, wait) {
    let timeout;
    return function (...args) {
        const context = this;
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(context, args), wait);
    };
}

function isMultiRespawnEnabled() {
    const checkbox = document.getElementById('nearest-respawn-point-enabled');
    return !!(checkbox && checkbox.checked);
}

function updateMultiRespawnUiVisibility() {
    const enabled = isMultiRespawnEnabled();
    const controls = document.getElementById('multi-respawn-controls');
    const configBlock = document.getElementById('multi-respawn-config');
    const addBtn = document.getElementById('add-respawn-point-btn');

    if (controls) {
        controls.style.display = enabled ? 'flex' : 'none';
    }
    if (configBlock) {
        configBlock.style.display = 'flex';
    }
    if (addBtn) {
        addBtn.disabled = !enabled;
    }
}

function toNumber(value, fallback) {
    const parsed = parseFloat(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeHeading(value) {
    const heading = toNumber(value, 0);
    let normalized = heading % 360;
    if (normalized < 0) normalized += 360;
    return Number(normalized.toFixed(1));
}

function sanitizeRespawnPoint(point, fallbackIndex = 0) {
    const defaultLabel = defaultRespawnPointLabel(fallbackIndex);
    if (!point || typeof point !== 'object') {
        return {
            label: defaultLabel,
            x: DEFAULT_RESPAWN_POINT.x,
            y: DEFAULT_RESPAWN_POINT.y,
            z: DEFAULT_RESPAWN_POINT.z,
            heading: DEFAULT_RESPAWN_POINT.heading
        };
    }

    const labelRaw = typeof point.label === 'string' ? point.label.trim() : '';
    return {
        label: labelRaw || defaultLabel,
        x: toNumber(point.x, DEFAULT_RESPAWN_POINT.x),
        y: toNumber(point.y, DEFAULT_RESPAWN_POINT.y),
        z: toNumber(point.z, DEFAULT_RESPAWN_POINT.z),
        heading: normalizeHeading(point.heading)
    };
}

function ensureRespawnLocations(points) {
    const source = Array.isArray(points) ? points : [];
    const normalized = source.map((point, index) => sanitizeRespawnPoint(point, index));
    if (normalized.length === 0) {
        normalized.push(sanitizeRespawnPoint({
            label: defaultHospitalLabel(),
            x: DEFAULT_RESPAWN_POINT.x,
            y: DEFAULT_RESPAWN_POINT.y,
            z: DEFAULT_RESPAWN_POINT.z,
            heading: DEFAULT_RESPAWN_POINT.heading
        }, 0));
    }
    return normalized;
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function renderRespawnPointsList() {
    const list = document.getElementById('respawn-point-list');
    if (!list) return;

    respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft);
    const multiEnabled = isMultiRespawnEnabled();
    const pointsToRender = multiEnabled
        ? respawnLocationsDraft.map((point, index) => ({ point, index }))
        : [{ point: respawnLocationsDraft[0], index: 0 }];

    list.innerHTML = pointsToRender.map(({ point, index }, visibleIndex) => {
        const rawLabel = typeof point.label === 'string' ? point.label : '';
        const label = escapeHtml(rawLabel);
        const x = Number(point.x).toFixed(2);
        const y = Number(point.y).toFixed(2);
        const z = Number(point.z).toFixed(2);
        const heading = Number(point.heading).toFixed(1);
        const removeDisabled = (!multiEnabled || respawnLocationsDraft.length <= 1) ? 'disabled' : '';
        const pointTitle = escapeHtml(translateOrFallback('respawn_point', 'Point %s', visibleIndex + 1));
        const useCurrentPositionText = escapeHtml(translateOrFallback('get_current_position', 'Get current position'));
        const removePointText = escapeHtml(translateOrFallback('remove_respawn_point', 'Remove'));
        const pointLabelText = escapeHtml(translateOrFallback('respawn_point_label', 'Label'));
        const pointHeadingText = escapeHtml(translateOrFallback('respawn_point_heading', 'Heading'));
        const removeButtonHtml = multiEnabled ? `
                        <button class="action-btn small" type="button" data-action="remove-point" data-index="${index}" ${removeDisabled}>
                            <i class="fas fa-trash"></i>
                            <span>${removePointText}</span>
                        </button>
        ` : '';

        return `
            <div class="respawn-point-card" data-point-index="${index}">
                <div class="respawn-point-head">
                    <span class="respawn-point-title">${pointTitle}</span>
                    <div class="respawn-point-actions">
                        <button class="action-btn small" type="button" data-action="use-current-pos" data-index="${index}">
                            <i class="fas fa-location-crosshairs"></i>
                            <span>${useCurrentPositionText}</span>
                        </button>
                        ${removeButtonHtml}
                    </div>
                </div>
                <div class="respawn-point-fields">
                    <div class="respawn-point-row single">
                        <div class="input-group">
                            <label>${pointLabelText}</label>
                            <input type="text" class="coord-input respawn-point-input" data-index="${index}" data-field="label" maxlength="64" value="${label}">
                        </div>
                    </div>
                    <div class="respawn-point-row">
                        <div class="input-group">
                            <label>X</label>
                            <input type="number" class="coord-input respawn-point-input" data-index="${index}" data-field="x" step="0.01" value="${x}">
                        </div>
                        <div class="input-group">
                            <label>Y</label>
                            <input type="number" class="coord-input respawn-point-input" data-index="${index}" data-field="y" step="0.01" value="${y}">
                        </div>
                    </div>
                    <div class="respawn-point-row">
                        <div class="input-group">
                            <label>Z</label>
                            <input type="number" class="coord-input respawn-point-input" data-index="${index}" data-field="z" step="0.01" value="${z}">
                        </div>
                        <div class="input-group">
                            <label>${pointHeadingText}</label>
                            <input type="number" class="coord-input respawn-point-input" data-index="${index}" data-field="heading" step="0.1" value="${heading}">
                        </div>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

function syncRespawnLocationsFromList() {
    const list = document.getElementById('respawn-point-list');
    if (!list) {
        respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft);
        return;
    }

    respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft).map((point, index) => {
        const pointLabel = list.querySelector(`.respawn-point-input[data-index="${index}"][data-field="label"]`);
        const pointX = list.querySelector(`.respawn-point-input[data-index="${index}"][data-field="x"]`);
        const pointY = list.querySelector(`.respawn-point-input[data-index="${index}"][data-field="y"]`);
        const pointZ = list.querySelector(`.respawn-point-input[data-index="${index}"][data-field="z"]`);
        const pointHeading = list.querySelector(`.respawn-point-input[data-index="${index}"][data-field="heading"]`);

        const nextLabel = pointLabel ? pointLabel.value : point.label;
        const nextX = pointX ? toNumber(pointX.value, point.x) : point.x;
        const nextY = pointY ? toNumber(pointY.value, point.y) : point.y;
        const nextZ = pointZ ? toNumber(pointZ.value, point.z) : point.z;
        const headingBase = pointHeading ? toNumber(pointHeading.value, point.heading) : point.heading;
        const nextHeading = normalizeHeading(headingBase);

        return sanitizeRespawnPoint({
            label: nextLabel,
            x: nextX,
            y: nextY,
            z: nextZ,
            heading: nextHeading
        }, index);
    });
}

function updateRespawnPointField(index, field, value) {
    if (!Number.isInteger(index) || index < 0 || index >= respawnLocationsDraft.length) {
        return;
    }

    const point = sanitizeRespawnPoint(respawnLocationsDraft[index], index);
    if (field === 'label') {
        point.label = typeof value === 'string' ? value : '';
        respawnLocationsDraft[index] = {
            label: point.label,
            x: Number(point.x),
            y: Number(point.y),
            z: Number(point.z),
            heading: Number(point.heading)
        };
        return;
    } else if (field === 'heading') {
        const headingValue = toNumber(value, point.heading);
        point.heading = normalizeHeading(headingValue);
    } else if (field === 'x' || field === 'y' || field === 'z') {
        point[field] = toNumber(value, point[field]);
    } else {
        return;
    }

    respawnLocationsDraft[index] = sanitizeRespawnPoint(point, index);
}

async function requestCurrentPosition() {
    try {
        const response = await fetch('https://next_death/getCurrentPosition', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        const data = await response.json();
        if (data && data.success && data.coords) {
            return data.coords;
        }
    } catch (error) {
        console.error(error);
    }

    return null;
}

async function setRespawnPointToCurrentPosition(index) {
    if (!Number.isInteger(index) || index < 0 || index >= respawnLocationsDraft.length) {
        return;
    }

    const coords = await requestCurrentPosition();
    if (!coords) return;

    const point = sanitizeRespawnPoint(respawnLocationsDraft[index], index);
    point.x = toNumber(coords.x, point.x);
    point.y = toNumber(coords.y, point.y);
    point.z = toNumber(coords.z, point.z);
    point.heading = normalizeHeading(coords.heading);
    if (!point.label || point.label.trim() === '') {
        point.label = defaultRespawnPointLabel(index);
    }

    respawnLocationsDraft[index] = sanitizeRespawnPoint(point, index);
    renderRespawnPointsList();
    triggerAutoSave();
}

async function addRespawnPoint() {
    if (!isMultiRespawnEnabled()) {
        return;
    }

    syncRespawnLocationsFromList();
    const nextIndex = respawnLocationsDraft.length;
    const newPoint = sanitizeRespawnPoint({
        label: defaultRespawnPointLabel(nextIndex),
        x: DEFAULT_RESPAWN_POINT.x,
        y: DEFAULT_RESPAWN_POINT.y,
        z: DEFAULT_RESPAWN_POINT.z,
        heading: DEFAULT_RESPAWN_POINT.heading
    }, nextIndex);

    const coords = await requestCurrentPosition();
    if (coords) {
        newPoint.x = toNumber(coords.x, newPoint.x);
        newPoint.y = toNumber(coords.y, newPoint.y);
        newPoint.z = toNumber(coords.z, newPoint.z);
        newPoint.heading = normalizeHeading(coords.heading);
    }

    respawnLocationsDraft.push(sanitizeRespawnPoint(newPoint, nextIndex));
    renderRespawnPointsList();
    triggerAutoSave();
}

function removeRespawnPoint(index) {
    if (!isMultiRespawnEnabled()) {
        return;
    }

    syncRespawnLocationsFromList();
    if (!Number.isInteger(index) || index < 0 || index >= respawnLocationsDraft.length) {
        return;
    }
    if (respawnLocationsDraft.length <= 1) {
        return;
    }

    respawnLocationsDraft.splice(index, 1);
    respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft);
    renderRespawnPointsList();
    triggerAutoSave();
}

function getRespawnLocationsFromConfig(config) {
    if (config && Array.isArray(config.respawnLocations) && config.respawnLocations.length > 0) {
        return ensureRespawnLocations(config.respawnLocations);
    }

    if (config && config.hospital && typeof config.hospital === 'object') {
        return ensureRespawnLocations([{
            label: defaultHospitalLabel(),
            x: config.hospital.x,
            y: config.hospital.y,
            z: config.hospital.z,
            heading: config.hospital.heading
        }]);
    }

    return ensureRespawnLocations([]);
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'openAdminMenu') {
        openAdminMenu(data.locale, data.translations, data.version);
    } else if (data.action === 'closeAdminMenu') {
        closeAdminMenu();
    } else if (data.action === 'adminUpdateConfig' && data.config) {
        latestAdminConfig = data.config;
        setAdminVersion(data.version);

        if (data.translations) {
            if (typeof setTranslations === 'function') {
                setTranslations(data.translations, data.locale);
            }
            updateAdminUITexts();
        }

        const languageSelect = document.getElementById('language-select');
        if (languageSelect && data.locale) {
            languageSelect.value = data.locale;
        }

        updateUI(data.config);

    } else if (data.action === 'languageChanged') {
        if (data.translations && data.locale) {
            if (typeof setTranslations === 'function') {
                setTranslations(data.translations, data.locale);
            }
            updateAdminUITexts();
        }
        const languageSelect = document.getElementById('language-select');
        if (languageSelect && data.locale) {
            languageSelect.value = data.locale;
        }
        if (adminMenuOpen) {
            loadConfig();
        }
    } else if (data.action === 'updateDetectedInfo') {
        const inventoryStatusValue = document.getElementById('inventory-status-value');
        if (inventoryStatusValue) {
            if (data.detectedInventory) {
                inventoryStatusValue.textContent = data.detectedInventory;
                inventoryStatusValue.className = 'info-value detected';
            } else {
                inventoryStatusValue.textContent = _('no_inventory_detected') || 'None detected';
                inventoryStatusValue.className = 'info-value not-detected';
            }
        }
    }
});

function setAdminVersion(version) {
    const versionEl = document.getElementById('ui-version');
    if (!versionEl || !version) return;
    versionEl.textContent = 'v' + version;
}

function openAdminMenu(locale, newTranslations, version) {
    if (adminMenuOpen) return;

    adminMenuOpen = true;

    if (newTranslations) {
        if (typeof setTranslations === 'function') {
            setTranslations(newTranslations, locale);
        }
    }

    if (locale) {
        currentLocale = locale;
    }

    const app = document.getElementById('app');
    if (app) {
        initializeAdminMenu();

        if (latestAdminConfig) {
            updateUI(latestAdminConfig);
        }

        app.classList.add('visible');
        loadConfig();
        setAdminVersion(version);
    }
}

function initializeAdminMenu() {
    initializeTabs();
    initializeSidebar();
    initializeInputs();

    const discordText = document.getElementById('discord-admin-text');
    if (discordText) discordText.style.display = 'block';

    updateAdminUITexts();
    updateMultiRespawnUiVisibility();
}

let tabsInitialized = false;
function initializeTabs() {
    if (tabsInitialized) return;
    tabsInitialized = true;

    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabPanels = document.querySelectorAll('.tab-pane');

    tabButtons.forEach(btn => {
        btn.addEventListener('click', function () {
            const targetTab = this.getAttribute('data-tab');

            tabButtons.forEach(b => b.classList.remove('active'));
            tabPanels.forEach(p => p.classList.remove('active'));

            this.classList.add('active');

            const targetPanel = document.getElementById('tab-' + targetTab);
            if (targetPanel) {
                targetPanel.classList.add('active');
            }
        });
    });
}

let sidebarInitialized = false;
function initializeSidebar() {
    if (sidebarInitialized) return;
    sidebarInitialized = true;

    const sidebarItems = document.querySelectorAll('.sidebar-item');

    sidebarItems.forEach(item => {
        item.addEventListener('click', function () {
            const sectionName = this.getAttribute('data-section');

            sidebarItems.forEach(i => i.classList.remove('active'));
            this.classList.add('active');

            const activePanel = document.querySelector('.tab-pane.active');
            if (activePanel) {
                activePanel.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
                const targetSection = activePanel.querySelector(`#section-${sectionName}`);
                if (targetSection) targetSection.classList.add('active');
            }
        });
    });
}

const triggerAutoSave = debounce(function () {
    saveConfig();
}, 500);

let inputsInitialized = false;
function initializeInputs() {
    if (inputsInitialized) return;
    inputsInitialized = true;

    const inputs = document.querySelectorAll('#app input, #app select');

    inputs.forEach(input => {
        if (input.classList.contains('respawn-point-input')) return;

        input.addEventListener('change', () => {
            if (input.id === 'nearest-respawn-point-enabled') {
                updateMultiRespawnUiVisibility();
                respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft);
                renderRespawnPointsList();
            }
            triggerAutoSave();
        });

        input.addEventListener('input', () => {
            if (input.id === 'nearest-respawn-point-enabled') {
                updateMultiRespawnUiVisibility();
            }
            if (input.type === 'range') {
                updateVisualsForInput(input);
            }
            if (input.id === 'bleedout-slider' || input.id === 'early-slider') {
                updateTimerWarningState();
            }
            triggerAutoSave();
        });
    });

    document.querySelectorAll('.color-option').forEach(option => {
        option.addEventListener('click', function () {
            document.querySelectorAll('.color-option').forEach(opt => opt.classList.remove('selected'));
            this.classList.add('selected');
            triggerAutoSave();
        });
    });

    const saveWhitelistBtn = document.getElementById('save-whitelist-btn');
    if (saveWhitelistBtn) {
        saveWhitelistBtn.addEventListener('click', function () {
            saveConfig();
            const originalText = this.innerHTML;
            this.innerHTML = '<i class="fas fa-check"></i> <span data-translate="saved">SAVED</span>';
            setTimeout(() => {
                this.innerHTML = originalText;
            }, 2000);
        });
    }

    const loseInventoryCheckbox = document.getElementById('lose-inventory-on-respawn');
    if (loseInventoryCheckbox) {
        loseInventoryCheckbox.addEventListener('change', function () {
            const container = document.getElementById('container-inventory-whitelist');
            if (container) container.style.display = 'flex';
        });
    }

    const respawnPointList = document.getElementById('respawn-point-list');
    if (respawnPointList) {
        respawnPointList.addEventListener('input', function (event) {
            const target = event.target;
            if (!target || !target.classList || !target.classList.contains('respawn-point-input')) {
                return;
            }

            const index = parseInt(target.dataset.index, 10);
            const field = target.dataset.field;
            updateRespawnPointField(index, field, target.value);
            if (field !== 'label') {
                triggerAutoSave();
            }
        });

        respawnPointList.addEventListener('change', function (event) {
            const target = event.target;
            if (!target || !target.classList || !target.classList.contains('respawn-point-input')) {
                return;
            }

            const index = parseInt(target.dataset.index, 10);
            const field = target.dataset.field;
            updateRespawnPointField(index, field, target.value);
            if (field === 'label') {
                triggerAutoSave();
            }
        });

        respawnPointList.addEventListener('click', function (event) {
            const target = event.target;
            const actionButton = target && target.closest ? target.closest('button[data-action]') : null;
            if (!actionButton) return;

            const index = parseInt(actionButton.dataset.index, 10);
            const action = actionButton.dataset.action;

            if (action === 'remove-point') {
                removeRespawnPoint(index);
            } else if (action === 'use-current-pos') {
                setRespawnPointToCurrentPosition(index);
            }
        });
    }
}

function updateVisualsForInput(input) {
    if (input.id === 'bleedout-slider') {
        const valSpan = document.getElementById('bleedout-value');
        if (valSpan) valSpan.textContent = `${input.value} min`;
    } else if (input.id === 'early-slider') {
        const minutes = parseFloat(input.value);
        const displayMinutes = minutes < 1 ? Math.round(minutes * 60) : minutes;
        const valueText = minutes < 1 ? `${displayMinutes} sec` : `${minutes.toFixed(1)} min`;
        const valSpan = document.getElementById('early-value');
        if (valSpan) valSpan.textContent = valueText;
    } else if (input.id === 'damage-vignette-opacity') {
        const valSpan = document.getElementById('damage-vignette-opacity-value');
        if (valSpan) valSpan.textContent = `${input.value}%`;
    }
}

function buildTimerWarningText() {
    return _('timer_respawn_order_warning');
}

function setTimerWarning(visible, message) {
    const warningEl = document.getElementById('timer-warning');
    if (!warningEl) return;

    if (visible) {
        warningEl.textContent = message || buildTimerWarningText();
        warningEl.classList.add('show');
    } else {
        warningEl.textContent = '';
        warningEl.classList.remove('show');
    }
}

function updateTimerWarningState() {
    const bleedoutSlider = document.getElementById('bleedout-slider');
    const earlySlider = document.getElementById('early-slider');
    if (!bleedoutSlider || !earlySlider) return false;

    const bleedoutMinutes = parseFloat(bleedoutSlider.value);
    const earlyMinutes = parseFloat(earlySlider.value);

    if (!Number.isFinite(bleedoutMinutes) || !Number.isFinite(earlyMinutes)) {
        setTimerWarning(false);
        return false;
    }

    const invalid = earlyMinutes >= bleedoutMinutes;
    setTimerWarning(invalid, invalid ? buildTimerWarningText() : '');
    return invalid;
}

function loadConfig() {
    fetch('https://next_death/loadConfig', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
        .then(r => r.json())
        .then(data => {
            if (data.success && data.config) {
                latestAdminConfig = data.config;
                updateUI(data.config);
            }
        })
        .catch(console.error);
}

function updateUI(config) {
    if (!config) return;

    const setVal = (id, val, isCheck = false) => {
        const el = document.getElementById(id);
        if (!el) return;
        if (isCheck) el.checked = val;
        else el.value = val;

        if (el.type === 'range') updateVisualsForInput(el);
    };

    const bleedoutMinutes = config.bleedoutTimeMs / (60 * 1000);
    setVal('bleedout-slider', bleedoutMinutes);

    const earlyMinutes = config.earlyRespawnTimeMs / (60 * 1000);
    setVal('early-slider', earlyMinutes);
    updateTimerWarningState();

    setVal('early-respawn-enabled', config.allowEarlyRespawn, true);
    setVal('forced-respawn-enabled', config.forcedRespawnEnabled ?? true, true);
    setVal('remove-weapons', config.removeWeaponsOnRespawn, true);
    setVal('lose-inventory-on-respawn', config.loseInventoryOnRespawn || false, true);
    const whitelistElem = document.getElementById('inventory-whitelist');
    if (whitelistElem) {
        whitelistElem.value = (config.inventoryWhitelist && Array.isArray(config.inventoryWhitelist)) ? config.inventoryWhitelist.join(', ') : '';
    }
    const whitelistContainer = document.getElementById('container-inventory-whitelist');
    if (whitelistContainer) {
        whitelistContainer.style.display = 'flex';
    }
    setVal('drop-weapon-on-death', config.dropWeaponOnDeath || false, true);
    setVal('respawn-at-location', config.respawnAtLocation ?? true, true);
    setVal('revive_at_location', config.reviveAtLocation ?? false, true);
    setVal('nearest-respawn-point-enabled', config.nearestRespawnPointEnabled ?? false, true);
    setVal('damage-vignette-enabled', config.damageVignetteEnabled || false, true);

    respawnLocationsDraft = getRespawnLocationsFromConfig(config);
    renderRespawnPointsList();
    updateMultiRespawnUiVisibility();

    setVal('damage-vignette-opacity', config.damageVignetteOpacity || 90);

    const selectedColor = config.damageVignetteColor || 'black';
    document.querySelectorAll('.color-option').forEach(opt => {
        opt.classList.remove('selected');
        if (opt.dataset.color === selectedColor) opt.classList.add('selected');
    });

    const inventoryStatusValue = document.getElementById('inventory-status-value');
    if (inventoryStatusValue) {
        if (config.detectedInventory) {
            inventoryStatusValue.textContent = config.detectedInventory;
            inventoryStatusValue.className = 'info-value detected';
        } else {
            inventoryStatusValue.textContent = _('no_inventory_detected') || 'None detected';
            inventoryStatusValue.className = 'info-value not-detected';
        }
    }

    updateAdminUITexts();
}

function saveConfig() {
    const bleedoutSlider = document.getElementById('bleedout-slider');
    const earlySlider = document.getElementById('early-slider');

    if (!bleedoutSlider || !earlySlider) return;

    const bleedoutMinutes = parseFloat(bleedoutSlider.value);
    const earlyMinutes = parseFloat(earlySlider.value);

    if (!Number.isFinite(bleedoutMinutes) || !Number.isFinite(earlyMinutes)) return;

    const bleedoutTimeMs = Math.round(bleedoutMinutes * 60 * 1000);
    const earlyRespawnTimeMs = Math.round(earlyMinutes * 60 * 1000);

    if (earlyRespawnTimeMs >= bleedoutTimeMs) {
        updateTimerWarningState();
        return;
    }
    setTimerWarning(false);

    syncRespawnLocationsFromList();
    respawnLocationsDraft = ensureRespawnLocations(respawnLocationsDraft);
    const serializedRespawnLocations = respawnLocationsDraft.map((point, index) => {
        const normalized = sanitizeRespawnPoint(point, index);
        return {
            label: normalized.label,
            x: Number(normalized.x),
            y: Number(normalized.y),
            z: Number(normalized.z),
            heading: Number(normalized.heading)
        };
    });
    const primaryRespawn = serializedRespawnLocations[0] || sanitizeRespawnPoint(DEFAULT_RESPAWN_POINT, 0);

    const config = {
        bleedoutTimeMs: bleedoutTimeMs,
        earlyRespawnTimeMs: earlyRespawnTimeMs,
        allowEarlyRespawn: document.getElementById('early-respawn-enabled').checked,
        forcedRespawnEnabled: document.getElementById('forced-respawn-enabled').checked,
        removeWeaponsOnRespawn: document.getElementById('remove-weapons').checked,
        loseInventoryOnRespawn: document.getElementById('lose-inventory-on-respawn').checked,
        inventoryWhitelist: document.getElementById('inventory-whitelist').value.split(',').map(item => item.trim()).filter(item => item !== ''),
        dropWeaponOnDeath: document.getElementById('drop-weapon-on-death').checked,
        respawnAtLocation: document.getElementById('respawn-at-location').checked,
        reviveAtLocation: document.getElementById('revive_at_location').checked,
        nearestRespawnPointEnabled: document.getElementById('nearest-respawn-point-enabled').checked,
        respawnLocations: serializedRespawnLocations,
        hospital: {
            x: Number(primaryRespawn.x),
            y: Number(primaryRespawn.y),
            z: Number(primaryRespawn.z),
            heading: Number(primaryRespawn.heading)
        },
        damageVignetteEnabled: document.getElementById('damage-vignette-enabled').checked,
        damageVignetteColor: document.querySelector('.color-option.selected')?.dataset.color || 'black',
        damageVignetteOpacity: parseInt(document.getElementById('damage-vignette-opacity').value) || 90,
        locale: document.getElementById('language-select')?.value || 'en'
    };

    fetch('https://next_death/saveConfig', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(config)
    }).then(r => r.json()).catch(e => console.error(e));
}

function closeAdminMenu() {
    if (!adminMenuOpen) return;
    adminMenuOpen = false;

    const app = document.getElementById('app');
    if (app) {
        app.classList.remove('visible');
    }

    fetch('https://next_death/closeAdminMenu', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function updateDiscordFooter() {
    const discordText = document.getElementById('discord-admin-text');
    if (!discordText) return;

    const foundBugText = typeof _ !== 'undefined' ? _('found_bug') || 'Found a bug? Let us know:' : 'Found a bug? Let us know:';
    discordText.querySelector('p').innerHTML = foundBugText + ' <a href="https://discord.gg/DPQarEF65Y" target="_blank" rel="noopener noreferrer" class="discord-link">https://discord.gg/DPQarEF65Y</a>';
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

window.closeAdminMenu = closeAdminMenu;
window.addRespawnPointFromUI = addRespawnPoint;
window.removeRespawnPointFromUI = function (index) {
    const parsed = parseInt(index, 10);
    if (Number.isInteger(parsed)) {
        removeRespawnPoint(parsed);
        return;
    }
    removeRespawnPoint(respawnLocationsDraft.length - 1);
};
window.getCurrentPosition = function (index) {
    const parsed = parseInt(index, 10);
    const targetIndex = Number.isInteger(parsed) ? parsed : 0;
    setRespawnPointToCurrentPosition(targetIndex);
};

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && adminMenuOpen) {
        closeAdminMenu();
    }
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
