/*
  ------------------------------------------------------------------------------------------------
    Next Housing - Complete housing system
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
    
    Documentation: https://www.nextcorestudio.com/docs/next-housing/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-housing/
    Tebex: https://junnho.tebex.io/package/7057755

--------------------------------------------------------------------------------------------------
*/
if (typeof window.translations === 'undefined') {
    window.translations = {};
}
if (typeof window.currentLocale === 'undefined') {
    window.currentLocale = 'en';
}
var translations = window.translations;
var currentLocale = window.currentLocale;

function normalizeScriptVersion(rawVersion) {
    const cleaned = String(rawVersion === undefined || rawVersion === null ? "" : rawVersion)
        .replace(/[\u0000-\u001F\u007F]/g, "")
        .trim();
    if (!cleaned) {
        return "";
    }

    return cleaned.toLowerCase().startsWith("v") ? cleaned : ("v" + cleaned);
}

function applyScriptVersionToHeaders(rawVersion) {
    const normalizedVersion = normalizeScriptVersion(rawVersion);
    if (!normalizedVersion) {
        return false;
    }

    document.querySelectorAll('.badge-version').forEach(function (badge) {
        badge.textContent = normalizedVersion;
    });
    window.nhScriptVersion = normalizedVersion;
    return true;
}

function getScriptVersionFromMetadata() {
    if (typeof GetResourceMetadata !== "function") {
        return "";
    }

    const resourceName = (typeof GetParentResourceName === "function" && GetParentResourceName())
        ? GetParentResourceName()
        : "next_housing";

    return GetResourceMetadata(resourceName, "version", 0) || "";
}

function syncScriptVersionBadges(rawVersion) {
    if (applyScriptVersionToHeaders(rawVersion)) {
        return;
    }

    try {
        applyScriptVersionToHeaders(getScriptVersionFromMetadata());
    } catch (_) {
    }
}

syncScriptVersionBadges();

window.updateManageLockIcon = function (isLocked) {
    const lockBtn = document.getElementById('toggle-lock-btn');
    if (!lockBtn) return;

    const icon = lockBtn.querySelector('svg');
    if (!icon) return;

    const locked = isLocked === true;
    lockBtn.setAttribute('title', locked ? (translations.closed) : (translations.open));
    lockBtn.setAttribute('data-locked', locked ? '1' : '0');

    icon.setAttribute('viewBox', '0 0 24 24');
    icon.setAttribute('fill', 'none');
    icon.setAttribute('stroke', 'currentColor');
    icon.setAttribute('stroke-width', '2');
    icon.setAttribute('stroke-linecap', 'round');
    icon.setAttribute('stroke-linejoin', 'round');

    if (locked) {
        icon.innerHTML = '<rect x="5" y="11" width="14" height="10" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path>';
    } else {
        icon.innerHTML = '<rect x="5" y="11" width="14" height="10" rx="2" ry="2"></rect><path d="M17 11V7a5 5 0 0 0-9.9-1"></path>';
    }
};

const NH_REFRESH_SPIN_CLASS = "nh-refresh-icon-spinning";
const NH_REFRESH_SPIN_DEFAULT_MS = 650;

function nhFindRefreshIcon(button) {
    if (!button || typeof button.querySelector !== "function") {
        return null;
    }

    return button.querySelector('i.ph-arrows-clockwise, i.ph-arrow-clockwise, i[class*="ph-arrows-clockwise"], i[class*="ph-arrow-clockwise"], i');
}

window.nhSpinRefreshButton = function (buttonOrSelector, durationMs) {
    let button = buttonOrSelector;
    if (!button) {
        return;
    }

    if (typeof button === "string") {
        button = document.querySelector(button);
    } else if (window.jQuery && button.jquery) {
        button = button.get(0);
    }

    if (!button || typeof button.querySelector !== "function") {
        return;
    }

    const icon = nhFindRefreshIcon(button);
    if (!icon) {
        return;
    }

    const parsedDuration = parseInt(durationMs, 10);
    const spinDuration = Number.isFinite(parsedDuration) && parsedDuration > 0
        ? Math.max(250, parsedDuration)
        : NH_REFRESH_SPIN_DEFAULT_MS;

    if (icon.__nhRefreshSpinTimer) {
        clearTimeout(icon.__nhRefreshSpinTimer);
        icon.__nhRefreshSpinTimer = null;
    }

    icon.classList.remove(NH_REFRESH_SPIN_CLASS);
    icon.style.setProperty("--nh-refresh-spin-duration", spinDuration + "ms");

    void icon.offsetWidth;

    icon.classList.add(NH_REFRESH_SPIN_CLASS);
    icon.__nhRefreshSpinTimer = window.setTimeout(function () {
        icon.classList.remove(NH_REFRESH_SPIN_CLASS);
        icon.style.removeProperty("--nh-refresh-spin-duration");
        icon.__nhRefreshSpinTimer = null;
    }, spinDuration + 50);
};

document.addEventListener("click", function (event) {
    if (!event || !event.target || typeof event.target.closest !== "function") {
        return;
    }

    const refreshButton = event.target.closest("#refresh-current-tab-btn, #pap-interface .pap-refresh-btn, #wardrobe-refresh-btn");
    if (!refreshButton || refreshButton.disabled || refreshButton.classList.contains("is-disabled")) {
        return;
    }

    window.nhSpinRefreshButton(refreshButton);
});

const NH_DEFAULT_BRAND_TITLE = "Next Housing";
const NH_DEFAULT_BRAND_LOGO_SOURCE = "https://www.junnho.com/assets/images/logoBlanc.png";
const NH_BRAND_LOGO_MAX_LENGTH = 450000;
const NH_EXTENDED_STATE_TTL_MS = 2500;
const NH_EXT_RESOURCE_NAME = (typeof GetConvar === 'function')
    ? (GetConvar('next_housing_extended_resource', 'next_housing_extended') || 'next_housing_extended')
    : 'next_housing_extended';
const NH_EXT_MAP_MODULE_PATH = "ui/job_map.js";
const NH_EXT_MAP_RETRY_COOLDOWN_MS = 4000;
const NH_BRAND_CONTEXTS = ["nh", "agency", "pap", "garage", "wardrobe"];
const NH_BRAND_SELECTORS = {
    nh: ["#headerTitle", "#dynamic-modal-brand-title"],
    agency: ["#job-interface .job-title"],
    pap: ["#pap-title"],
    garage: ["#garage-container .title"],
    wardrobe: ["#wardrobe-container .title"]
};
const NH_BRAND_HEADER_BLOCK_SELECTORS = [
    "#container .header > div:first-child",
    "#dynamic-global-modal .pap-modal-header > div:first-child",
    "#garage-container .header > div:first-child",
    "#job-interface .job-header > div:first-child",
    "#pap-interface .pap-header > div:first-child",
    "#wardrobe-container .header > div:first-child"
];

if (typeof window.nhExtendedState === "undefined") {
    window.nhExtendedState = {
        available: false,
        title: NH_DEFAULT_BRAND_TITLE,
        perMenuEnabled: false,
        squareDotEnabled: false,
        logoEnabled: false,
        logoSource: NH_DEFAULT_BRAND_LOGO_SOURCE,
        menuTitles: {
            nh: NH_DEFAULT_BRAND_TITLE,
            agency: NH_DEFAULT_BRAND_TITLE,
            pap: NH_DEFAULT_BRAND_TITLE,
            garage: NH_DEFAULT_BRAND_TITLE,
            wardrobe: NH_DEFAULT_BRAND_TITLE
        },
        canCustomize: false,
        canEdit: false,
        loaded: false,
        resource: NH_EXT_RESOURCE_NAME,
        maxLength: 48,
        lastFetchAt: 0,
    };
}

if (typeof window.__nhMapModuleLoaderState === "undefined") {
    window.__nhMapModuleLoaderState = {
        loading: false,
        loaded: false,
        resource: "",
        lastAttemptAt: 0,
        scriptId: "nh-extended-map-module"
    };
}

function normalizeExtendedResourceName(value) {
    const cleaned = String(value || "").trim().replace(/[^A-Za-z0-9_-]/g, "");
    return cleaned || NH_EXT_RESOURCE_NAME;
}

function buildExtendedNuiAssetUrl(resourceName, relativePath) {
    const safeResourceName = normalizeExtendedResourceName(resourceName);
    const safeRelativePath = String(relativePath || "").trim().replace(/^\/+/, "");
    if (!safeRelativePath) {
        return "";
    }
    return `https://cfx-nui-${safeResourceName}/${safeRelativePath}`;
}

function ensureExtendedMapModuleLoaded(options) {
    const opts = options && typeof options === "object" ? options : {};
    const force = opts.force === true;
    const state = window.nhExtendedState || {};
    const resourceName = normalizeExtendedResourceName(opts.resource || state.resource || NH_EXT_RESOURCE_NAME);
    const loaderState = window.__nhMapModuleLoaderState || {};
    const now = Date.now();

    if (typeof window.nhJobMapOpenTab === "function") {
        loaderState.loaded = true;
        loaderState.loading = false;
        loaderState.resource = loaderState.resource || resourceName;
        window.__nhMapModuleLoaderState = loaderState;
        return;
    }

    if (loaderState.loaded === true) {
        return;
    }

    if (loaderState.loading === true) {
        return;
    }

    if (!force && loaderState.lastAttemptAt > 0 && (now - loaderState.lastAttemptAt) < NH_EXT_MAP_RETRY_COOLDOWN_MS) {
        return;
    }

    const scriptUrl = buildExtendedNuiAssetUrl(resourceName, NH_EXT_MAP_MODULE_PATH);
    if (!scriptUrl) {
        return;
    }

    loaderState.loading = true;
    loaderState.lastAttemptAt = now;
    loaderState.resource = resourceName;
    window.__nhMapModuleLoaderState = loaderState;

    const existingScript = document.getElementById(loaderState.scriptId);
    if (existingScript) {
        existingScript.remove();
    }

    const scriptElement = document.createElement("script");
    scriptElement.id = loaderState.scriptId;
    scriptElement.src = scriptUrl;
    scriptElement.async = true;
    scriptElement.defer = true;
    scriptElement.onload = function () {
        const currentLoaderState = window.__nhMapModuleLoaderState || {};
        currentLoaderState.loading = false;
        currentLoaderState.loaded = true;
        currentLoaderState.resource = resourceName;
        window.__nhMapModuleLoaderState = currentLoaderState;

        if (typeof window.nhJobMapUpdateExtendedState === "function") {
            window.nhJobMapUpdateExtendedState(window.nhExtendedState || {});
        }
    };
    scriptElement.onerror = function () {
        const currentLoaderState = window.__nhMapModuleLoaderState || {};
        currentLoaderState.loading = false;
        currentLoaderState.loaded = false;
        currentLoaderState.resource = resourceName;
        window.__nhMapModuleLoaderState = currentLoaderState;
    };

    document.head.appendChild(scriptElement);
}

window.ensureExtendedMapModuleLoaded = ensureExtendedMapModuleLoaded;

function nhEscapeHtml(value) {
    return String(value || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function normalizeBrandTitle(value, fallback) {
    const baseFallback = (typeof fallback === "string" && fallback.trim() !== "")
        ? fallback.trim()
        : NH_DEFAULT_BRAND_TITLE;
    if (typeof value !== "string") {
        return baseFallback;
    }

    const cleaned = value
        .replace(/[\u0000-\u001F\u007F]/g, "")
        .replace(/\s+/g, " ")
        .trim();
    return cleaned === "" ? baseFallback : cleaned;
}

function normalizeBrandBool(value, fallback) {
    if (value === undefined || value === null) {
        return fallback === true;
    }
    if (typeof value === "boolean") {
        return value;
    }
    if (typeof value === "number") {
        return value === 1;
    }
    if (typeof value === "string") {
        const normalized = value.trim().toLowerCase();
        if (normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on") {
            return true;
        }
        if (normalized === "0" || normalized === "false" || normalized === "no" || normalized === "off") {
            return false;
        }
    }
    return fallback === true;
}

function normalizeBrandLogoSource(value, fallback) {
    const fallbackSource = (typeof fallback === "string" && fallback.trim() !== "")
        ? fallback.trim()
        : NH_DEFAULT_BRAND_LOGO_SOURCE;

    if (typeof value !== "string") {
        return fallbackSource;
    }

    const cleaned = value
        .replace(/[\u0000-\u001F\u007F]/g, "")
        .trim();

    if (cleaned === "" || cleaned.length > NH_BRAND_LOGO_MAX_LENGTH) {
        return fallbackSource;
    }

    const lowered = cleaned.toLowerCase();
    if (lowered.startsWith("http://") || lowered.startsWith("https://")) {
        return cleaned;
    }

    if (/^data:image\/[a-z0-9.+-]+;base64,[a-z0-9+/=]+$/i.test(cleaned)) {
        return cleaned;
    }

    return fallbackSource;
}

function ensureBrandLogoSlots() {
    NH_BRAND_HEADER_BLOCK_SELECTORS.forEach(function (selector) {
        const containers = document.querySelectorAll(selector);
        containers.forEach(function (container) {
            if (!container || container.dataset.nhBrandLogoReady === "1") {
                return;
            }

            const children = Array.from(container.childNodes);
            const textStack = document.createElement("div");
            textStack.className = "nh-brand-text-stack";
            children.forEach(function (child) {
                textStack.appendChild(child);
            });

            const logo = document.createElement("img");
            logo.className = "nh-brand-logo";
            logo.alt = "Brand logo";
            logo.decoding = "async";
            logo.loading = "lazy";
            logo.style.display = "none";

            container.classList.add("nh-brand-header-block");
            container.appendChild(logo);
            container.appendChild(textStack);
            container.dataset.nhBrandLogoReady = "1";
        });
    });
}

function applyBrandLogoToDom(stateOverride) {
    const state = (stateOverride && typeof stateOverride === "object")
        ? stateOverride
        : (window.nhExtendedState || {});
    const showLogo = state.available === true && normalizeBrandBool(state.logoEnabled, true);
    const logoSource = normalizeBrandLogoSource(state.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE);

    ensureBrandLogoSlots();

    document.querySelectorAll(".nh-brand-header-block").forEach(function (container) {
        const logo = container.querySelector(".nh-brand-logo");
        if (!logo) return;

        if (showLogo) {
            if (logo.getAttribute("src") !== logoSource) {
                logo.setAttribute("src", logoSource);
            }
            logo.style.display = "";
            container.classList.add("has-logo");
        } else {
            logo.removeAttribute("src");
            logo.style.display = "none";
            container.classList.remove("has-logo");
        }
    });
}

function buildBrandTitleMarkup(title, squareDotEnabled) {
    const normalized = normalizeBrandTitle(title, NH_DEFAULT_BRAND_TITLE);
    const chunks = normalized.split(" ").filter(Boolean);
    const words = chunks.length > 0 ? chunks : [normalized];
    const useSquareDot = normalizeBrandBool(squareDotEnabled, false);

    if (!useSquareDot) {
        return words.map(function (word) {
            return nhEscapeHtml(word.toUpperCase());
        }).join(" ");
    }

    return words.map(function (word, index) {
        const safeWord = nhEscapeHtml(word.toUpperCase());
        if (index < words.length - 1) {
            return safeWord + '<span class="square-dot"></span>';
        }
        return safeWord;
    }).join("");
}

function getDefaultBrandMenuTitles(baseTitle) {
    const fallbackTitle = normalizeBrandTitle(baseTitle, NH_DEFAULT_BRAND_TITLE);
    return {
        nh: fallbackTitle,
        agency: fallbackTitle,
        pap: fallbackTitle,
        garage: fallbackTitle,
        wardrobe: fallbackTitle
    };
}

function normalizeBrandMenuTitles(menuTitles, fallbackTitle) {
    const normalized = getDefaultBrandMenuTitles(fallbackTitle);
    if (!menuTitles || typeof menuTitles !== "object") {
        return normalized;
    }

    NH_BRAND_CONTEXTS.forEach(function (context) {
        if (Object.prototype.hasOwnProperty.call(menuTitles, context)) {
            normalized[context] = normalizeBrandTitle(menuTitles[context], normalized[context]);
        }
    });

    return normalized;
}

function resolveBrandTitleForContext(context, stateOverride) {
    const state = (stateOverride && typeof stateOverride === "object")
        ? stateOverride
        : (window.nhExtendedState || {});
    const normalizedTitle = normalizeBrandTitle(state.title, NH_DEFAULT_BRAND_TITLE);
    const normalizedMenuTitles = normalizeBrandMenuTitles(state.menuTitles, normalizedTitle);
    const resolvedContext = NH_BRAND_CONTEXTS.includes(context) ? context : "nh";

    if (state.perMenuEnabled === true) {
        return normalizeBrandTitle(normalizedMenuTitles[resolvedContext], normalizedTitle);
    }

    return normalizedTitle;
}

function applyBrandStateToDom(stateOverride) {
    const state = (stateOverride && typeof stateOverride === "object")
        ? stateOverride
        : (window.nhExtendedState || {});

    NH_BRAND_CONTEXTS.forEach(function (context) {
        const selectors = NH_BRAND_SELECTORS[context] || [];
        const contextTitle = resolveBrandTitleForContext(context, state);
        const markup = buildBrandTitleMarkup(contextTitle, state.squareDotEnabled);

        selectors.forEach(function (selector) {
            const elements = document.querySelectorAll(selector);
            elements.forEach(function (element) {
                element.innerHTML = markup;
            });
        });
    });

    const mainTitle = resolveBrandTitleForContext("nh", state);
    document.title = mainTitle + " (by Junnho)";
    applyBrandLogoToDom(state);
}

window.getBrandTitleForContext = function (context) {
    return resolveBrandTitleForContext(context, window.nhExtendedState || {});
};

window.applyBrandTitle = function (title) {
    const state = window.nhExtendedState || {};
    const normalizedTitle = normalizeBrandTitle(title, NH_DEFAULT_BRAND_TITLE);
    const nextState = {
        available: state.available === true,
        title: normalizedTitle,
        perMenuEnabled: state.perMenuEnabled === true,
        squareDotEnabled: normalizeBrandBool(state.squareDotEnabled, false),
        logoEnabled: normalizeBrandBool(state.logoEnabled, true),
        logoSource: normalizeBrandLogoSource(state.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE),
        menuTitles: normalizeBrandMenuTitles(state.menuTitles, normalizedTitle),
        canCustomize: state.canCustomize === true,
        canEdit: state.canEdit === true,
        loaded: state.loaded === true,
        resource: state.resource || NH_EXT_RESOURCE_NAME,
        maxLength: Number.isFinite(Number(state.maxLength)) ? Number(state.maxLength) : 48,
        lastFetchAt: Number.isFinite(Number(state.lastFetchAt)) ? Number(state.lastFetchAt) : 0
    };

    window.nhExtendedState = nextState;
    applyBrandStateToDom(nextState);
};

window.applyBrandTitleForContext = function (context, title) {
    const state = window.nhExtendedState || {};
    const baseTitle = normalizeBrandTitle(state.title, NH_DEFAULT_BRAND_TITLE);
    const normalizedContext = NH_BRAND_CONTEXTS.includes(context) ? context : "nh";
    const menuTitles = normalizeBrandMenuTitles(state.menuTitles, baseTitle);
    menuTitles[normalizedContext] = normalizeBrandTitle(title, baseTitle);

    const nextState = {
        available: state.available === true,
        title: baseTitle,
        perMenuEnabled: state.perMenuEnabled === true,
        squareDotEnabled: normalizeBrandBool(state.squareDotEnabled, false),
        logoEnabled: normalizeBrandBool(state.logoEnabled, true),
        logoSource: normalizeBrandLogoSource(state.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE),
        menuTitles: menuTitles,
        canCustomize: state.canCustomize === true,
        canEdit: state.canEdit === true,
        loaded: state.loaded === true,
        resource: state.resource || NH_EXT_RESOURCE_NAME,
        maxLength: Number.isFinite(Number(state.maxLength)) ? Number(state.maxLength) : 48,
        lastFetchAt: Number.isFinite(Number(state.lastFetchAt)) ? Number(state.lastFetchAt) : 0
    };

    window.nhExtendedState = nextState;
    applyBrandStateToDom(nextState);
};

window.applyExtendedStatePayload = function (payload) {
    const incoming = (payload && typeof payload === "object") ? payload : {};
    const previousState = window.nhExtendedState || {};
    const nextState = {
        available: incoming.available === true,
        title: normalizeBrandTitle(incoming.title, NH_DEFAULT_BRAND_TITLE),
        perMenuEnabled: incoming.perMenuEnabled === true,
        squareDotEnabled: normalizeBrandBool(incoming.squareDotEnabled, false),
        logoEnabled: normalizeBrandBool(incoming.logoEnabled, incoming.available === true),
        logoSource: normalizeBrandLogoSource(incoming.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE),
        menuTitles: normalizeBrandMenuTitles(incoming.menuTitles, incoming.title || NH_DEFAULT_BRAND_TITLE),
        canCustomize: incoming.canCustomize === true,
        canEdit: incoming.canEdit === true,
        loaded: true,
        resource: incoming.resource || NH_EXT_RESOURCE_NAME,
        maxLength: Number.isFinite(Number(incoming.maxLength)) ? Number(incoming.maxLength) : 48,
        lastFetchAt: Date.now(),
    };

    if (nextState.available !== true && previousState.available === true) {
        const misses = (Number(window.__nhExtendedTransientUnavailableCount) || 0) + 1;
        window.__nhExtendedTransientUnavailableCount = misses;

        if (misses < 3) {
            const preserved = {
                available: true,
                title: normalizeBrandTitle(previousState.title, NH_DEFAULT_BRAND_TITLE),
                perMenuEnabled: previousState.perMenuEnabled === true,
                squareDotEnabled: normalizeBrandBool(previousState.squareDotEnabled, false),
                logoEnabled: normalizeBrandBool(previousState.logoEnabled, true),
                logoSource: normalizeBrandLogoSource(previousState.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE),
                menuTitles: normalizeBrandMenuTitles(
                    previousState.menuTitles,
                    previousState.title || NH_DEFAULT_BRAND_TITLE
                ),
                canCustomize: previousState.canCustomize === true,
                canEdit: previousState.canEdit === true,
                loaded: true,
                resource: previousState.resource || NH_EXT_RESOURCE_NAME,
                maxLength: Number.isFinite(Number(previousState.maxLength)) ? Number(previousState.maxLength) : 48,
                lastFetchAt: Date.now(),
            };

            window.nhExtendedState = preserved;
            applyBrandStateToDom(preserved);
            if (typeof window.applyExtendedTabState === "function") {
                window.applyExtendedTabState(preserved);
            }
            if (preserved.available === true) {
                ensureExtendedMapModuleLoaded({ resource: preserved.resource });
            }
            return preserved;
        }
    } else {
        window.__nhExtendedTransientUnavailableCount = 0;
    }

    if (!nextState.available) {
        nextState.title = NH_DEFAULT_BRAND_TITLE;
        nextState.perMenuEnabled = false;
        nextState.squareDotEnabled = false;
        nextState.logoEnabled = false;
        nextState.logoSource = NH_DEFAULT_BRAND_LOGO_SOURCE;
        nextState.menuTitles = getDefaultBrandMenuTitles(NH_DEFAULT_BRAND_TITLE);
        nextState.canCustomize = false;
        nextState.canEdit = false;
    }

    nextState.menuTitles = normalizeBrandMenuTitles(nextState.menuTitles, nextState.title);

    window.nhExtendedState = nextState;
    applyBrandStateToDom(nextState);

    if (typeof window.applyExtendedTabState === "function") {
        window.applyExtendedTabState(nextState);
    }

    if (nextState.available === true) {
        ensureExtendedMapModuleLoaded({ resource: nextState.resource });
    }

    return nextState;
};

window.fetchExtendedState = function (forceRefresh) {
    const deferred = $.Deferred();
    const now = Date.now();
    const state = window.nhExtendedState || {};
    const canUseCache = state.loaded === true
        && !forceRefresh
        && Number.isFinite(state.lastFetchAt)
        && (now - state.lastFetchAt) < NH_EXTENDED_STATE_TTL_MS;

    if (canUseCache) {
        applyBrandStateToDom(state);
        if (typeof window.applyExtendedTabState === "function") {
            window.applyExtendedTabState(state);
        }
        deferred.resolve(state);
        return deferred.promise();
    }

    $.post("https://next_housing/getExtendedState", JSON.stringify({ force: !!forceRefresh }), function (resp) {
        let payload = null;
        try {
            payload = (typeof resp === "string") ? JSON.parse(resp) : resp;
        } catch (_) {
            payload = null;
        }

        const resolved = window.applyExtendedStatePayload(payload);
        deferred.resolve(resolved);
    }).fail(function () {
        const currentState = window.nhExtendedState || {};
        if (currentState.loaded === true) {
            const preserved = {
                available: currentState.available === true,
                title: normalizeBrandTitle(currentState.title, NH_DEFAULT_BRAND_TITLE),
                perMenuEnabled: currentState.perMenuEnabled === true,
                squareDotEnabled: normalizeBrandBool(currentState.squareDotEnabled, false),
                logoEnabled: normalizeBrandBool(currentState.logoEnabled, true),
                logoSource: normalizeBrandLogoSource(currentState.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE),
                menuTitles: normalizeBrandMenuTitles(
                    currentState.menuTitles,
                    currentState.title || NH_DEFAULT_BRAND_TITLE
                ),
                canCustomize: currentState.canCustomize === true,
                canEdit: currentState.canEdit === true,
                loaded: true,
                resource: currentState.resource || NH_EXT_RESOURCE_NAME,
                maxLength: Number.isFinite(Number(currentState.maxLength)) ? Number(currentState.maxLength) : 48,
                lastFetchAt: Date.now(),
            };

            window.nhExtendedState = preserved;
            applyBrandStateToDom(preserved);
            if (typeof window.applyExtendedTabState === "function") {
                window.applyExtendedTabState(preserved);
            }
            deferred.resolve(preserved);
            return;
        }

        const fallback = window.applyExtendedStatePayload({
            available: false,
            title: NH_DEFAULT_BRAND_TITLE,
            perMenuEnabled: false,
            squareDotEnabled: false,
            logoEnabled: false,
            logoSource: NH_DEFAULT_BRAND_LOGO_SOURCE,
            menuTitles: getDefaultBrandMenuTitles(NH_DEFAULT_BRAND_TITLE),
            canCustomize: false,
            canEdit: false,
        });
        deferred.resolve(fallback);
    });

    return deferred.promise();
};


function clearScanTimeout() {
    if (window.scanTimeoutId) {
        clearTimeout(window.scanTimeoutId);
        window.scanTimeoutId = null;
    }
}

const MANAGE_LOADING_DELAY_MS = 180;
const MANAGE_SCAN_TIMEOUT_MS = 1000;

function clearManageLoadingDelay() {
    if (window.manageLoadingDelayId) {
        clearTimeout(window.manageLoadingDelayId);
        window.manageLoadingDelayId = null;
    }
}

function finalizeManageScan() {
    window.manageScanWaitingForResponse = false;
    window.manageScanToken = (window.manageScanToken || 0) + 1;
    clearScanTimeout();
    clearManageLoadingDelay();
}

function hideManageStatePanels() {
    $("#manage-loading-state").hide();
    $("#empty-state").hide();
    $("#house-info-state").hide();
    $("#delete-btn").hide();
    $("#toggle-lock-btn").hide();
    $("#interior-change-section").hide();
    $("#show-more-options-container").hide();
    $("#coords-sections-container").hide();
    $("#entrance-coords-section").hide();
    $("#garage-coords-section").hide();
    $(".create-form").addClass("no-scroll");
}

function hasManageHouseData() {
    const houseId = ($("#houseid").text() || "").trim();
    return houseId !== "" && houseId !== "-" && houseId.toUpperCase() !== "N/A";
}

function beginManageScan(options) {
    const opts = options || {};
    const loadingDelay = (typeof opts.loadingDelayMs === 'number' && opts.loadingDelayMs >= 0)
        ? opts.loadingDelayMs
        : MANAGE_LOADING_DELAY_MS;
    const scanTimeout = (typeof opts.scanTimeoutMs === 'number' && opts.scanTimeoutMs > 0)
        ? opts.scanTimeoutMs
        : MANAGE_SCAN_TIMEOUT_MS;
    const keepCurrentInfo = opts.keepCurrentInfo === true && hasManageHouseData();
    const shouldShowLoading = opts.suppressLoading !== true && !keepCurrentInfo;
    const fallbackToEmpty = opts.fallbackToEmpty !== false;

    window.manageScanWaitingForResponse = true;
    window.manageScanToken = (window.manageScanToken || 0) + 1;
    const scanToken = window.manageScanToken;
    clearScanTimeout();
    clearManageLoadingDelay();

    $('#manage-houses-loading').hide();
    $('#manage-houses-empty').hide();
    if (keepCurrentInfo) {
        $("#manage-loading-state").hide();
        $("#empty-state").hide();
    } else {
        hideManageStatePanels();
    }

    if (shouldShowLoading) {
        window.manageLoadingDelayId = setTimeout(function () {
            if (scanToken !== window.manageScanToken) {
                return;
            }
            window.manageLoadingDelayId = null;
            if (!window.manageScanWaitingForResponse) {
                return;
            }

            showManageLoadingState();

            loadAllHousesData(function (houses) {
                if (scanToken !== window.manageScanToken) {
                    return;
                }
                if (!window.manageScanWaitingForResponse) {
                    return;
                }

                if (houses.length === 0 && $('#manage-loading-state').is(':visible')) {
                    clearScanTimeout();
                    showManageEmptyState();
                }
            });
        }, loadingDelay);
    }

    window.scanTimeoutId = setTimeout(function () {
        if (scanToken !== window.manageScanToken) {
            return;
        }
        window.scanTimeoutId = null;
        window.manageScanWaitingForResponse = false;
        clearManageLoadingDelay();

        if (!fallbackToEmpty) {
            return;
        }

        $('#manage-loading-state').hide();
        showManageEmptyState();
    }, scanTimeout);

    return $.post('https://next_housing/scan', JSON.stringify({ scanSeq: scanToken }))
        .fail(function () {
            if (scanToken !== window.manageScanToken) {
                return;
            }
            if (!fallbackToEmpty) {
                finalizeManageScan();
                return;
            }
            finalizeManageScan();
            showManageEmptyState();
        });
}





$(function () {
    window.nhIsAdmin = false;
    window.__nhSettingsHydrating = window.__nhSettingsHydrating === true;
    window.__nhSettingsHydrationTimer = window.__nhSettingsHydrationTimer || null;
    window.__nhSettingsInitToken = window.__nhSettingsInitToken || 0;
    window.__nhSettingsUserTouched = window.__nhSettingsUserTouched || {};
    window.startSettingsHydration = function (durationMs) {
        const ms = (typeof durationMs === 'number' && durationMs > 0) ? durationMs : 1500;
        window.__nhSettingsHydrating = true;
        if (window.__nhSettingsHydrationTimer) {
            clearTimeout(window.__nhSettingsHydrationTimer);
        }
        window.__nhSettingsHydrationTimer = setTimeout(function () {
            window.__nhSettingsHydrating = false;
            window.__nhSettingsHydrationTimer = null;
        }, ms);
    };
    window.resetSettingsInitState = function () {
        window.__nhSettingsInitToken = (window.__nhSettingsInitToken || 0) + 1;
        window.__nhSettingsUserTouched = {};
        return window.__nhSettingsInitToken;
    };
    window.isSettingsInitTokenCurrent = function (token) {
        return token === window.__nhSettingsInitToken;
    };
    window.markSettingsFieldTouched = function (fieldId) {
        if (!fieldId) return;
        window.__nhSettingsUserTouched = window.__nhSettingsUserTouched || {};
        window.__nhSettingsUserTouched[fieldId] = true;
    };
    window.hasSettingsFieldBeenTouched = function (fieldId) {
        if (!fieldId) return false;
        return !!(window.__nhSettingsUserTouched && window.__nhSettingsUserTouched[fieldId]);
    };

    function display(bool) {
        if (bool) {
            $("#nui-background").show();
            $("#container").addClass('show');
        } else {
            window.nhIsAdmin = false;
            $("#nui-background").hide();
            $("#container").removeClass('show');
            $("#preview-container").hide();
            $("#info-container").hide();
        }
    }

    $(document).on('keydown', function (event) {
        if (event.key === "Escape") {
            
            if ($('#image-lightbox').length && !$('#image-lightbox').hasClass('hidden')) {
                return;
            }

            
            
            if (window.ModalManager && window.ModalManager.isOpen) {
                event.preventDefault();
                event.stopPropagation();
                window.ModalManager.close();
                return;
            }

            
            if ($('#container').hasClass('show')) {
                $.post('http://next_housing/exit', JSON.stringify({}));
                display(false);
            } else {
                
                const $pap = $('#pap-interface');
                if ($pap.length && !$pap.hasClass('hidden')) {
                    if (typeof hidePapInterface === 'function') {
                        hidePapInterface();
                    } else {
                        $pap.addClass('hidden');
                        $.post('https://next_housing/closePapInterface', JSON.stringify({}));
                    }
                }
            }
        }
    });


    let currentPaymentHouseId = null;
    let keysModalState = {
        houseId: null,
        identifier: null,
        keys: [],
        isOpen: false
    };

    loadCurrencySymbol();

    function openPaymentMethodModal(houseId, houseNumber, price, houseName) {
        currentPaymentHouseId = houseId;
        const acquisitionTitle = translations.job_modal_property_acquisition;
        const houseLabel = (translations.job_house_number).replace(/\s*#\s*$/, '').trim();
        const resolvedHouseName = (houseName || '').toString().trim();
        const localNameIsId = resolvedHouseName !== '' && (resolvedHouseName === String(houseNumber || '') || resolvedHouseName === String(houseId || ''));
        const fallbackHouseName = `${translations.job_house_number}${houseNumber || houseId || ''}`;
        const houseDisplayName = (resolvedHouseName !== '' && !localNameIsId) ? resolvedHouseName : fallbackHouseName;

        window.ModalManager.open({
            title: translations.job_buy_payment_method,
            containerClass: 'pap-form-modal agency-house-buy-modal',
            mainBlockHeader: {
                title: acquisitionTitle,
                target: '.agency-house-buy-main-block'
            },
            bodyHTML: `
                <div class="agency-modal-main-block agency-house-buy-main-block">
                    <div class="agency-house-buy-summary">
                        <div class="agency-house-buy-summary-item">
                            <span class="agency-house-buy-summary-label">${houseLabel}</span>
                            <span class="agency-house-buy-summary-value">${houseDisplayName}</span>
                        </div>
                        <div class="agency-house-buy-summary-item">
                            <span class="agency-house-buy-summary-label">${translations.job_house_price}</span>
                            <span class="agency-house-buy-summary-value agency-house-buy-summary-price">${formatPrice(price)}</span>
                        </div>
                    </div>
                    <div class="agency-house-buy-actions">
                        <div class="agency-house-buy-section-label">${translations.job_buy_payment_method}</div>
                        <button class="pap-btn primary multimodal-action-btn agency-house-buy-btn" id="payment-treasury-btn">
                            <i class="ph ph-bank"></i>
                            <span>${translations.job_buy_with_treasury}</span>
                        </button>
                        <button class="pap-btn secondary multimodal-action-btn agency-house-buy-btn" id="payment-bank-btn">
                            <i class="ph ph-credit-card"></i>
                            <span>${translations.job_buy_with_bank}</span>
                        </button>
                        <button class="pap-btn secondary multimodal-action-btn agency-house-buy-btn" id="payment-cash-btn">
                            <i class="ph ph-money-wavy"></i>
                            <span>${translations.job_buy_with_cash}</span>
                        </button>
                    </div>
                </div>
            `,
            buttons: [
                {
                    text: translations.job_modal_cancel_btn,
                    class: 'pap-btn secondary multimodal-action-btn',
                    onClick: function () {
                        window.ModalManager.close();
                    }
                }
            ],
            onOpen: function ($modal) {
                $modal.find('#payment-treasury-btn').on('click', function () {
                    if (currentPaymentHouseId) {
                        $.post('http://next_housing/buyHouseForAgencyFromMarker', JSON.stringify({
                            houseId: currentPaymentHouseId,
                            paymentMethod: 'treasury'
                        }), function (response) {
                            if (response === 'ok') {
                                window.ModalManager.close();
                            }
                        });
                    }
                });

                $modal.find('#payment-bank-btn').on('click', function () {
                    if (currentPaymentHouseId) {
                        $.post('http://next_housing/buyHouseForAgencyFromMarker', JSON.stringify({
                            houseId: currentPaymentHouseId,
                            paymentMethod: 'bank'
                        }), function (response) {
                            if (response === 'ok') {
                                window.ModalManager.close();
                            }
                        });
                    }
                });

                $modal.find('#payment-cash-btn').on('click', function () {
                    if (currentPaymentHouseId) {
                        $.post('http://next_housing/buyHouseForAgencyFromMarker', JSON.stringify({
                            houseId: currentPaymentHouseId,
                            paymentMethod: 'cash'
                        }), function (response) {
                            if (response === 'ok') {
                                window.ModalManager.close();
                            }
                        });
                    }
                });
            },
            onClose: function () {
                currentPaymentHouseId = null;
                $.post('http://next_housing/closePaymentMethodModal', JSON.stringify({}));
            }
        });
    }

    function resetKeysModalState() {
        keysModalState = {
            houseId: null,
            identifier: null,
            keys: [],
            isOpen: false
        };
    }

    function isKeysModalActive() {
        if (!window.ModalManager || !window.ModalManager.isOpen) {
            return false;
        }

        const currentConfig = window.ModalManager.currentConfig || {};
        const containerClass = String(currentConfig.containerClass || '');
        return containerClass.indexOf('keys-management-modal') !== -1;
    }

    function showKeysModalMessage(message, title) {
        const t = translations || {};
        const safeMessage = $('<div>').text(message || t.action_impossible).html().replace(/\n/g, '<br>');

        window.ModalManager.open({
            title: title || t.key_management,
            stack: true,
            containerClass: 'multimodal-message-modal',
            bodyHTML: `
                <div class="pap-prompt-label" style="text-align: center;">
                    ${safeMessage}
                </div>
            `,
            buttons: [
                {
                    text: t.job_modal_ok || t.close,
                    class: 'pap-btn primary multimodal-action-btn',
                    onClick: function () {
                        window.ModalManager.close();
                    }
                }
            ]
        });
    }

    function refreshKeysModalTexts() {
        if (!isKeysModalActive()) {
            return;
        }

        const t = translations || {};
        const addKeyLabel = t.add_key;

        $('#dynamic-modal-subtitle').text(t.key_management);
        $('#keys-modal-add-label').text(t.who_to_give_key);
        $('#keys-modal-list-label').text(t.view_delete_keys);
        $('#keys-modal-add-btn')
            .attr('title', addKeyLabel)
            .attr('aria-label', addKeyLabel);
        $('#keys-modal-playerid').attr('placeholder', t.who_to_give_key);
    }

    function renderKeysModalList(keys) {
        const $list = $('#keys-modal-list');
        if (!$list.length) {
            return;
        }

        $list.empty();
        const list = Array.isArray(keys) ? keys : [];
        const t = translations || {};

        if (list.length === 0) {
            const emptyLabel = String(t.no_keys || '');
            const emptyBadge = String(t.view_delete_keys || '');
            const $row = $('<div class="keys-row keys-empty-row"></div>');
            $row.append($('<span class="keys-name"></span>').text(emptyLabel));
            $row.append($('<span class="keys-badge"></span>').text(emptyBadge));
            $list.append($row);
            return;
        }
        list.forEach(function (key) {
            const name = String((key && (key.player_name || key.name || key.identifier)) || '-');
            const identifier = String((key && key.identifier) || '');
            const isOwner = !!(key && key.isOwner === true);
            const isTenant = !!(key && key.isTenant === true);
            const isProtected = isOwner || isTenant;

            const badgeText = isOwner
                ? t.owner
                : (isTenant ? t.tenant : null);

            const $row = $('<div class="keys-row"></div>');
            $row.append($('<span class="keys-name"></span>').text(name));

            if (badgeText) {
                $row.append($('<span class="keys-badge"></span>').text(badgeText));
            }

            if (!isProtected) {
                const $removeBtn = $('<button class="pap-btn danger multimodal-action-btn keys-remove-btn"><i class="ph ph-trash"></i></button>');
                $removeBtn.attr('data-player', name);
                $removeBtn.attr('data-identifier', identifier);
                $row.append($removeBtn);
            }

            $list.append($row);
        });
    }

    function submitKeyAddition($scope) {
        if (!keysModalState.houseId) {
            return;
        }

        const $input = $scope.find('#keys-modal-playerid');
        const rawValue = String($input.val() || '').trim();
        const playerId = Number(rawValue);

        if (!rawValue || !Number.isInteger(playerId) || playerId <= 0) {
            showKeysModalMessage(
                (translations && (translations.invalid_parameters || translations.action_impossible)),
                (translations && translations.key_management)
            );
            $input.trigger('focus');
            return;
        }

        $.post('http://next_housing/keys:add', JSON.stringify({
            houseId: keysModalState.houseId,
            playerId: playerId
        }));

        $input.val('');
        $input.trigger('focus');
    }

    function requestKeyRemoval(targetName, targetIdentifier) {
        if (!keysModalState.houseId || !targetIdentifier) {
            return;
        }

        const t = translations || {};
        const template = t.confirm_remove_key || t.confirm_deletion || '';
        const confirmMessage = template.replace('%s', targetName || '-');
        const confirmTitle = t.confirmation || t.confirm;

        const handleConfirmation = function (confirmed) {
            if (!confirmed) {
                return;
            }

            $.post('http://next_housing/keys:remove', JSON.stringify({
                houseId: keysModalState.houseId,
                playerName: targetName,
                playerIdentifier: targetIdentifier
            }));
        };

        if (typeof showJobConfirmWithOptions === 'function') {
            showJobConfirmWithOptions(confirmMessage, confirmTitle, handleConfirmation, { stack: true });
            return;
        }

        if (typeof showJobConfirm === 'function') {
            showJobConfirm(confirmMessage, confirmTitle, handleConfirmation);
            return;
        }

        handleConfirmation(window.confirm(confirmMessage));
    }

    function openKeysModal(data) {
        if (data && data.translations) {
            window.translations = data.translations;
            translations = window.translations;
            window.currentLocale = data.locale || 'en';
            currentLocale = window.currentLocale;
        }

        keysModalState.houseId = data && data.houseId || null;
        keysModalState.identifier = data && data.identifier || null;
        keysModalState.keys = (data && Array.isArray(data.keys)) ? data.keys : [];
        keysModalState.isOpen = true;

        const t = translations || {};

        window.ModalManager.open({
            title: t.key_management,
            containerClass: 'pap-form-modal keys-management-modal',
            footerClass: 'pap-form-modal-footer',
            mainBlockHeader: {
                title: t.key_management,
                target: '.keys-management-main-block'
            },
            bodyHTML: `
                <div class="agency-modal-main-block pap-form-main-block keys-management-main-block">
                    <div class="pap-form-group">
                        <label id="keys-modal-add-label" class="pap-form-label">${t.who_to_give_key}</label>
                        <div class="keys-modal-add-row">
                            <input type="number" id="keys-modal-playerid" class="pap-form-input pap-form-control" placeholder="${t.who_to_give_key}" min="1" />
                            <button class="visit-btn keys-modal-add-btn" id="keys-modal-add-btn"><i class="ph ph-plus" aria-hidden="true"></i></button>
                        </div>
                    </div>

                    <div class="pap-form-group keys-management-list-group">
                        <label id="keys-modal-list-label" class="pap-form-label">${t.view_delete_keys}</label>
                        <div id="keys-modal-list" class="keys-modal-list"></div>
                    </div>
                </div>
            `,
            buttons: [
                {
                    text: t.job_modal_close || t.close,
                    class: 'pap-btn secondary multimodal-action-btn',
                    onClick: function () {
                        window.ModalManager.close();
                    }
                }
            ],
            onOpen: function ($modal) {
                renderKeysModalList(keysModalState.keys);
                refreshKeysModalTexts();

                const $input = $modal.find('#keys-modal-playerid');
                $input.trigger('focus');

                $modal.find('#keys-modal-add-btn').on('click', function () {
                    submitKeyAddition($modal);
                });

                $input.on('keydown', function (event) {
                    if (event.key !== 'Enter') return;
                    event.preventDefault();
                    submitKeyAddition($modal);
                });

                $modal.on('click', '.keys-remove-btn', function () {
                    const $button = $(this);
                    const targetName = String($button.attr('data-player') || '');
                    const targetIdentifier = String($button.attr('data-identifier') || '');
                    requestKeyRemoval(targetName, targetIdentifier);
                });
            },
            onClose: function () {
                resetKeysModalState();
                $.post('http://next_housing/keys:close', JSON.stringify({}));
            }
        });
    }

    window.closeKeysModal = function () {
        if (window.ModalManager && window.ModalManager.isOpen && keysModalState.houseId) {
            if (!isKeysModalActive()) {
                window.ModalManager.close();
                setTimeout(function () {
                    if (isKeysModalActive()) {
                        window.ModalManager.close();
                    }
                }, 0);
                return;
            }

            window.ModalManager.close();
            return;
        }

        resetKeysModalState();
        $.post('http://next_housing/keys:close', JSON.stringify({}));
    };

    function playDoorbellSound() {
        const audio = document.getElementById('doorbell-sound');
        if (audio) {
            
            if (audio.volume !== 0.05) {
                audio.volume = 0.05; 
            }
            audio.currentTime = 0;

            audio.play().catch(function (error) {
            });
        }
    }

    function playDoorSound() {
        const audio = document.getElementById('door-sound');
        if (audio) {
            if (audio.volume !== 0.05) {
                audio.volume = 0.05;
            }
            audio.currentTime = 0;
            audio.play().catch(function (error) {

            });
        }
    }

    window.addEventListener('message', function (event) {
        if (event.data && event.data.scriptVersion) {
            syncScriptVersionBadges(event.data.scriptVersion);
        }

        if (event.data.type === "extendedTitleChanged") {
            const incomingExtended = (event.data.extended && typeof event.data.extended === "object")
                ? event.data.extended
                : {};
            window.applyExtendedStatePayload({
                available: true,
                title: event.data.title || event.data.brandTitle || incomingExtended.title || NH_DEFAULT_BRAND_TITLE,
                perMenuEnabled: (event.data.perMenuEnabled !== undefined)
                    ? event.data.perMenuEnabled === true
                    : incomingExtended.perMenuEnabled === true,
                squareDotEnabled: (event.data.squareDotEnabled !== undefined)
                    ? normalizeBrandBool(event.data.squareDotEnabled, false)
                    : normalizeBrandBool(incomingExtended.squareDotEnabled, normalizeBrandBool(window.nhExtendedState && window.nhExtendedState.squareDotEnabled, false)),
                logoEnabled: (event.data.logoEnabled !== undefined)
                    ? normalizeBrandBool(event.data.logoEnabled, true)
                    : normalizeBrandBool(incomingExtended.logoEnabled, normalizeBrandBool(window.nhExtendedState && window.nhExtendedState.logoEnabled, true)),
                logoSource: (event.data.logoSource !== undefined)
                    ? normalizeBrandLogoSource(event.data.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE)
                    : normalizeBrandLogoSource(
                        incomingExtended.logoSource,
                        normalizeBrandLogoSource(window.nhExtendedState && window.nhExtendedState.logoSource, NH_DEFAULT_BRAND_LOGO_SOURCE)
                    ),
                menuTitles: event.data.menuTitles || incomingExtended.menuTitles,
                canCustomize: window.nhExtendedState && window.nhExtendedState.canCustomize === true,
                canEdit: window.nhExtendedState && window.nhExtendedState.canEdit === true,
            });
            return;
        }

        if (event.data.type === "extendedState" && event.data.extended) {
            window.applyExtendedStatePayload(event.data.extended);
            return;
        }

        if (event.data.type === "openPaymentMethodModal") {
            openPaymentMethodModal(event.data.houseId, event.data.houseNumber, event.data.price, event.data.houseName);
        } else if (event.data.type === "openKeysModal") {
            openKeysModal(event.data);
        } else if (event.data.type === "updateKeysModal") {
            if (event.data.translations) {
                window.translations = event.data.translations;
                translations = window.translations;
                window.currentLocale = event.data.locale || 'en';
                currentLocale = window.currentLocale;
            }
            if (Array.isArray(event.data.keys)) {
                keysModalState.keys = event.data.keys;
            }

            if (isKeysModalActive()) {
                refreshKeysModalTexts();
                renderKeysModalList(keysModalState.keys);
            }
        } else if (event.data.type === "showHelp") {
            showHelpMessage(event.data.messages);
        } else if (event.data.type === "hideHelp") {
            hideHelpMessages();
        } else if (event.data.type === "close") {
            display(false);
        } else if (event.data.type === "playDoorbellSound") {
            playDoorbellSound();
        } else if (event.data.type === "playDoorSound") {
            playDoorSound();
        }
    });

    window.addEventListener('message', function (event) {
        if (event.data && event.data.brandTitle) {
            const hasExtendedPayload = event.data.extended && typeof event.data.extended === 'object';
            const explicitUnavailable = hasExtendedPayload && event.data.extended.available === false;
            const currentState = window.nhExtendedState || {};

            if (currentState.perMenuEnabled === true) {
                if (typeof window.applyExtendedStatePayload === 'function' && event.data.extended) {
                    window.applyExtendedStatePayload(event.data.extended);
                } else {
                    applyBrandStateToDom(currentState);
                }
            } else {
                if (explicitUnavailable) {
                    window.applyBrandTitle(NH_DEFAULT_BRAND_TITLE);
                } else if (typeof event.data.brandTitle === 'string' && event.data.brandTitle.trim() !== '') {
                    window.applyBrandTitle(event.data.brandTitle);
                } else if (currentState.available === true) {
                    window.applyBrandTitle(currentState.title || NH_DEFAULT_BRAND_TITLE);
                } else {
                    window.applyBrandTitle(NH_DEFAULT_BRAND_TITLE);
                }
            }
        }

        if (event.data && event.data.extended) {
            window.applyExtendedStatePayload(event.data.extended);
        }

        if (event.data.translations) {
            window.translations = event.data.translations;
            window.currentLocale = event.data.locale || 'en';
            
            translations = window.translations;
            currentLocale = window.currentLocale;
            if (typeof translateInterface === 'function') translateInterface();
            refreshKeysModalTexts();
        }

        if (event.data.shells) {
            currentShells = event.data.shells || [];
            if (typeof renderShells === 'function') renderShells();
        }

        if (event.data.type === "shellsUpdated" && event.data.shells) {
            currentShells = event.data.shells || [];
            if (typeof renderShells === 'function') renderShells();
        }

        if (event.data.type === "languageChanged") {
            if (event.data.translations) {
                window.translations = event.data.translations;
                window.currentLocale = event.data.locale || 'en';
                translations = window.translations;
                currentLocale = window.currentLocale;

                if (typeof translateInterface === 'function') translateInterface();
                refreshKeysModalTexts();

                if (listModeActive && allHousesData && allHousesData.length > 0) {
                    if (typeof renderManageHousesList === 'function') renderManageHousesList();
                }
            }
            if (typeof window.fetchExtendedState === "function") {
                window.fetchExtendedState(false);
            }
        }

        if (event.data.type === "housePreviewPlaceholdersSettingChanged") {
            const enabled = event.data.enabled === true;

            if (typeof window.nhSetHousePreviewPlaceholdersSetting === 'function') {
                window.nhSetHousePreviewPlaceholdersSetting(enabled, true);
            }

            $('#house-preview-placeholders-enabled').prop('checked', enabled);

            if (listModeActive && typeof renderManageHousesList === 'function') {
                renderManageHousesList();
            }
        }

        if (event.data.type === "garagesEnabledSettingChanged") {
            const enabled = event.data.enabled === true;

            if (typeof window.nhApplyGarageEnabledState === 'function') {
                window.nhApplyGarageEnabledState(enabled, { syncToggle: true });
            } else {
                window.nhGaragesEnabled = enabled;
                $('#garage-enabled').prop('checked', enabled);
            }
        }

        if (event.data.type === "openui") {
            if (event.data.status == true) {
                window.nhIsAdmin = event.data.isAdmin === true;
                if (event.data.extended) {
                    window.applyExtendedStatePayload(event.data.extended);
                }

                if (typeof window.fetchExtendedState === "function") {
                    window.fetchExtendedState(true);
                }

                window.__nhInitialSettings = event.data.settings || null;
                if (window.__nhInitialSettings && typeof window.nhSetHousePreviewPlaceholdersSetting === 'function') {
                    window.nhSetHousePreviewPlaceholdersSetting(
                        window.__nhInitialSettings.housePreviewPlaceholdersEnabled,
                        window.__nhInitialSettings.housePreviewPlaceholdersEnabledLoaded === true
                    );
                }

                if (window.__nhInitialSettings && typeof window.nhApplyGarageEnabledState === 'function') {
                    const garageEnabledFromSnapshot = (window.__nhInitialSettings.garagesEnabledLoaded === true)
                        ? (window.__nhInitialSettings.garagesEnabled === true)
                        : true;
                    window.nhApplyGarageEnabledState(garageEnabledFromSnapshot, { syncToggle: true });
                }

                if (
                    (!window.__nhInitialSettings || window.__nhInitialSettings.garagesEnabledLoaded !== true)
                    && typeof window.nhApplyGarageEnabledState === 'function'
                ) {
                    $.post('https://next_housing/getGaragesEnabled', JSON.stringify({}), function (resp) {
                        let enabled = true;
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            enabled = !!(data && (data.enabled === true || data.enabled === 1));
                        } catch (_) {
                            enabled = true;
                        }

                        window.nhApplyGarageEnabledState(enabled, { syncToggle: true });
                    });
                }
                display(true)

                let savedTab = 'edit';

                const storedTab = getFromLocalStorage('next_housing_activeTab');
                if (storedTab && ['edit', 'create', 'shells', 'settings', 'agency', 'extended'].includes(storedTab)) {
                    const tabButton = $(`.tab-btn[data-tab='${storedTab}']`);
                    if (tabButton.length > 0 && tabButton.is(':visible')) {

                        savedTab = storedTab;
                    }
                }

                isRestoringTab = true;

                if (typeof activateTab === 'function') activateTab(savedTab);

                setTimeout(function () {
                    isRestoringTab = false;
                }, 500);

                if (event.data.translations) {

                    window.translations = event.data.translations;
                    window.currentLocale = event.data.locale || 'en';
                    translations = window.translations;
                    currentLocale = window.currentLocale;
                }
                if (typeof translateInterface === 'function') {
                    translateInterface();
                }
                if (listModeActive && allHousesData.length > 0) {
                    if (typeof renderManageHousesList === 'function') renderManageHousesList();
                }

                loadCurrencySymbol();

                if (event.data.shells) {
                    currentShells = event.data.shells || [];
                    if (typeof renderShells === 'function') renderShells();
                }

                
                
                
                $.post('https://next_housing/getCustomShellsEnabled', JSON.stringify({}), function (resp) {

                    try {
                        const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                        if (data && typeof data.enabled !== 'undefined') {
                            const isEnabled = data.enabled === true || data.enabled === 1;
                            const shellsTab = $(".tab-btn[data-tab='shells']");
                            if (isEnabled) {
                                shellsTab.show();
                            } else {
                                shellsTab.hide();
                                const storedTab = getFromLocalStorage('next_housing_activeTab');
                                if (storedTab === 'shells') {

                                    if (typeof activateTab === 'function') activateTab('edit');
                                }
                            }
                        } else {
                            $(".tab-btn[data-tab='shells']").hide();
                            const storedTab = getFromLocalStorage('next_housing_activeTab');
                            if (storedTab === 'shells') {

                                if (typeof activateTab === 'function') activateTab('edit');
                            }
                        }
                    } catch (_) {
                        $(".tab-btn[data-tab='shells']").hide();
                        const storedTab = getFromLocalStorage('next_housing_activeTab');
                        if (storedTab === 'shells') {

                            if (typeof activateTab === 'function') activateTab('edit');
                        }
                    }
                });

                const currentTab = $(".tab-btn.active").data('tab');
                if (currentTab === 'edit') {
                    beginManageScan({
                        suppressLoading: true,
                        fallbackToEmpty: true
                    });
                } else {
                    finalizeManageScan();
                }

                if (event.data.isAdmin) {
                    $("#discord-admin-text").show();
                } else {
                    $("#discord-admin-text").hide();
                }
            } else {
                window.nhIsAdmin = false;
                finalizeManageScan();
                display(false)
            }
        } else if (event.data.type === "showJobInterface"
            || event.data.type === "showPapInterface"
            || event.data.type === "openGarage"
            || event.data.type === "openWardrobe")
        {
            window.nhIsAdmin = false;
            if (typeof window.fetchExtendedState === "function") {
                window.fetchExtendedState(false);
            }
        } else if (event.data.type === "builderui") {
            if (event.data.status == true) {
                window.nhIsAdmin = false;
                display(true)
                if (typeof activateTab === 'function') activateTab('create')
                if (typeof translateInterface === 'function') translateInterface();
                $("#discord-admin-text").hide();

                if (event.data.shells) {
                    currentShells = event.data.shells || [];
                    if (typeof renderShells === 'function') renderShells();
                }
            } else {
                window.nhIsAdmin = false;
                finalizeManageScan();
                display(false)
            }
        } else if (event.data.type === "infoui") {
            const incomingScanSeq = Number(event.data.scanSeq);
            if (Number.isFinite(incomingScanSeq) && window.manageScanToken && incomingScanSeq !== window.manageScanToken) {
                return;
            }

            const wasWaitingForManageScan = window.manageScanWaitingForResponse === true;
            finalizeManageScan();

            $("#container").addClass('show');
            $("#delete-btn").hide();
            const currentActiveTab = $(".tab-btn.active").data('tab');
            if (!isRestoringTab && wasWaitingForManageScan && currentActiveTab !== 'edit') {
                if (typeof activateTab === 'function') activateTab('edit');
            }

            const activeTabAfterSync = $(".tab-btn.active").data('tab');
            if (activeTabAfterSync && activeTabAfterSync !== 'edit') {
                return;
            }

            if (typeof translateInterface === 'function') translateInterface();


            if (event.data.status == true) {
                showManageInfoState();

                $("#houseid").text(event.data.data[0]);
                $("#bname").text(event.data.data[2]);
                const ownerName = event.data.data[4];
                const ownerIdentifier = event.data.data[3];
                const ownerText = (ownerName && ownerName.trim() !== '') ? ownerName : ((ownerIdentifier && ownerIdentifier.trim() !== '') ? (translations.no_data) : (translations.vacant));
                $("#oname").text(ownerText);

                $("#price_display").text(event.data.data[7] ? formatPrice(event.data.data[7]) : '-');
                const isLocked = event.data.data[6] === true;
                $("#lock").text(isLocked ? (translations.closed) : (translations.open));
                window.updateManageLockIcon(isLocked);
                window.currentInterior = event.data.data[5];
                window.initialInterior = event.data.data[5];
                $('#interior-change').val(window.currentInterior);
                const interiorName = (typeof getInteriorName === 'function') ? getInteriorName(window.currentInterior) : window.currentInterior;
                $("#interiornow").text(interiorName);

                if (event.data.shells) {
                    currentShells = event.data.shells || [];
                    if (typeof renderShells === 'function') renderShells();
                }
                if (event.data.entranceCoords) {

                    $("#entrancex").val(event.data.entranceCoords.x ? parseFloat(event.data.entranceCoords.x).toFixed(2) : '');
                    $("#entrancey").val(event.data.entranceCoords.y ? parseFloat(event.data.entranceCoords.y).toFixed(2) : '');
                    $("#entrancez").val(event.data.entranceCoords.z ? parseFloat(event.data.entranceCoords.z).toFixed(2) : '');
                } else {
                    $("#entrancex").val('');
                    $("#entrancey").val('');
                    $("#entrancez").val('');
                }
                if (event.data.garageCoords) {

                    $("#garagex-manage").val(event.data.garageCoords.x ? parseFloat(event.data.garageCoords.x).toFixed(2) : '');
                    $("#garagey-manage").val(event.data.garageCoords.y ? parseFloat(event.data.garageCoords.y).toFixed(2) : '');
                    $("#garagez-manage").val(event.data.garageCoords.z ? parseFloat(event.data.garageCoords.z).toFixed(2) : '');
                    $("#garageh-manage").val(event.data.garageCoords.h ? parseFloat(event.data.garageCoords.h).toFixed(2) : '');
                } else {
                    $("#garagex-manage").val('');
                    $("#garagey-manage").val('');
                    $("#garagez-manage").val('');
                    $("#garageh-manage").val('');
                }
                window.initialValues = {
                    interior: window.currentInterior,
                    entranceX: $("#entrancex").val(),
                    entranceY: $("#entrancey").val(),
                    entranceZ: $("#entrancez").val(),
                    garageX: $("#garagex-manage").val(),
                    garageY: $("#garagey-manage").val(),
                    garageZ: $("#garagez-manage").val(),
                    garageH: $("#garageh-manage").val()
                };


                if (typeof window.triggerAutoSaveManage === 'function') {
                    window.triggerAutoSaveManage();
                }
            } else {
                showManageEmptyState();
            }
        } else if (event.data.type === "close") {
            finalizeManageScan();
            display(false);
        } else if (event.data.type === "restoreMenu") {
            restoreMenuState();
        } else if (event.data.type === "coords") {
            if (event.data.status == "house") {
                $('#housex').val(event.data.x.toFixed(2));
                $('#housey').val(event.data.y.toFixed(2));
                $('#housez').val(event.data.z.toFixed(2));
            } else if (event.data.status == "garage") {
                if (window.nhGaragesEnabled === true) {
                    $('#garagex').val(event.data.x.toFixed(2));
                    $('#garagey').val(event.data.y.toFixed(2));
                    $('#garagez').val(event.data.z.toFixed(2));
                    $('#garageh').val(event.data.h.toFixed(2));
                }
            } else if (event.data.status == "entrance") {
                $('#entrancex').val(event.data.x.toFixed(2)).trigger('change');
                $('#entrancey').val(event.data.y.toFixed(2)).trigger('change');
                $('#entrancez').val(event.data.z.toFixed(2)).trigger('change');
            } else if (event.data.status == "garage-manage") {
                if (window.nhGaragesEnabled === true) {
                    $('#garagex-manage').val(event.data.x.toFixed(2)).trigger('change');
                    $('#garagey-manage').val(event.data.y.toFixed(2)).trigger('change');
                    $('#garagez-manage').val(event.data.z.toFixed(2)).trigger('change');
                    $('#garageh-manage').val(event.data.h.toFixed(2)).trigger('change');
                }
            } else if (event.data.status == "stash-settings") {
                $('#stash-global-x').val(event.data.x.toFixed(2));
                $('#stash-global-y').val(event.data.y.toFixed(2));
                $('#stash-global-z').val(event.data.z.toFixed(2));
                if (typeof window.nhSaveSelectedStashInteriorCoords === 'function') {
                    window.nhSaveSelectedStashInteriorCoords();
                }
            } else if (event.data.status == "wardrobe-settings") {
                $('#wardrobe-global-x').val(event.data.x.toFixed(2));
                $('#wardrobe-global-y').val(event.data.y.toFixed(2));
                $('#wardrobe-global-z').val(event.data.z.toFixed(2));
                if (typeof window.nhSaveSelectedWardrobeInteriorCoords === 'function') {
                    window.nhSaveSelectedWardrobeInteriorCoords();
                }
            } else if (event.data.status == "shell-base") {
                $('#shell-base-x').val(event.data.x.toFixed(2));
                $('#shell-base-y').val(event.data.y.toFixed(2));
                $('#shell-base-z').val(event.data.z.toFixed(2));
            } else if (event.data.status == "shell-entry-edit") {
                $('#shell-entry-x-edit').val(event.data.x.toFixed(2));
                $('#shell-entry-y-edit').val(event.data.y.toFixed(2));
                $('#shell-entry-z-edit').val(event.data.z.toFixed(2));
            } else if (event.data.status == "shell-stash-edit") {
                $('#shell-stash-x-edit').val(event.data.x.toFixed(2));
                $('#shell-stash-y-edit').val(event.data.y.toFixed(2));
                $('#shell-stash-z-edit').val(event.data.z.toFixed(2));
            }
        } else if (event.data.type === "lockupdate") {
            const isLocked = event.data.status === true;
            $("#lock").text(isLocked ? (translations.closed) : (translations.open));
            window.updateManageLockIcon(isLocked);
        } else if (event.data.type === "showShellTeleportWarning") {
            $('#shell-teleport-warning').show();
        } else if (event.data.type === "hideShellTeleportWarning") {
            $('#shell-teleport-warning').hide();
        }
    })

    $(document).on('click', '#shell-return-link', function (e) {
        e.preventDefault();
        $.post('https://next_housing/returnFromShellTeleport', JSON.stringify({}));
    });


    $('#container').on('click', '#delete-btn', function () {
        $("#confirm").show();
    });

    $('#info-container').on('click', '#close', function () {
        $.post('http://next_housing/exit', JSON.stringify({}));
        display(false)
    });


    $('#confirm').on('click', '#close', function () {
        $("#confirm").hide();
    });

    window.CloseMenu = function () {
        $.post('http://next_housing/exit', JSON.stringify({}));
        display(false);
    };

    if (typeof StatusChange === 'function') StatusChange();
    if (typeof activateTab === 'function') activateTab('edit');

    $(".tab-btn[data-tab='shells']").hide();

    $('#list-mode-btn').hide();

    $('.sidebar-item').on('click', function () {
        const panel = $(this).closest('.tab-panel');

        if (panel.attr('id') === 'tab-shells') {
            return;
        }

        const section = $(this).data('section');
        panel.find('.sidebar-item').removeClass('active');
        panel.find('.sidebar-section, .content-section').removeClass('active').css('display', '');

        $(this).addClass('active');
        panel.find('#section-' + section).addClass('active');

        const tabId = panel.attr('id');
        const sectionStorageMap = {
            'tab-settings': 'next_housing_activeSection_settings',
            'tab-agency': 'next_housing_activeSection_agency'
        };

        if (sectionStorageMap[tabId]) {
            saveToLocalStorage(sectionStorageMap[tabId], section);
        }

        if (panel.attr('id') === 'tab-settings') {

            if (section === 'settings-wardrobe') {
                if (typeof initializeSettingsWardrobe === 'function') initializeSettingsWardrobe();
            }
            if (section === 'settings-burglary') {
                if (typeof initializeSettingsBurglary === 'function') initializeSettingsBurglary();
            }

            if (typeof translateInterface === 'function') {
                translateInterface();
            }
        }

        if (panel.attr('id') === 'tab-agency') {

            if (section === 'agency-transaction') {
                setTimeout(function () {
                    $.post('http://next_housing/getCurrencySymbol', JSON.stringify({}), function (resp) {
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && data.symbol) {
                                $('#currency-symbol').val(data.symbol);
                            }
                        } catch (_) { }
                    });
                    $.post('https://next_housing/getRentPaymentMode', JSON.stringify({}), function (resp) {
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && data.mode) {
                                $('#rent-payment-mode').val(data.mode);
                            }
                        } catch (_) { }
                    });
                    $.post('https://next_housing/getRentPaymentInterval', JSON.stringify({}), function (resp) {
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && data.interval) {
                                $('#rent-payment-interval').val(data.interval);
                            }
                        } catch (_) { }
                    });
                }, 50);
            }
        }
    });

    function nhDebounce(func, wait) {
        let timeout;
        return function (...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }

    function saveMarkerSettings(changedFieldId) {
        const payload = {};
        const includeAll = !changedFieldId;

        if (includeAll || changedFieldId === 'sprites-enabled') {
            payload.spritesEnabled = $('#sprites-enabled').is(':checked');
        }

        if (includeAll || changedFieldId === 'blips-enabled') {
            payload.blipsEnabled = $('#blips-enabled').is(':checked');
        }

        if (includeAll || changedFieldId === 'sprite-height-offset') {
            const offset = parseFloat($('#sprite-height-offset').val());
            if (Number.isFinite(offset)) {
                payload.spriteHeightOffset = offset;
            }
        }

        if (includeAll || changedFieldId === 'entrance-display-distance') {
            const distance = parseFloat($('#entrance-display-distance').val());
            if (Number.isFinite(distance)) {
                payload.entranceDisplayDistance = distance;
            }
        }

        if (includeAll || changedFieldId === 'chest-display-distance') {
            const distance = parseFloat($('#chest-display-distance').val());
            if (Number.isFinite(distance)) {
                payload.chestDisplayDistance = distance;
            }
        }

        if (Object.keys(payload).length === 0) {
            return false;
        }

        $.post('https://next_housing/saveMarkerSettings', JSON.stringify(payload));
        return true;
    }

    function saveSingleSetting(fieldId) {
        switch (fieldId) {
            case 'language-select':
                $.post('https://next_housing/saveLanguage', JSON.stringify({ locale: $('#language-select').val() }));
                break;
            case 'sprites-enabled':
            case 'blips-enabled':
            case 'sprite-height-offset':
            case 'entrance-display-distance':
            case 'chest-display-distance':
                saveMarkerSettings(fieldId);
                break;
            case 'house-preview-placeholders-enabled':
                (function () {
                    const enabled = $('#house-preview-placeholders-enabled').is(':checked');
                    $.post('https://next_housing/saveHousePreviewPlaceholdersEnabled', JSON.stringify({ enabled: enabled }), function (resp) {
                        let saveSucceeded = true;

                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && Object.prototype.hasOwnProperty.call(data, 'success')) {
                                saveSucceeded = data.success === true;
                            }
                        } catch (_) {
                        }

                        if (!saveSucceeded) {
                            return;
                        }

                        if (typeof window.nhSetHousePreviewPlaceholdersSetting === 'function') {
                            window.nhSetHousePreviewPlaceholdersSetting(enabled, true);
                        }

                        if (typeof listModeActive !== 'undefined' && listModeActive && typeof renderManageHousesList === 'function') {
                            renderManageHousesList();
                        }
                    });
                })();
                break;
            case 'garage-enabled':
                (function () {
                    const enabled = $('#garage-enabled').is(':checked');
                    $.post('https://next_housing/saveGaragesEnabled', JSON.stringify({ enabled: enabled }), function (resp) {
                        let saveSucceeded = true;

                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && Object.prototype.hasOwnProperty.call(data, 'success')) {
                                saveSucceeded = data.success === true;
                            }
                        } catch (_) {
                        }

                        if (!saveSucceeded) {
                            return;
                        }

                        if (typeof window.nhApplyGarageEnabledState === 'function') {
                            window.nhApplyGarageEnabledState(enabled, { syncToggle: true });
                        } else {
                            window.nhGaragesEnabled = enabled;
                            $('#garage-enabled').prop('checked', enabled);
                        }
                    });
                })();
                break;
            case 'garage-show-all-vehicles':
                if (window.nhGarageShowAllVehiclesAvailable === false) {
                    break;
                }
                $.post('https://next_housing/saveGarageShowAllVehicles', JSON.stringify({ enabled: $('#garage-show-all-vehicles').is(':checked') }));
                break;
            case 'stash-enabled':
                $.post('https://next_housing/saveStashesEnabled', JSON.stringify({ enabled: $('#stash-enabled').is(':checked') }));
                break;
            case 'stash-system':
                $.post('https://next_housing/saveStashSystem', JSON.stringify({ system: $('#stash-system').val() }));
                break;
            case 'stash-custom-coords-enabled':
                (function () {
                    const enabled = $('#stash-custom-coords-enabled').is(':checked');
                    $.post('https://next_housing/saveStashCustomCoordsEnabled', JSON.stringify({ enabled: enabled }), function (resp) {
                        let saveSucceeded = true;

                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && Object.prototype.hasOwnProperty.call(data, 'success')) {
                                saveSucceeded = data.success === true;
                            }
                        } catch (_) {
                        }

                        if (!saveSucceeded) {
                            return;
                        }

                        window.nhStashCustomCoordsEnabled = enabled;
                        if (typeof window.updateStashGlobalCoordsVisibility === 'function') {
                            window.updateStashGlobalCoordsVisibility();
                        }
                    });
                })();
                break;
            case 'stash-global-interior-select':
                if (typeof window.nhLoadSelectedStashInteriorCoords === 'function') {
                    window.nhLoadSelectedStashInteriorCoords();
                }
                break;
            case 'stash-global-x':
            case 'stash-global-y':
            case 'stash-global-z':
                if (typeof window.nhSaveSelectedStashInteriorCoords === 'function') {
                    window.nhSaveSelectedStashInteriorCoords();
                }
                break;
            case 'wardrobe-enabled':
                $.post('https://next_housing/saveWardrobeEnabled', JSON.stringify({ enabled: $('#wardrobe-enabled').is(':checked') }));
                break;
            case 'wardrobe-system':
                $.post('https://next_housing/saveWardrobeSystem', JSON.stringify({ system: $('#wardrobe-system').val() }));
                break;
            case 'wardrobe-custom-coords-enabled':
                (function () {
                    const enabled = $('#wardrobe-custom-coords-enabled').is(':checked');
                    $.post('https://next_housing/saveWardrobeCustomCoordsEnabled', JSON.stringify({ enabled: enabled }), function (resp) {
                        let saveSucceeded = true;

                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && Object.prototype.hasOwnProperty.call(data, 'success')) {
                                saveSucceeded = data.success === true;
                            }
                        } catch (_) {
                        }

                        if (!saveSucceeded) {
                            return;
                        }

                        window.nhWardrobeCustomCoordsEnabled = enabled;
                        if (typeof window.updateWardrobeGlobalCoordsVisibility === 'function') {
                            window.updateWardrobeGlobalCoordsVisibility();
                        }
                    });
                })();
                break;
            case 'wardrobe-global-interior-select':
                if (typeof window.nhLoadSelectedWardrobeInteriorCoords === 'function') {
                    window.nhLoadSelectedWardrobeInteriorCoords();
                }
                break;
            case 'wardrobe-global-x':
            case 'wardrobe-global-y':
            case 'wardrobe-global-z':
                if (typeof window.nhSaveSelectedWardrobeInteriorCoords === 'function') {
                    window.nhSaveSelectedWardrobeInteriorCoords();
                }
                break;
            case 'custom-shells-enabled':
                $.post('https://next_housing/saveCustomShellsEnabled', JSON.stringify({ enabled: $('#custom-shells-enabled').is(':checked') }), function () {
                    updateCustomShellsTabVisibility();
                });
                break;
            case 'burglary-enabled':
                $.post('https://next_housing/saveBurglaryEnabled', JSON.stringify({ enabled: $('#burglary-enabled').is(':checked') }));
                break;
            default:
                break;
        }
    }

    function autoSaveSettings(changedFieldId) {
        if (typeof changedFieldId === 'string' && changedFieldId.length > 0) {
            if (saveMarkerSettings(changedFieldId)) {
                return;
            }
            saveSingleSetting(changedFieldId);
            return;
        }

        
        saveSingleSetting('language-select');
        saveMarkerSettings();
        saveSingleSetting('house-preview-placeholders-enabled');
        saveSingleSetting('garage-enabled');
        saveSingleSetting('garage-show-all-vehicles');
        saveSingleSetting('stash-enabled');
        saveSingleSetting('stash-system');
        saveSingleSetting('stash-custom-coords-enabled');
        saveSingleSetting('wardrobe-enabled');
        saveSingleSetting('wardrobe-system');
        saveSingleSetting('wardrobe-custom-coords-enabled');
        saveSingleSetting('custom-shells-enabled');
        saveSingleSetting('burglary-enabled');
    }

    function autoSaveAgency() {
        const jobEnabled = $('#job-enabled').is(':checked');
        const jobCommand = $('#job-command').val().trim() || 'realestate';
        const jobName = $('#job-name').val().trim() || 'realestate';
        const directPurchaseEnabled = $('#direct-purchase-enabled').is(':checked');
        const treasuryWithdrawMinGrade = parseInt($('#treasury-withdraw-min-grade').val()) || 0;
        const symbolVal = $('#currency-symbol').val().trim() || '$';
        const rentPaymentMode = $('#rent-payment-mode').val() || 'hours';
        const rentPaymentInterval = parseInt($('#rent-payment-interval').val()) || 1;
        const papEnabled = $('#pap-enabled').is(':checked');
        const papAllowRent = $('#pap-allow-rent').is(':checked');
        const papCommand = $('#pap-command').val().trim() || 'classifieds';
        const papListingFee = parseInt($('#pap-listing-fee').val()) || 0;
        const papMaxListings = parseInt($('#pap-max-listings').val()) || 3;
        const papListingDuration = parseInt($('#pap-listing-duration').val()) || 14;

        $.post('https://next_housing/saveJobEnabled', JSON.stringify({ enabled: jobEnabled }));
        $.post('https://next_housing/saveJobCommand', JSON.stringify({ command: jobCommand }));
        $.post('https://next_housing/saveJobName', JSON.stringify({ jobName: jobName }));
        $.post('https://next_housing/saveDirectPurchaseEnabled', JSON.stringify({ enabled: directPurchaseEnabled }));
        $.post('https://next_housing/saveTreasuryWithdrawMinGrade', JSON.stringify({ minGrade: treasuryWithdrawMinGrade }));
        $.post('https://next_housing/saveCurrencySymbol', JSON.stringify({ symbol: symbolVal }), function () {
            loadCurrencySymbol();
        });
        $.post('https://next_housing/saveRentPaymentMode', JSON.stringify({ mode: rentPaymentMode }));
        $.post('https://next_housing/saveRentPaymentInterval', JSON.stringify({ interval: rentPaymentInterval }));
        $.post('https://next_housing/savePapSettings', JSON.stringify({
            enabled: papEnabled,
            allowRent: papAllowRent,
            command: papCommand,
            listingFee: papListingFee,
            maxListings: papMaxListings,
            listingDuration: papListingDuration
        }));
    }

    function autoSaveManage() {
        const houseid = $('#houseid').text();
        if (!houseid || houseid === '-') return;

        const currentInterior = $('#interior-change').val();
        if (window.initialValues && String(currentInterior) !== String(window.initialValues.interior)) {
            $.post('https://next_housing/interior', JSON.stringify({
                id: houseid,
                interior: currentInterior
            }), function () {
                if (window.initialValues) {
                    window.initialValues.interior = currentInterior;
                }
                window.initialInterior = currentInterior;
                window.currentInterior = currentInterior;
                const interiorName = getInteriorName(currentInterior);
                $("#interiornow").text(interiorName);
            });
        }

        const entranceX = $('#entrancex').val();
        const entranceY = $('#entrancey').val();
        const entranceZ = $('#entrancez').val();
        if (window.initialValues &&
            (entranceX !== window.initialValues.entranceX ||
                entranceY !== window.initialValues.entranceY ||
                entranceZ !== window.initialValues.entranceZ)) {

            if (entranceX && entranceY && entranceZ && entranceX.trim() !== '' && entranceY.trim() !== '' && entranceZ.trim() !== '') {
                $.post('https://next_housing/updateEntranceCoords', JSON.stringify({
                    id: houseid,
                    x: parseFloat(entranceX),
                    y: parseFloat(entranceY),
                    z: parseFloat(entranceZ)
                }), function (resp) {
                    try {
                        const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                        if (data && data.success && window.initialValues) {
                            window.initialValues.entranceX = parseFloat(entranceX).toFixed(2);
                            window.initialValues.entranceY = parseFloat(entranceY).toFixed(2);
                            window.initialValues.entranceZ = parseFloat(entranceZ).toFixed(2);
                        }
                    } catch (_) { }
                });
            }
        }

        if (window.nhGaragesEnabled === true) {
            const garageX = $('#garagex-manage').val();
            const garageY = $('#garagey-manage').val();
            const garageZ = $('#garagez-manage').val();
            const garageH = $('#garageh-manage').val();
            if (window.initialValues &&
                (garageX !== window.initialValues.garageX ||
                    garageY !== window.initialValues.garageY ||
                    garageZ !== window.initialValues.garageZ ||
                    garageH !== window.initialValues.garageH)) {

                if (garageX && garageY && garageZ && garageX.trim() !== '' && garageY.trim() !== '' && garageZ.trim() !== '') {
                    $.post('https://next_housing/updateGarageCoords', JSON.stringify({
                        id: houseid,
                        x: parseFloat(garageX),
                        y: parseFloat(garageY),
                        z: parseFloat(garageZ),
                        h: garageH && garageH.trim() !== '' ? parseFloat(garageH) : 0.0
                    }), function (resp) {
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && data.success && window.initialValues) {
                                window.initialValues.garageX = parseFloat(garageX).toFixed(2);
                                window.initialValues.garageY = parseFloat(garageY).toFixed(2);
                                window.initialValues.garageZ = parseFloat(garageZ).toFixed(2);
                                window.initialValues.garageH = garageH && garageH.trim() !== '' ? parseFloat(garageH).toFixed(2) : '';
                            }
                        } catch (_) { }
                    });
                }
            }
        }

    }

    const triggerAutoSaveSettings = nhDebounce(autoSaveSettings, 500);
    const triggerAutoSaveAgency = nhDebounce(autoSaveAgency, 500);
    const triggerAutoSaveManage = nhDebounce(autoSaveManage, 500);

    window.autoSaveSettings = autoSaveSettings;
    window.autoSaveAgency = autoSaveAgency;
    window.autoSaveManage = autoSaveManage;
    window.triggerAutoSaveSettings = triggerAutoSaveSettings;
    window.triggerAutoSaveAgency = triggerAutoSaveAgency;
    window.triggerAutoSaveManage = triggerAutoSaveManage;

    let settingsAutoSaveAttached = false;
    function attachSettingsAutoSave() {
        if (settingsAutoSaveAttached) return;
        $('#tab-settings input, #tab-settings select').on('change input', function (event) {
            const fieldId = this && this.id ? this.id : null;
            if (!fieldId) return;

            const isUserEvent = !!(event && event.originalEvent);

            if (window.__nhSettingsHydrating === true) {
                if (!isUserEvent) {
                    return;
                }

                
                window.__nhSettingsHydrating = false;
                if (window.__nhSettingsHydrationTimer) {
                    clearTimeout(window.__nhSettingsHydrationTimer);
                    window.__nhSettingsHydrationTimer = null;
                }
            }

            if (!isUserEvent) {
                return;
            }

            if (typeof window.markSettingsFieldTouched === 'function') {
                window.markSettingsFieldTouched(fieldId);
            }

            const isSliderField = fieldId === 'sprite-height-offset'
                || fieldId === 'entrance-display-distance'
                || fieldId === 'chest-display-distance';

            if (event && event.type === 'input' && !isSliderField) {
                return;
            }

            triggerAutoSaveSettings(fieldId);
        });
        settingsAutoSaveAttached = true;
    }
    window.attachSettingsAutoSave = attachSettingsAutoSave;

    let agencyAutoSaveAttached = false;
    function attachAgencyAutoSave() {
        if (agencyAutoSaveAttached) return;
        $('#tab-agency input, #tab-agency select').on('change input', function () {
            triggerAutoSaveAgency();
        });
        agencyAutoSaveAttached = true;
    }
    window.attachAgencyAutoSave = attachAgencyAutoSave;

    let manageAutoSaveAttached = false;
    function attachManageAutoSave() {
        if (manageAutoSaveAttached) return;
        $('#tab-edit input, #tab-edit select').on('change input', function () {
            triggerAutoSaveManage();
        });
        manageAutoSaveAttached = true;
    }
    window.attachManageAutoSave = attachManageAutoSave;

    $(document).on('click', '.discord-link', function (e) {
        e.preventDefault();
        const url = $(this).attr('href');
        try {
            if (typeof window.invokeNative === 'function') {
                window.invokeNative('openUrl', url);
            } else {
                window.open(url, '_blank');
            }
        } catch (_) {
            try { window.open(url, '_blank'); } catch (__) { }
        }
        $.post('https://next_housing/notifyDiscordOpened', JSON.stringify({
            url: url
        }));
    });
});

let currentHelpMessages = null;

function showHelpMessage(messages) {
    const messagesKey = JSON.stringify(messages);
    if (currentHelpMessages === messagesKey) {
        return;
    }
    currentHelpMessages = messagesKey;
    const container = $('#help-messages');
    container.empty();
    if (!messages || messages.length === 0) return;

    const normalMessages = [];
    const fullWidthMessages = [];

    messages.forEach(function (msg) {
        if (msg.fullWidth) {
            fullWidthMessages.push(msg);
        } else {
            normalMessages.push(msg);
        }
    });

    if (normalMessages.length > 0) {
        const rowDiv = $('<div class="help-messages-row">');
        normalMessages.forEach(function (msg) {
            const messageDiv = $('<div class="help-message">');
            if (msg.icon) {
                messageDiv.append(`<div class="help-icon">${msg.icon}</div>`);
            }
            let textContent = '';
            if (msg.key) {
                textContent = `<span class="help-key">${msg.key}</span> ${msg.text}`;
            } else {
                textContent = msg.text;
            }
            messageDiv.append(`<div class="help-text">${textContent}</div>`);
            rowDiv.append(messageDiv);
        });
        container.append(rowDiv);

        requestAnimationFrame(function () {
            rowDiv[0].offsetHeight;

            const rowWidth = rowDiv.outerWidth(false);

            fullWidthMessages.forEach(function (msg) {
                const messageDiv = $('<div class="help-message help-message-fullwidth">');
                messageDiv.css('width', rowWidth + 'px');
                messageDiv.css('min-width', rowWidth + 'px');
                messageDiv.css('max-width', rowWidth + 'px');
                messageDiv.css('flex-shrink', '0');
                messageDiv.css('flex-grow', '0');
                let textContent = msg.text || '';
                messageDiv.append(`<div class="help-text help-text-info">${textContent}</div>`);
                container.append(messageDiv);
            });
        });
    } else {
        fullWidthMessages.forEach(function (msg) {
            const messageDiv = $('<div class="help-message help-message-fullwidth">');
            let textContent = msg.text || '';
            messageDiv.append(`<div class="help-text help-text-info">${textContent}</div>`);
            container.append(messageDiv);
        });
    }
}

function hideHelpMessages() {
    const messages = $('.help-message');
    if (messages.length > 0) {
        messages.animate({ opacity: 0, marginBottom: '-20px' }, 250, function () {
            $(this).remove();
        });
    }
    currentHelpMessages = null;
}

$(document).ready(function () {
    $('#manage-houses-loading').hide();
    $('#manage-houses-empty').hide();
    $('#entrancex, #entrancey, #entrancez, #garagex-manage, #garagey-manage, #garagez-manage, #garageh-manage').on('input change', function () {
        if (typeof window.triggerAutoSaveManage === 'function') {
            window.triggerAutoSaveManage();
        }
    });

    $('#interior-change').on('change', function () {
        if (typeof window.triggerAutoSaveManage === 'function') {
            window.triggerAutoSaveManage();
        }
    });
});

let listModeActive = false;
let allHousesData = [];

function getTranslation(key, fallback) {
    if (!window.translations) return fallback || '';
    return window.translations[key] || fallback || '';
}

function getTranslationWithFallbacks(keys, fallback) {
    if (!window.translations) return fallback || '';
    for (let i = 0; i < keys.length; i++) {
        if (window.translations[keys[i]]) {
            return window.translations[keys[i]];
        }
    }
    return fallback || '';
}



