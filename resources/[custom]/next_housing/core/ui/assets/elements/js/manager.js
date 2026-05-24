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
let manageHousesRequestToken = 0;
let manageHousesLoadingInProgress = false;
let manageHousesActiveRequest = null;

function saveToLocalStorage(key, value) {
    try {
        localStorage.setItem(key, value);
    } catch (e) {
    }
}

function getFromLocalStorage(key) {
    try {
        return localStorage.getItem(key);
    } catch (e) {
        return null;
    }
}

function restoreSectionInPanel(panel, storageKey, fallbackCallback) {
    panel.find('.sidebar-item').removeClass('active');
    panel.find('.sidebar-section, .content-section').removeClass('active').css('display', '');

    const savedSection = getFromLocalStorage(storageKey);

    if (savedSection && panel.find(`#section-${savedSection}`).length > 0) {
        panel.find(`#section-${savedSection}`).addClass('active');
        panel.find(`.sidebar-item[data-section="${savedSection}"]`).addClass('active');
        return true;
    } else {
        if (fallbackCallback) {
            fallbackCallback(panel);
        }
        return false;
    }
}

function activateFirstSection(panel) {
    const firstItem = panel.find('.sidebar-item').first();
    if (firstItem.length > 0) {
        firstItem.addClass('active');
        const firstSectionId = firstItem.data('section');
        if (firstSectionId) {
            const mappedSection = panel.find(`#section-${firstSectionId}`);
            if (mappedSection.length > 0) {
                mappedSection.addClass('active');
                return;
            }
        }
    }
    const firstSection = panel.find('.sidebar-section, .content-section').first();
    if (firstSection.length > 0) {
        firstSection.addClass('active');
    }
}

function activateSection(sectionId) {
    const section = $('#section-' + sectionId);
    if (!section.length) return;

    const panel = section.closest('.tab-panel');
    panel.find('.sidebar-item').removeClass('active');
    panel.find('.sidebar-section, .content-section').removeClass('active').css('display', '');

    panel.find(`.sidebar-item[data-section="${sectionId}"]`).addClass('active');
    section.addClass('active');
}



function activateTab(name) {
    const requestedTab = (name || 'edit').toString();
    const extendedTab = $(".tab-btn[data-tab='extended']");
    const extendedVisible = extendedTab.length > 0 && extendedTab.is(':visible');

    if (requestedTab === 'extended' && !extendedVisible) {
        name = 'edit';
    } else {
        name = requestedTab;
    }

    $(".tab-btn").removeClass('active');
    $(".tab-panel").removeClass('active');

    saveToLocalStorage('next_housing_activeTab', name);

    if (name === 'edit') {
        $('#list-mode-btn').show();
    } else {
        $('#list-mode-btn').hide();
    }

    if (name === 'edit') {
        $(".tab-btn[data-tab='edit']").addClass('active');
        $("#tab-edit").addClass('active');
        if (typeof window.nhApplyGarageEnabledState === 'function') {
            setTimeout(function () {
                window.nhApplyGarageEnabledState(window.nhGaragesEnabled === true, { syncToggle: false });
            }, 0);
        }
        setTimeout(function () {
            if (typeof window.attachManageAutoSave === 'function') {
                window.attachManageAutoSave();
            }
        }, 100);
    } else if (name === 'create') {
        $(".tab-btn[data-tab='create']").addClass('active');
        $("#tab-create").addClass('active');
        $("#delete-btn").hide();
        initializeSidebar();
    } else if (name === 'shells') {
        $(".tab-btn[data-tab='shells']").addClass('active');
        $("#tab-shells").addClass('active');
        initializeShellsSidebar();
    } else if (name === 'settings') {
        if (typeof window.resetSettingsInitState === 'function') {
            window.resetSettingsInitState();
        } else {
            window.__nhSettingsInitToken = (window.__nhSettingsInitToken || 0) + 1;
            window.__nhSettingsUserTouched = {};
        }

        if (typeof window.startSettingsHydration === 'function') {
            window.startSettingsHydration(2500);
        } else {
            window.__nhSettingsHydrating = true;
            setTimeout(function () {
                window.__nhSettingsHydrating = false;
            }, 2500);
        }

        $(".tab-btn[data-tab='settings']").addClass('active');
        $("#tab-settings").addClass('active');
        initializeSettingsSidebar();
        initializeSettingsLanguages();
        initializeSettingsMarkers();
        initializeSettingsHousePreviews();
        initializeSettingsGarage();
        initializeSettingsStash();
        initializeSettingsWardrobe();
        initializeSettingsBeta();
        initializeSettingsBurglary();
        if (typeof translateInterface === 'function') {
            translateInterface();
        }
        setTimeout(function () {
            if (typeof window.attachSettingsAutoSave === 'function') {
                window.attachSettingsAutoSave();
            }
        }, 100);
    } else if (name === 'agency') {
        $(".tab-btn[data-tab='agency']").addClass('active');
        $("#tab-agency").addClass('active');
        initializeAgencySidebar();
        initializeAgencySettings();
        if (typeof translateInterface === 'function') {
            translateInterface();
        }
        loadCurrencySymbol();
        setTimeout(function () {
            if (typeof window.attachAgencyAutoSave === 'function') {
                window.attachAgencyAutoSave();
            }
        }, 100);
    } else if (name === 'extended') {
        $(".tab-btn[data-tab='extended']").addClass('active');
        $("#tab-extended").addClass('active');
        initializeExtendedSettings();
    }
}



function initializeSidebar() {
    const panel = $('#tab-create');
    restoreSectionInPanel(panel, 'next_housing_activeSection_create', activateFirstSection);
}

function initializeShellsSidebar() {
    const panel = $('#tab-shells');
    const savedSection = getFromLocalStorage('next_housing_activeSection_shells');

    panel.find('.sidebar-item').removeClass('active');
    panel.find('.content-section').removeClass('active').css('display', '');

    if (savedSection && panel.find(`#section-${savedSection}`).length > 0) {
        const sectionToRestore = (savedSection === 'shells-edit' && !selectedShellInterior)
            ? 'shells-list'
            : savedSection;
        activateSection(sectionToRestore);
    } else {
        activateFirstSection(panel);
    }
}

function initializeAgencySidebar() {
    const panel = $('#tab-agency');
    restoreSectionInPanel(panel, 'next_housing_activeSection_agency', activateFirstSection);
}

function initializeSettingsSidebar() {
    const panel = $('#tab-settings');
    restoreSectionInPanel(panel, 'next_housing_activeSection_settings', activateFirstSection);
}

function getExtendedTranslation(key, fallback) {
    if (window.translations && window.translations[key]) {
        return window.translations[key];
    }
    return fallback || '';
}

const EXTENDED_MENU_CONTEXTS = ['nh', 'agency', 'pap', 'garage', 'wardrobe'];
const EXTENDED_MENU_INPUTS = {
    nh: '#extended-script-title-nh',
    agency: '#extended-script-title-agency',
    pap: '#extended-script-title-pap',
    garage: '#extended-script-title-garage',
    wardrobe: '#extended-script-title-wardrobe'
};
const EXTENDED_DEFAULT_LOGO_SOURCE = 'https://www.junnho.com/assets/images/logoBlanc.png';
const EXTENDED_MAX_LOGO_SOURCE_LENGTH = 450000;

function normalizeExtendedBool(value, fallback) {
    if (value === undefined || value === null) return fallback === true;
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value === 1;
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === '1' || normalized === 'true' || normalized === 'yes' || normalized === 'on') return true;
        if (normalized === '0' || normalized === 'false' || normalized === 'no' || normalized === 'off') return false;
    }
    return fallback === true;
}

function normalizeExtendedLogoSource(value, fallback) {
    const fallbackSource = (typeof fallback === 'string' && fallback.trim() !== '')
        ? fallback.trim()
        : EXTENDED_DEFAULT_LOGO_SOURCE;
    if (typeof value !== 'string') {
        return fallbackSource;
    }

    const cleaned = value
        .replace(/[\u0000-\u001F\u007F]/g, '')
        .trim();
    if (cleaned === '' || cleaned.length > EXTENDED_MAX_LOGO_SOURCE_LENGTH) {
        return fallbackSource;
    }

    const lowered = cleaned.toLowerCase();
    if (lowered.startsWith('http://') || lowered.startsWith('https://')) {
        return cleaned;
    }

    if (/^data:image\/[a-z0-9.+-]+;base64,[a-z0-9+/=]+$/i.test(cleaned)) {
        return cleaned;
    }

    return fallbackSource;
}

function isExtendedLogoDataUri(value) {
    return typeof value === 'string' && /^data:image\//i.test(value);
}

function setExtendedLogoPreview(source, isEnabled) {
    const preview = $('#extended-logo-preview');
    if (!preview.length) return;

    if (isEnabled !== true) {
        preview.attr('src', '');
        preview.hide();
        return;
    }

    const resolved = normalizeExtendedLogoSource(source, EXTENDED_DEFAULT_LOGO_SOURCE);
    preview.attr('src', resolved);
    preview.show();
}

function applyExtendedLogoSourceToInputs(source) {
    const resolved = normalizeExtendedLogoSource(source, EXTENDED_DEFAULT_LOGO_SOURCE);
    const logoUrlInput = $('#extended-logo-url');
    const logoDataInput = $('#extended-logo-data');

    if (isExtendedLogoDataUri(resolved)) {
        logoDataInput.val(resolved);
        logoUrlInput.val('');
    } else if (resolved === EXTENDED_DEFAULT_LOGO_SOURCE) {
        logoDataInput.val('');
        logoUrlInput.val('');
    } else {
        logoDataInput.val('');
        logoUrlInput.val(resolved);
    }

    setExtendedLogoPreview(resolved, $('#extended-logo-enabled').is(':checked'));
}

function readExtendedLogoSourceFromInputs() {
    const logoData = ($('#extended-logo-data').val() || '').toString().trim();
    const logoUrl = ($('#extended-logo-url').val() || '').toString().trim();
    const candidate = logoData !== '' ? logoData : logoUrl;
    return normalizeExtendedLogoSource(candidate, EXTENDED_DEFAULT_LOGO_SOURCE);
}

function setExtendedLogoInputsEnabled(canEdit, logoEnabled) {
    const editable = canEdit === true && logoEnabled === true;
    const settings = $('#extended-logo-settings');
    if (settings.length) {
        settings.toggle(logoEnabled === true);
    }
    $('#extended-logo-url').prop('disabled', !editable);
    $('#extended-logo-upload-btn').prop('disabled', !editable);
    $('#extended-logo-reset-btn').prop('disabled', !editable);
}

function loadImageFile(file) {
    return new Promise(function (resolve, reject) {
        const objectUrl = URL.createObjectURL(file);
        const image = new Image();
        image.onload = function () {
            URL.revokeObjectURL(objectUrl);
            resolve(image);
        };
        image.onerror = function () {
            URL.revokeObjectURL(objectUrl);
            reject(new Error('image_load_failed'));
        };
        image.src = objectUrl;
    });
}

function exportCanvasAsDataUrl(canvas, quality, maxDimension) {
    const width = canvas.width;
    const height = canvas.height;
    const scale = Math.min(1, maxDimension / Math.max(width, height));
    const targetWidth = Math.max(1, Math.round(width * scale));
    const targetHeight = Math.max(1, Math.round(height * scale));

    const resized = document.createElement('canvas');
    resized.width = targetWidth;
    resized.height = targetHeight;
    const resizedCtx = resized.getContext('2d');
    if (!resizedCtx) {
        throw new Error('canvas_context_unavailable');
    }
    resizedCtx.drawImage(canvas, 0, 0, targetWidth, targetHeight);

    let dataUrl = resized.toDataURL('image/webp', quality);
    if (!/^data:image\/webp/i.test(dataUrl)) {
        dataUrl = resized.toDataURL('image/png');
    }

    return dataUrl;
}

function compressExtendedLogoFile(file) {
    return loadImageFile(file).then(function (image) {
        const baseCanvas = document.createElement('canvas');
        baseCanvas.width = image.naturalWidth || image.width;
        baseCanvas.height = image.naturalHeight || image.height;
        const ctx = baseCanvas.getContext('2d');
        if (!ctx) {
            throw new Error('canvas_context_unavailable');
        }
        ctx.drawImage(image, 0, 0);

        const attempts = [
            { quality: 0.92, maxDimension: 512 },
            { quality: 0.88, maxDimension: 512 },
            { quality: 0.84, maxDimension: 460 },
            { quality: 0.8, maxDimension: 420 },
            { quality: 0.76, maxDimension: 384 }
        ];

        let candidate = '';
        for (let i = 0; i < attempts.length; i += 1) {
            const current = attempts[i];
            candidate = exportCanvasAsDataUrl(baseCanvas, current.quality, current.maxDimension);
            if (candidate.length <= EXTENDED_MAX_LOGO_SOURCE_LENGTH) {
                return candidate;
            }
        }

        return candidate;
    });
}

function refreshExtendedTranslations() {
    $('#extended-tab-label').text(getExtendedTranslation('extended_tab', 'Extended'));
    $('#tab-extended .sidebar-item[data-section="extended-branding"] span').text(
        getExtendedTranslation('extended_branding', 'Branding')
    );
    $('#extended-settings-title').text(getExtendedTranslation('extended_settings_title', 'NEXT HOUSING EXTENDED'));
    $('#extended-script-title-label').text(getExtendedTranslation('extended_script_title_label', 'Script title'));
    $('#extended-script-title-help').text(
        getExtendedTranslation('extended_script_title_help', 'Available only with Next Housing Extended.')
    );
    $('#extended-per-menu-toggle-label').text(
        getExtendedTranslation('extended_per_menu_toggle_label', 'Enable per-menu titles')
    );
    $('#extended-per-menu-toggle-help').text(
        getExtendedTranslation('extended_per_menu_toggle_help', 'When enabled, each menu can have its own title.')
    );
    $('#extended-square-dot-toggle-label').text(
        getExtendedTranslation('extended_square_dot_toggle_label', 'Enable square dot separator')
    );
    $('#extended-square-dot-toggle-help').text(
        getExtendedTranslation(
            'extended_square_dot_toggle_help',
            'When disabled, titles are displayed without square dots between words.'
        )
    );
    $('#extended-logo-toggle-label').text(
        getExtendedTranslation('extended_logo_toggle_label', 'Enable header logo')
    );
    $('#extended-logo-toggle-help').text(
        getExtendedTranslation(
            'extended_logo_toggle_help',
            'When enabled, a logo is shown on the left of the title and subtitle.'
        )
    );
    $('#extended-logo-url-label').text(
        getExtendedTranslation('extended_logo_url_label', 'Logo URL')
    );
    $('#extended-logo-url-help').text(
        getExtendedTranslation(
            'extended_logo_url_help',
            'You can paste a URL or upload a file. Uploaded logos are compressed and saved in base64.'
        )
    );
    $('#extended-logo-upload-btn').text(
        getExtendedTranslation('extended_logo_upload_btn', 'Upload logo')
    );
    $('#extended-logo-reset-btn').text(
        getExtendedTranslation('extended_logo_reset_btn', 'Default logo')
    );
    $('#extended-script-title-nh-label').text(
        getExtendedTranslation('extended_script_title_nh_label', 'Main /nh menu')
    );
    $('#extended-script-title-agency-label').text(
        getExtendedTranslation('extended_script_title_agency_label', 'Agency menu')
    );
    $('#extended-script-title-pap-label').text(
        getExtendedTranslation('extended_script_title_pap_label', 'PaP menu')
    );
    $('#extended-script-title-garage-label').text(
        getExtendedTranslation('extended_script_title_garage_label', 'Garage menu')
    );
    $('#extended-script-title-wardrobe-label').text(
        getExtendedTranslation('extended_script_title_wardrobe_label', 'Wardrobe menu')
    );
}

function setExtendedStatus(message, statusType, options) {
    const opts = options || {};
    const status = $('#extended-title-status');
    if (!status.length) {
        if (opts.notify !== true || statusType !== 'error' || !message) return;

        const now = Date.now();
        const lastMessage = window.__nhExtendedLastErrorMessage || '';
        const lastAt = Number(window.__nhExtendedLastErrorAt) || 0;
        if (lastMessage === message && (now - lastAt) < 2500) {
            return;
        }

        window.__nhExtendedLastErrorMessage = message;
        window.__nhExtendedLastErrorAt = now;

        $.post('https://next_housing/notify', JSON.stringify({
            message: message,
            type: 'error',
            duration: 3000
        }));
        return;
    }

    status.text(message || '');
    status.removeClass('error success');

    if (!message) return;
    if (statusType === 'error') {
        status.addClass('error');
    } else if (statusType === 'success') {
        status.addClass('success');
    }
}

function normalizeExtendedTitle(value) {
    const fallback = 'Next Housing';
    const trimmed = (value || '').toString().replace(/\s+/g, ' ').trim();
    return trimmed.length > 0 ? trimmed : fallback;
}

function normalizeExtendedMenuTitles(menuTitles, fallbackTitle) {
    const fallback = normalizeExtendedTitle(fallbackTitle || 'Next Housing');
    const normalized = {
        nh: fallback,
        agency: fallback,
        pap: fallback,
        garage: fallback,
        wardrobe: fallback
    };

    if (!menuTitles || typeof menuTitles !== 'object') {
        return normalized;
    }

    EXTENDED_MENU_CONTEXTS.forEach(function (context) {
        if (Object.prototype.hasOwnProperty.call(menuTitles, context)) {
            normalized[context] = normalizeExtendedTitle(menuTitles[context] || fallback);
        }
    });

    return normalized;
}

function cloneExtendedPayload(payload) {
    const source = payload || {};
    const title = normalizeExtendedTitle(source.title || 'Next Housing');
    return {
        title: title,
        perMenuEnabled: source.perMenuEnabled === true,
        squareDotEnabled: normalizeExtendedBool(source.squareDotEnabled, false),
        logoEnabled: normalizeExtendedBool(source.logoEnabled, true),
        logoSource: normalizeExtendedLogoSource(source.logoSource, EXTENDED_DEFAULT_LOGO_SOURCE),
        menuTitles: normalizeExtendedMenuTitles(source.menuTitles, title)
    };
}

function buildExtendedPayloadFromState(state) {
    const currentState = state || {};
    const title = normalizeExtendedTitle(currentState.title || 'Next Housing');
    return {
        title: title,
        perMenuEnabled: normalizeExtendedBool(currentState.perMenuEnabled, false),
        squareDotEnabled: normalizeExtendedBool(currentState.squareDotEnabled, false),
        logoEnabled: normalizeExtendedBool(currentState.logoEnabled, true),
        logoSource: normalizeExtendedLogoSource(currentState.logoSource, EXTENDED_DEFAULT_LOGO_SOURCE),
        menuTitles: normalizeExtendedMenuTitles(currentState.menuTitles, title)
    };
}

function readExtendedPayloadFromInputs() {
    const title = normalizeExtendedTitle($('#extended-script-title').val());
    const perMenuEnabled = $('#extended-per-menu-titles-enabled').is(':checked');
    const squareDotEnabled = $('#extended-square-dot-enabled').is(':checked');
    const logoEnabled = $('#extended-logo-enabled').is(':checked');
    const logoSource = readExtendedLogoSourceFromInputs();
    const menuTitlesInput = {};

    EXTENDED_MENU_CONTEXTS.forEach(function (context) {
        const selector = EXTENDED_MENU_INPUTS[context];
        const input = $(selector);
        menuTitlesInput[context] = input.length ? input.val() : title;
    });

    return {
        title: title,
        perMenuEnabled: perMenuEnabled,
        squareDotEnabled: squareDotEnabled,
        logoEnabled: logoEnabled,
        logoSource: logoSource,
        menuTitles: normalizeExtendedMenuTitles(menuTitlesInput, title)
    };
}

function applyExtendedPayloadToInputs(payload, maxLength, isEditable) {
    const normalizedPayload = cloneExtendedPayload(payload);
    const allowEdit = isEditable === true;
    const perMenuEnabled = normalizedPayload.perMenuEnabled === true;
    const squareDotEnabled = normalizedPayload.squareDotEnabled === true;
    const logoEnabled = normalizedPayload.logoEnabled === true;

    $('#extended-script-title').val(normalizedPayload.title);
    $('#extended-script-title').attr('maxlength', maxLength);
    $('#extended-script-title').prop('disabled', !allowEdit);

    $('#extended-per-menu-titles-enabled').prop('checked', perMenuEnabled);
    $('#extended-per-menu-titles-enabled').prop('disabled', !allowEdit);
    $('#extended-square-dot-enabled').prop('checked', squareDotEnabled);
    $('#extended-square-dot-enabled').prop('disabled', !allowEdit);
    $('#extended-logo-enabled').prop('checked', logoEnabled);
    $('#extended-logo-enabled').prop('disabled', !allowEdit);
    applyExtendedLogoSourceToInputs(normalizedPayload.logoSource);
    setExtendedLogoInputsEnabled(allowEdit, logoEnabled);

    const menuFields = $('#extended-menu-titles-settings');
    if (menuFields.length) {
        menuFields.toggle(perMenuEnabled);
    }

    EXTENDED_MENU_CONTEXTS.forEach(function (context) {
        const selector = EXTENDED_MENU_INPUTS[context];
        const input = $(selector);
        if (!input.length) return;
        input.val(normalizedPayload.menuTitles[context]);
        input.attr('maxlength', maxLength);
        input.prop('disabled', !(allowEdit && perMenuEnabled));
    });
}

function extendedPayloadEquals(left, right) {
    const a = cloneExtendedPayload(left);
    const b = cloneExtendedPayload(right);
    if (a.title !== b.title) return false;
    if (a.perMenuEnabled !== b.perMenuEnabled) return false;
    if (a.squareDotEnabled !== b.squareDotEnabled) return false;
    if (a.logoEnabled !== b.logoEnabled) return false;
    if (a.logoSource !== b.logoSource) return false;

    for (let i = 0; i < EXTENDED_MENU_CONTEXTS.length; i += 1) {
        const context = EXTENDED_MENU_CONTEXTS[i];
        if ((a.menuTitles && a.menuTitles[context]) !== (b.menuTitles && b.menuTitles[context])) {
            return false;
        }
    }

    return true;
}

window.applyExtendedTabState = function (state) {
    const extState = state || {};
    const isAvailable = extState.available === true;
    const canEdit = extState.canEdit === true;
    const titleValue = normalizeExtendedTitle(extState.title || 'Next Housing');
    const perMenuEnabled = normalizeExtendedBool(extState.perMenuEnabled, false);
    const squareDotEnabled = normalizeExtendedBool(extState.squareDotEnabled, false);
    const logoEnabled = normalizeExtendedBool(extState.logoEnabled, true);
    const logoSource = normalizeExtendedLogoSource(extState.logoSource, EXTENDED_DEFAULT_LOGO_SOURCE);
    const normalizedMenuTitles = normalizeExtendedMenuTitles(extState.menuTitles, titleValue);
    const maxLength = Number.isFinite(Number(extState.maxLength)) ? Number(extState.maxLength) : 48;

    refreshExtendedTranslations();

    const tabButton = $(".tab-btn[data-tab='extended']");
    if (isAvailable) {
        tabButton.show();
    } else {
        tabButton.hide();
        if ($(".tab-btn.active").data('tab') === 'extended') {
            activateTab('edit');
        }
    }

    applyExtendedPayloadToInputs({
        title: titleValue,
        perMenuEnabled: perMenuEnabled,
        squareDotEnabled: squareDotEnabled,
        logoEnabled: logoEnabled,
        logoSource: logoSource,
        menuTitles: normalizedMenuTitles
    }, maxLength, isAvailable && canEdit);

    if (!isAvailable) {
        setExtendedStatus(getExtendedTranslation('extended_status_not_detected', 'Next Housing Extended not detected. Title is locked.'), 'error');
        return;
    }

    if (!canEdit) {
        setExtendedStatus(getExtendedTranslation('extended_status_profile_locked', 'Customization is currently unavailable for your profile.'), 'error');
        return;
    }

    setExtendedStatus(getExtendedTranslation('extended_status_enabled', 'Premium title customization enabled.'), 'success');
};

function initializeExtendedSettings() {
    refreshExtendedTranslations();

    if (typeof window.fetchExtendedState !== 'function') {
        window.applyExtendedTabState({
            available: false,
            canEdit: false,
            title: 'Next Housing',
            perMenuEnabled: false,
            squareDotEnabled: false,
            logoEnabled: false,
            logoSource: EXTENDED_DEFAULT_LOGO_SOURCE,
            menuTitles: normalizeExtendedMenuTitles({}, 'Next Housing'),
            maxLength: 48,
        });
        return;
    }

    setExtendedStatus(getExtendedTranslation('extended_status_loading', 'Loading premium state...'), '');
    window.fetchExtendedState(true).done(function (state) {
        window.applyExtendedTabState(state);
    });
}

window.saveExtendedScriptTitle = function (options) {
    const opts = options || {};
    const titleInput = $('#extended-script-title');
    if (!titleInput.length) return;

    const payloadToSave = readExtendedPayloadFromInputs();
    const currentState = window.nhExtendedState || {};
    const currentPayload = buildExtendedPayloadFromState(currentState);

    if (currentState.available !== true || currentState.canEdit !== true) {
        setExtendedStatus(
            getExtendedTranslation('extended_status_update_blocked', 'Update blocked: premium extension or admin rights missing.'),
            'error',
            { notify: true }
        );
        return;
    }

    if (opts.force !== true && extendedPayloadEquals(payloadToSave, currentPayload)) {
        return;
    }

    applyExtendedPayloadToInputs(payloadToSave, Number(currentState.maxLength) || 48, true);

    if (window.__nhExtendedSaveInFlight === true) {
        window.__nhExtendedQueuedPayload = cloneExtendedPayload(payloadToSave);
        return;
    }

    window.__nhExtendedSaveInFlight = true;

    $.post('https://next_housing/saveExtendedScriptTitle', JSON.stringify({
        title: payloadToSave.title,
        perMenuEnabled: payloadToSave.perMenuEnabled,
        squareDotEnabled: payloadToSave.squareDotEnabled,
        logoEnabled: payloadToSave.logoEnabled,
        logoSource: payloadToSave.logoSource,
        menuTitles: payloadToSave.menuTitles
    }), function (resp) {
        let data = null;
        try {
            data = typeof resp === 'string' ? JSON.parse(resp) : resp;
        } catch (_) {
            data = null;
        }

        if (!data || data.success !== true) {
            if (typeof window.fetchExtendedState === 'function') {
                window.fetchExtendedState(true).done(function (state) {
                    window.applyExtendedTabState(state);
                });
            }
            return;
        }

        const resolvedPayload = {
            title: normalizeExtendedTitle(data.title || payloadToSave.title),
            perMenuEnabled: (data.perMenuEnabled !== undefined)
                ? normalizeExtendedBool(data.perMenuEnabled, payloadToSave.perMenuEnabled)
                : payloadToSave.perMenuEnabled,
            squareDotEnabled: (data.squareDotEnabled !== undefined)
                ? normalizeExtendedBool(data.squareDotEnabled, payloadToSave.squareDotEnabled)
                : payloadToSave.squareDotEnabled,
            logoEnabled: (data.logoEnabled !== undefined)
                ? normalizeExtendedBool(data.logoEnabled, payloadToSave.logoEnabled)
                : payloadToSave.logoEnabled,
            logoSource: normalizeExtendedLogoSource(
                data.logoSource || payloadToSave.logoSource,
                EXTENDED_DEFAULT_LOGO_SOURCE
            ),
            menuTitles: normalizeExtendedMenuTitles(data.menuTitles || payloadToSave.menuTitles, data.title || payloadToSave.title)
        };

        if (typeof window.applyExtendedStatePayload === 'function') {
            window.applyExtendedStatePayload({
                available: true,
                title: resolvedPayload.title,
                perMenuEnabled: resolvedPayload.perMenuEnabled,
                squareDotEnabled: resolvedPayload.squareDotEnabled,
                logoEnabled: resolvedPayload.logoEnabled,
                logoSource: resolvedPayload.logoSource,
                menuTitles: resolvedPayload.menuTitles,
                canCustomize: currentState.canCustomize === true,
                canEdit: currentState.canEdit === true,
                maxLength: Number(currentState.maxLength) || 48
            });
        }

        if (typeof window.fetchExtendedState === 'function') {
            window.fetchExtendedState(true).done(function (state) {
                window.applyExtendedTabState(state);
            });
            return;
        }
    }).fail(function () {
        setExtendedStatus(
            getExtendedTranslation('extended_status_network_error', 'Network error while saving title.'),
            'error',
            { notify: true }
        );
    }).always(function () {
        window.__nhExtendedSaveInFlight = false;
        const queuedPayload = window.__nhExtendedQueuedPayload;
        window.__nhExtendedQueuedPayload = null;
        if (queuedPayload && typeof queuedPayload === 'object') {
            const normalizedQueued = cloneExtendedPayload(queuedPayload);
            const statePayload = buildExtendedPayloadFromState(window.nhExtendedState || {});
            if (!extendedPayloadEquals(normalizedQueued, statePayload)) {
                applyExtendedPayloadToInputs(
                    normalizedQueued,
                    Number((window.nhExtendedState && window.nhExtendedState.maxLength) || 48) || 48,
                    true
                );
                window.saveExtendedScriptTitle({ force: true });
            }
        }
    });
};



function parseToggleValue(value, fallback) {
    if (value === undefined || value === null) return fallback;
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value === 1;
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === '1' || normalized === 'true' || normalized === 'yes' || normalized === 'on') return true;
        if (normalized === '0' || normalized === 'false' || normalized === 'no' || normalized === 'off') return false;
    }
    return fallback;
}

function getToggleEnabledFromResponse(resp, fallback) {
    let payload = resp;
    if (typeof payload === 'string') {
        try {
            payload = JSON.parse(payload);
        } catch (_) {
        }
    }

    if (payload && typeof payload === 'object' && Object.prototype.hasOwnProperty.call(payload, 'enabled')) {
        return parseToggleValue(payload.enabled, fallback);
    }

    return parseToggleValue(payload, fallback);
}

function initializeSettingsLanguages() {
    $.post('https://next_housing/getLanguage', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.locale) {
                $('#language-select').val(data.locale);
            }
        } catch (_) { }
    });
}

window.nhGaragesEnabled = (window.nhGaragesEnabled !== false);
window.nhGarageShowAllVehiclesAvailable = (window.nhGarageShowAllVehiclesAvailable !== false);

window.nhApplyGarageShowAllVehiclesAvailability = function (isAvailable) {
    const available = isAvailable === true;
    window.nhGarageShowAllVehiclesAvailable = available;

    const showAllSetting = $('#garage-show-all-vehicles-setting');
    if (showAllSetting.length) {
        showAllSetting.toggle(available);
    }

    if (!available) {
        $('#garage-show-all-vehicles').prop('checked', false);
    }

    $('#garage-show-all-vehicles').prop('disabled', !available || window.nhGaragesEnabled !== true);
};

window.nhApplyGarageEnabledState = function (enabled, options) {
    const opts = options && typeof options === 'object' ? options : {};
    const normalizedEnabled = enabled !== false;
    window.nhGaragesEnabled = normalizedEnabled;

    if (opts.syncToggle !== false) {
        $('#garage-enabled').prop('checked', normalizedEnabled);
    }

    $('#garage-show-all-vehicles').prop('disabled', !normalizedEnabled || window.nhGarageShowAllVehiclesAvailable === false);

    const createSection = $('#garage-create-section');
    if (createSection.length) {
        createSection.toggle(normalizedEnabled);
    }
    $('#garagex, #garagey, #garagez, #garageh').prop('disabled', !normalizedEnabled);

    const entranceSection = $('#entrance-coords-section');
    if (entranceSection.length) {
        if (normalizedEnabled) {
            entranceSection.css({
                'grid-column': '',
                'width': ''
            });
        } else {
            entranceSection.css({
                'grid-column': '1 / -1',
                'width': '100%'
            });
        }
    }

    const manageSection = $('#garage-coords-section');
    if (manageSection.length) {
        manageSection.css('display', normalizedEnabled ? 'flex' : 'none');
    }
    $('#garagex-manage, #garagey-manage, #garagez-manage, #garageh-manage').prop('disabled', !normalizedEnabled);
};

function initializeSettingsGarage() {
    const initToken = window.__nhSettingsInitToken || 0;
    const initialSettings = window.__nhInitialSettings || {};
    const fieldId = 'garage-enabled';
    const canApplyField = function () {
        if (typeof window.isSettingsInitTokenCurrent === 'function' && !window.isSettingsInitTokenCurrent(initToken)) {
            return false;
        }
        if (typeof window.hasSettingsFieldBeenTouched === 'function' && window.hasSettingsFieldBeenTouched(fieldId)) {
            return false;
        }
        return true;
    };

    if (initialSettings.garagesEnabledLoaded === true && canApplyField()) {
        const enabledFromSnapshot = parseToggleValue(initialSettings.garagesEnabled, true);
        if (typeof window.nhApplyGarageEnabledState === 'function') {
            window.nhApplyGarageEnabledState(enabledFromSnapshot, { syncToggle: true });
        } else {
            $('#garage-enabled').prop('checked', enabledFromSnapshot);
            window.nhGaragesEnabled = enabledFromSnapshot;
        }
    }

    $.post('https://next_housing/getGaragesEnabled', JSON.stringify({}), function (resp) {
        if (!canApplyField()) {
            return;
        }

        let enabled = true;
        try {
            enabled = getToggleEnabledFromResponse(resp, true);
        } catch (_) {
            enabled = true;
        }

        if (typeof window.nhApplyGarageEnabledState === 'function') {
            window.nhApplyGarageEnabledState(enabled, { syncToggle: true });
        } else {
            $('#garage-enabled').prop('checked', enabled);
            window.nhGaragesEnabled = enabled;
        }
    });

    $.post('https://next_housing/getGarageSystem', JSON.stringify({}), function (resp) {
        let system = 'esx';
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (payload && typeof payload.system === 'string') {
                system = payload.system.toLowerCase();
            }
        } catch (_) {
            system = 'esx';
        }

        const showAllAvailable = system === 'qbcore';
        if (typeof window.nhApplyGarageShowAllVehiclesAvailability === 'function') {
            window.nhApplyGarageShowAllVehiclesAvailability(showAllAvailable);
        }

        if (!showAllAvailable) {
            return;
        }

        $.post('https://next_housing/getGarageShowAllVehicles', JSON.stringify({}), function (showAllResp) {
            try {
                $('#garage-show-all-vehicles').prop('checked', getToggleEnabledFromResponse(showAllResp, true));
            } catch (_) {
                $('#garage-show-all-vehicles').prop('checked', true);
            }
        });
    });
}

window.nhStashCustomCoordsEnabled = window.nhStashCustomCoordsEnabled === true;
window.nhStashInteriorCoordsOverrides = window.nhStashInteriorCoordsOverrides || {};
window.nhStashInteriorOptionsHtmlCache = window.nhStashInteriorOptionsHtmlCache || null;
window.nhLastStashCoordsSaveErrorAt = Number(window.nhLastStashCoordsSaveErrorAt) || 0;
window.nhWardrobeCustomCoordsEnabled = window.nhWardrobeCustomCoordsEnabled === true;
window.nhWardrobeInteriorCoordsOverrides = window.nhWardrobeInteriorCoordsOverrides || {};
window.nhWardrobeInteriorOptionsHtmlCache = window.nhWardrobeInteriorOptionsHtmlCache || null;
window.nhLastWardrobeCoordsSaveErrorAt = Number(window.nhLastWardrobeCoordsSaveErrorAt) || 0;

function normalizeStashInteriorCoordsOverrides(rawOverrides) {
    const normalized = {};
    const source = rawOverrides && typeof rawOverrides === 'object' ? rawOverrides : {};

    Object.keys(source).forEach(function (interiorId) {
        const interiorNum = parseInt(interiorId, 10);
        const coords = source[interiorId];
        const x = coords && Number(coords.x);
        const y = coords && Number(coords.y);
        const z = coords && Number(coords.z);
        if (Number.isFinite(interiorNum) && Number.isFinite(x) && Number.isFinite(y) && Number.isFinite(z)) {
            normalized[String(interiorNum)] = { x: x, y: y, z: z };
        }
    });

    return normalized;
}

function refreshStashInteriorSelectDropdown() {
    if (typeof window.refreshCustomDropdown === 'function') {
        window.refreshCustomDropdown('stash-global-interior-select');
    }
    if (typeof window.syncCustomDropdown === 'function') {
        window.syncCustomDropdown('stash-global-interior-select');
    }
}

function notifyStashCoordsSaveError() {
    const now = Date.now();
    if ((now - window.nhLastStashCoordsSaveErrorAt) < 1500) {
        return;
    }

    window.nhLastStashCoordsSaveErrorAt = now;

    const fallbackMessage = 'Failed to save stash coordinates.';
    const message = (window.translations && (
        window.translations.stash_coords_save_error
        || window.translations.update_error
        || window.translations.error
    )) || fallbackMessage;

    $.post('https://next_housing/notify', JSON.stringify({
        message: message,
        type: 'error',
        duration: 3000
    }));
}

function cloneStashInteriorOptionsFromCreateForm() {
    const targetSelect = $('#stash-global-interior-select');
    if (!targetSelect.length) {
        return;
    }

    const sourceSelect = $('#interior-select');
    if (!sourceSelect.length) {
        return;
    }

    const sourceOptionsHtml = sourceSelect.html();
    const normalizedSourceOptionsHtml = (typeof sourceOptionsHtml === 'string')
        ? sourceOptionsHtml.trim()
        : '';
    const previousValue = (targetSelect.val() || '').toString().trim();
    let shouldRefreshDropdown = false;

    if (normalizedSourceOptionsHtml === '') {
        if (window.nhStashInteriorOptionsHtmlCache !== '' || targetSelect.find('option').length > 0) {
            targetSelect.empty();
            window.nhStashInteriorOptionsHtmlCache = '';
            shouldRefreshDropdown = true;
        }
        if (shouldRefreshDropdown) {
            refreshStashInteriorSelectDropdown();
        }
        return;
    }

    if (window.nhStashInteriorOptionsHtmlCache !== sourceOptionsHtml) {
        targetSelect.html(sourceOptionsHtml);
        window.nhStashInteriorOptionsHtmlCache = sourceOptionsHtml;
        shouldRefreshDropdown = true;
    }

    if (previousValue.length > 0 && targetSelect.find('option[value="' + previousValue + '"]').length > 0) {
        const currentValue = (targetSelect.val() || '').toString().trim();
        if (currentValue !== previousValue) {
            targetSelect.val(previousValue);
            shouldRefreshDropdown = true;
        }
    }

    if (!targetSelect.val()) {
        const firstOption = targetSelect.find('option').first();
        if (firstOption.length) {
            const firstValue = (firstOption.val() || '').toString().trim();
            const currentValue = (targetSelect.val() || '').toString().trim();
            if (currentValue !== firstValue) {
                targetSelect.val(firstOption.val());
                shouldRefreshDropdown = true;
            }
        }
    }

    if (shouldRefreshDropdown) {
        refreshStashInteriorSelectDropdown();
    }
}

function getSelectedStashInteriorId() {
    const interiorValue = ($('#stash-global-interior-select').val() || '').toString().trim();
    const interiorNum = parseInt(interiorValue, 10);
    if (!Number.isFinite(interiorNum)) {
        return null;
    }
    return String(interiorNum);
}

function loadSelectedStashInteriorCoords() {
    cloneStashInteriorOptionsFromCreateForm();

    const interiorId = getSelectedStashInteriorId();
    const coords = interiorId ? window.nhStashInteriorCoordsOverrides[interiorId] : null;
    if (coords && Number.isFinite(Number(coords.x)) && Number.isFinite(Number(coords.y)) && Number.isFinite(Number(coords.z))) {
        $('#stash-global-x').val(Number(coords.x).toFixed(2));
        $('#stash-global-y').val(Number(coords.y).toFixed(2));
        $('#stash-global-z').val(Number(coords.z).toFixed(2));
    } else {
        $('#stash-global-x').val('');
        $('#stash-global-y').val('');
        $('#stash-global-z').val('');
    }
}

function updateStashGlobalCoordsVisibility() {
    const section = $('#stash-global-coords-settings');
    if (!section.length) {
        return;
    }

    const enabled = window.nhStashCustomCoordsEnabled === true;
    section.toggle(enabled);
    $('#stash-global-interior-select, #stash-global-x, #stash-global-y, #stash-global-z').prop('disabled', !enabled);

    if (enabled) {
        loadSelectedStashInteriorCoords();
    }
}

window.updateStashGlobalCoordsVisibility = updateStashGlobalCoordsVisibility;
window.nhLoadSelectedStashInteriorCoords = loadSelectedStashInteriorCoords;

window.nhSaveSelectedStashInteriorCoords = function () {
    if (window.nhStashCustomCoordsEnabled !== true) {
        return;
    }

    const interiorId = getSelectedStashInteriorId();
    const x = Number($('#stash-global-x').val());
    const y = Number($('#stash-global-y').val());
    const z = Number($('#stash-global-z').val());
    if (!interiorId || !Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(z)) {
        return;
    }

    $.post('https://next_housing/saveStashInteriorCoords', JSON.stringify({
        interior: Number(interiorId),
        x: x,
        y: y,
        z: z
    }), function (resp) {
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (!payload || payload.success !== true) {
                notifyStashCoordsSaveError();
                return;
            }

            const overrides = payload.overrides && typeof payload.overrides === 'object'
                ? payload.overrides
                : window.nhStashInteriorCoordsOverrides;
            window.nhStashInteriorCoordsOverrides = normalizeStashInteriorCoordsOverrides(overrides);
            loadSelectedStashInteriorCoords();
        } catch (_) {
            notifyStashCoordsSaveError();
        }
    }).fail(function () {
        notifyStashCoordsSaveError();
    });
};

function initializeSettingsStash() {
    cloneStashInteriorOptionsFromCreateForm();

    $.post('https://next_housing/getStashesEnabled', JSON.stringify({}), function (resp) {
        try {
            $('#stash-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#stash-enabled').prop('checked', true);
        }
    });

    $.post('https://next_housing/getStashSystem', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            const system = data && data.system ? data.system : (typeof resp === 'string' ? resp : 'auto');
            $('#stash-system').val(system);
        } catch (_) {
            $('#stash-system').val('auto');
        }
    });

    $.post('https://next_housing/getStashCustomCoordsEnabled', JSON.stringify({}), function (resp) {
        try {
            const enabled = getToggleEnabledFromResponse(resp, false);
            $('#stash-custom-coords-enabled').prop('checked', enabled);
            window.nhStashCustomCoordsEnabled = enabled;
        } catch (_) {
            $('#stash-custom-coords-enabled').prop('checked', false);
            window.nhStashCustomCoordsEnabled = false;
        }

        if (typeof window.updateStashGlobalCoordsVisibility === 'function') {
            window.updateStashGlobalCoordsVisibility();
        }
    });

    $.post('https://next_housing/getStashInteriorCoordsMap', JSON.stringify({}), function (resp) {
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            const overrides = payload && payload.overrides && typeof payload.overrides === 'object'
                ? payload.overrides
                : (payload && typeof payload === 'object' ? payload : {});
            window.nhStashInteriorCoordsOverrides = normalizeStashInteriorCoordsOverrides(overrides);
        } catch (_) {
            window.nhStashInteriorCoordsOverrides = {};
        }

        loadSelectedStashInteriorCoords();
        if (typeof window.updateStashGlobalCoordsVisibility === 'function') {
            window.updateStashGlobalCoordsVisibility();
        }
    });
}

function normalizeWardrobeInteriorCoordsOverrides(rawOverrides) {
    const normalized = {};
    const source = rawOverrides && typeof rawOverrides === 'object' ? rawOverrides : {};

    Object.keys(source).forEach(function (interiorId) {
        const interiorNum = parseInt(interiorId, 10);
        const coords = source[interiorId];
        const x = coords && Number(coords.x);
        const y = coords && Number(coords.y);
        const z = coords && Number(coords.z);
        if (Number.isFinite(interiorNum) && Number.isFinite(x) && Number.isFinite(y) && Number.isFinite(z)) {
            normalized[String(interiorNum)] = { x: x, y: y, z: z };
        }
    });

    return normalized;
}

function refreshWardrobeInteriorSelectDropdown() {
    if (typeof window.refreshCustomDropdown === 'function') {
        window.refreshCustomDropdown('wardrobe-global-interior-select');
    }
    if (typeof window.syncCustomDropdown === 'function') {
        window.syncCustomDropdown('wardrobe-global-interior-select');
    }
}

function notifyWardrobeCoordsSaveError() {
    const now = Date.now();
    if ((now - window.nhLastWardrobeCoordsSaveErrorAt) < 1500) {
        return;
    }

    window.nhLastWardrobeCoordsSaveErrorAt = now;

    const fallbackMessage = 'Failed to save wardrobe coordinates.';
    const message = (window.translations && (
        window.translations.wardrobe_coords_save_error
        || window.translations.update_error
        || window.translations.error
    )) || fallbackMessage;

    $.post('https://next_housing/notify', JSON.stringify({
        message: message,
        type: 'error',
        duration: 3000
    }));
}

function cloneWardrobeInteriorOptionsFromCreateForm() {
    const targetSelect = $('#wardrobe-global-interior-select');
    if (!targetSelect.length) {
        return;
    }

    const sourceSelect = $('#interior-select');
    if (!sourceSelect.length) {
        return;
    }

    const sourceOptionsHtml = sourceSelect.html();
    const normalizedSourceOptionsHtml = (typeof sourceOptionsHtml === 'string')
        ? sourceOptionsHtml.trim()
        : '';
    const previousValue = (targetSelect.val() || '').toString().trim();
    let shouldRefreshDropdown = false;

    if (normalizedSourceOptionsHtml === '') {
        if (window.nhWardrobeInteriorOptionsHtmlCache !== '' || targetSelect.find('option').length > 0) {
            targetSelect.empty();
            window.nhWardrobeInteriorOptionsHtmlCache = '';
            shouldRefreshDropdown = true;
        }
        if (shouldRefreshDropdown) {
            refreshWardrobeInteriorSelectDropdown();
        }
        return;
    }

    if (window.nhWardrobeInteriorOptionsHtmlCache !== sourceOptionsHtml) {
        targetSelect.html(sourceOptionsHtml);
        window.nhWardrobeInteriorOptionsHtmlCache = sourceOptionsHtml;
        shouldRefreshDropdown = true;
    }

    if (previousValue.length > 0 && targetSelect.find('option[value="' + previousValue + '"]').length > 0) {
        const currentValue = (targetSelect.val() || '').toString().trim();
        if (currentValue !== previousValue) {
            targetSelect.val(previousValue);
            shouldRefreshDropdown = true;
        }
    }

    if (!targetSelect.val()) {
        const firstOption = targetSelect.find('option').first();
        if (firstOption.length) {
            const firstValue = (firstOption.val() || '').toString().trim();
            const currentValue = (targetSelect.val() || '').toString().trim();
            if (currentValue !== firstValue) {
                targetSelect.val(firstOption.val());
                shouldRefreshDropdown = true;
            }
        }
    }

    if (shouldRefreshDropdown) {
        refreshWardrobeInteriorSelectDropdown();
    }
}

function getSelectedWardrobeInteriorId() {
    const interiorValue = ($('#wardrobe-global-interior-select').val() || '').toString().trim();
    const interiorNum = parseInt(interiorValue, 10);
    if (!Number.isFinite(interiorNum)) {
        return null;
    }
    return String(interiorNum);
}

function loadSelectedWardrobeInteriorCoords() {
    cloneWardrobeInteriorOptionsFromCreateForm();

    const interiorId = getSelectedWardrobeInteriorId();
    const coords = interiorId ? window.nhWardrobeInteriorCoordsOverrides[interiorId] : null;
    if (coords && Number.isFinite(Number(coords.x)) && Number.isFinite(Number(coords.y)) && Number.isFinite(Number(coords.z))) {
        $('#wardrobe-global-x').val(Number(coords.x).toFixed(2));
        $('#wardrobe-global-y').val(Number(coords.y).toFixed(2));
        $('#wardrobe-global-z').val(Number(coords.z).toFixed(2));
    } else {
        $('#wardrobe-global-x').val('');
        $('#wardrobe-global-y').val('');
        $('#wardrobe-global-z').val('');
    }
}

function updateWardrobeGlobalCoordsVisibility() {
    const section = $('#wardrobe-global-coords-settings');
    if (!section.length) {
        return;
    }

    const enabled = window.nhWardrobeCustomCoordsEnabled === true;
    section.toggle(enabled);
    $('#wardrobe-global-interior-select, #wardrobe-global-x, #wardrobe-global-y, #wardrobe-global-z').prop('disabled', !enabled);

    if (enabled) {
        loadSelectedWardrobeInteriorCoords();
    }
}

window.updateWardrobeGlobalCoordsVisibility = updateWardrobeGlobalCoordsVisibility;
window.nhLoadSelectedWardrobeInteriorCoords = loadSelectedWardrobeInteriorCoords;

window.nhSaveSelectedWardrobeInteriorCoords = function () {
    if (window.nhWardrobeCustomCoordsEnabled !== true) {
        return;
    }

    const interiorId = getSelectedWardrobeInteriorId();
    const x = Number($('#wardrobe-global-x').val());
    const y = Number($('#wardrobe-global-y').val());
    const z = Number($('#wardrobe-global-z').val());
    if (!interiorId || !Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(z)) {
        return;
    }

    $.post('https://next_housing/saveWardrobeInteriorCoords', JSON.stringify({
        interior: Number(interiorId),
        x: x,
        y: y,
        z: z
    }), function (resp) {
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (!payload || payload.success !== true) {
                notifyWardrobeCoordsSaveError();
                return;
            }

            const overrides = payload.overrides && typeof payload.overrides === 'object'
                ? payload.overrides
                : window.nhWardrobeInteriorCoordsOverrides;
            window.nhWardrobeInteriorCoordsOverrides = normalizeWardrobeInteriorCoordsOverrides(overrides);
            loadSelectedWardrobeInteriorCoords();
        } catch (_) {
            notifyWardrobeCoordsSaveError();
        }
    }).fail(function () {
        notifyWardrobeCoordsSaveError();
    });
};

function initializeSettingsBeta() {
    const customShellsToggle = $('#custom-shells-enabled');
    customShellsToggle.prop('checked', false);
    customShellsToggle.prop('disabled', true);

    $.post('https://next_housing/getCustomShellsEnabled', JSON.stringify({}), function () {
        customShellsToggle.prop('checked', false);
        updateCustomShellsTabVisibility();
    }).fail(function () {
        customShellsToggle.prop('checked', false);
        updateCustomShellsTabVisibility();
    });
}

function initializeSettingsBurglary() {
    $.post('https://next_housing/getBurglaryEnabled', JSON.stringify({}), function (resp) {
        try {
            $('#burglary-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#burglary-enabled').prop('checked', true);
        }
    });
}

function updateCustomShellsTabVisibility() {
    const isEnabled = $('#custom-shells-enabled').is(':checked');
    const shellsTab = $(".tab-btn[data-tab='shells']");
    if (isEnabled) {
        shellsTab.show();
    } else {
        shellsTab.hide();
        if (shellsTab.hasClass('active')) {
            activateTab('edit');
        }
    }
}

function initializeSettingsMarkers() {
    const initToken = window.__nhSettingsInitToken || 0;
    const initialSettings = window.__nhInitialSettings || {};
    const canApplyField = function (fieldId) {
        if (typeof window.isSettingsInitTokenCurrent === 'function' && !window.isSettingsInitTokenCurrent(initToken)) {
            return false;
        }
        if (typeof window.hasSettingsFieldBeenTouched === 'function' && window.hasSettingsFieldBeenTouched(fieldId)) {
            return false;
        }
        return true;
    };

    const toBool = function (value, fallback) {
        if (typeof value === 'boolean') return value;
        if (typeof value === 'number') return value === 1;
        if (typeof value === 'string') {
            const normalized = value.trim().toLowerCase();
            if (normalized === '1' || normalized === 'true' || normalized === 'yes' || normalized === 'on') return true;
            if (normalized === '0' || normalized === 'false' || normalized === 'no' || normalized === 'off') return false;
        }
        return fallback;
    };

    const toNumberValue = function (value, fallback) {
        const parsed = parseFloat(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    };

    const applyBundle = function (bundle) {
        if (!bundle || typeof bundle !== 'object') return;

        const spritesEnabled = toBool(bundle.spritesEnabled, $('#sprites-enabled').is(':checked'));
        const blipsEnabled = toBool(bundle.blipsEnabled, $('#blips-enabled').is(':checked'));
        const spriteHeightOffset = toNumberValue(bundle.spriteHeightOffset, parseFloat($('#sprite-height-offset').val() || 1.0));
        const entranceDistance = toNumberValue(bundle.entranceDisplayDistance, parseFloat($('#entrance-display-distance').val() || 20.0));
        const chestDistance = toNumberValue(bundle.chestDisplayDistance, parseFloat($('#chest-display-distance').val() || 2.0));

        if (canApplyField('sprites-enabled')) {
            $('#sprites-enabled').prop('checked', spritesEnabled);
        }

        if (canApplyField('blips-enabled')) {
            $('#blips-enabled').prop('checked', blipsEnabled);
        }

        if (canApplyField('sprite-height-offset')) {
            $('#sprite-height-offset').val(spriteHeightOffset);
            $('#sprite-height-offset-value').text(spriteHeightOffset.toFixed(1));
        }

        if (canApplyField('entrance-display-distance')) {
            $('#entrance-display-distance').val(entranceDistance);
            $('#entrance-display-distance-value').text(entranceDistance.toFixed(1));
        }

        if (canApplyField('chest-display-distance')) {
            $('#chest-display-distance').val(chestDistance);
            $('#chest-display-distance-value').text(chestDistance.toFixed(1));
        }
    };

    if (translations && Object.keys(translations).length > 0) {
        $("#section-settings-markers .config-card:nth-child(3) .card-header h4").text(translations.sprite_height_offset);
        $("#section-settings-markers .config-card:nth-child(3) .card-content p").text(translations.sprite_height_offset_help);
        $("#section-settings-markers .config-card:nth-child(4) .card-header h4").text(translations.entrance_display_distance_label);
        $("#section-settings-markers .config-card:nth-child(4) .card-content p").text(translations.entrance_display_distance_hint);
        $("#section-settings-markers .config-card:nth-child(5) .card-header h4").text(translations.chest_display_distance_label);
        $("#section-settings-markers .config-card:nth-child(5) .card-content p").text(translations.chest_display_distance_hint);
    }

    if (initialSettings.spritesEnabledLoaded === true && canApplyField('sprites-enabled')) {
        $('#sprites-enabled').prop('checked', toBool(initialSettings.spritesEnabled, $('#sprites-enabled').is(':checked')));
    }
    if (initialSettings.blipsEnabledLoaded === true && canApplyField('blips-enabled')) {
        $('#blips-enabled').prop('checked', toBool(initialSettings.blipsEnabled, $('#blips-enabled').is(':checked')));
    }
    if (canApplyField('sprite-height-offset')) {
        const initialOffset = toNumberValue(initialSettings.spriteHeightOffset, parseFloat($('#sprite-height-offset').val() || 1.0));
        $('#sprite-height-offset').val(initialOffset);
        $('#sprite-height-offset-value').text(initialOffset.toFixed(1));
    }
    if (canApplyField('entrance-display-distance')) {
        const initialEntranceDistance = toNumberValue(initialSettings.entranceDisplayDistance, parseFloat($('#entrance-display-distance').val() || 20.0));
        $('#entrance-display-distance').val(initialEntranceDistance);
        $('#entrance-display-distance-value').text(initialEntranceDistance.toFixed(1));
    }
    if (canApplyField('chest-display-distance')) {
        const initialChestDistance = toNumberValue(initialSettings.chestDisplayDistance, parseFloat($('#chest-display-distance').val() || 2.0));
        $('#chest-display-distance').val(initialChestDistance);
        $('#chest-display-distance-value').text(initialChestDistance.toFixed(1));
    }

    const spritesFallback = toBool(initialSettings.spritesEnabled, true);
    const blipsFallback = toBool(initialSettings.blipsEnabled, true);
    const spriteOffsetFallback = toNumberValue(initialSettings.spriteHeightOffset, 1.0);
    const entranceDistanceFallback = toNumberValue(initialSettings.entranceDisplayDistance, 20.0);
    const chestDistanceFallback = toNumberValue(initialSettings.chestDisplayDistance, 2.0);

    $.post('https://next_housing/getMarkerSettingsBundle', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && typeof data === 'object') {
                applyBundle(data);
                return;
            }
        } catch (_) {
        }

        applyBundle({
            spritesEnabled: spritesFallback,
            blipsEnabled: blipsFallback,
            spriteHeightOffset: spriteOffsetFallback,
            entranceDisplayDistance: entranceDistanceFallback,
            chestDisplayDistance: chestDistanceFallback,
        });
    });

    $('#sprite-height-offset').off('input.nhMarkers').on('input.nhMarkers', function () {
        const value = parseFloat($(this).val());
        $('#sprite-height-offset-value').text(value.toFixed(1));
    });

    $('#entrance-display-distance').off('input.nhMarkers').on('input.nhMarkers', function () {
        const value = parseFloat($(this).val());
        $('#entrance-display-distance-value').text(value.toFixed(1));
    });

    $('#chest-display-distance').off('input.nhMarkers').on('input.nhMarkers', function () {
        const value = parseFloat($(this).val());
        $('#chest-display-distance-value').text(value.toFixed(1));
    });
}

function initializeSettingsHousePreviews() {
    const fieldId = 'house-preview-placeholders-enabled';
    const initToken = window.__nhSettingsInitToken || 0;
    const initialSettings = window.__nhInitialSettings || {};
    const canApplyField = function () {
        if (typeof window.isSettingsInitTokenCurrent === 'function' && !window.isSettingsInitTokenCurrent(initToken)) {
            return false;
        }
        if (typeof window.hasSettingsFieldBeenTouched === 'function' && window.hasSettingsFieldBeenTouched(fieldId)) {
            return false;
        }
        return true;
    };

    if (initialSettings.housePreviewPlaceholdersEnabledLoaded === true && canApplyField()) {
        $('#house-preview-placeholders-enabled').prop(
            'checked',
            parseToggleValue(initialSettings.housePreviewPlaceholdersEnabled, true)
        );
    }

    $.post('https://next_housing/getHousePreviewPlaceholdersEnabled', JSON.stringify({}), function (resp) {
        if (!canApplyField()) {
            return;
        }

        try {
            $('#house-preview-placeholders-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#house-preview-placeholders-enabled').prop('checked', true);
        }
    });
}



function initializeAgencySettings() {
    $.post('https://next_housing/getJobEnabled', JSON.stringify({}), function (resp) {
        try {
            $('#job-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#job-enabled').prop('checked', true);
        }
    });

    $.post('https://next_housing/getJobCommand', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.command) {
                $('#job-command').val(data.command);
            } else {
                $('#job-command').val('realestate');
            }
        } catch (_) {
            $('#job-command').val('realestate');
        }
    });

    $.post('https://next_housing/getJobName', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.jobName) {
                $('#job-name').val(data.jobName);
            } else {
                $('#job-name').val('realestate');
            }
        } catch (_) {
            $('#job-name').val('realestate');
        }
    });

    $.post('https://next_housing/getDirectPurchaseEnabled', JSON.stringify({}), function (resp) {
        try {
            $('#direct-purchase-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#direct-purchase-enabled').prop('checked', true);
        }
    });

    $.post('https://next_housing/getTreasuryWithdrawMinGrade', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && typeof data.minGrade !== 'undefined') {
                $('#treasury-withdraw-min-grade').val(data.minGrade || 0);
            } else {
                $('#treasury-withdraw-min-grade').val(0);
            }
        } catch (_) {
            $('#treasury-withdraw-min-grade').val(0);
        }
    });

    $.post('https://next_housing/getCurrencySymbol', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.symbol) {
                currencySymbol = data.symbol;
                const symbolField = $('#currency-symbol');
                if (symbolField.length > 0) {
                    symbolField.val(data.symbol);
                } else {
                    setTimeout(function () {
                        $('#currency-symbol').val(data.symbol);
                    }, 100);
                }
            } else {
                $('#currency-symbol').val('$');
            }
        } catch (e) {
            $('#currency-symbol').val('$');
        }
    });

    $.post('https://next_housing/getRentPaymentMode', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.mode) {
                const modeField = $('#rent-payment-mode');
                if (modeField.length > 0) {
                    modeField.val(data.mode);
                } else {
                    setTimeout(function () {
                        $('#rent-payment-mode').val(data.mode);
                    }, 100);
                }
            } else {
                $('#rent-payment-mode').val('hours');
            }
        } catch (_) {
            $('#rent-payment-mode').val('hours');
        }
    });

    $.post('https://next_housing/getRentPaymentInterval', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.interval) {
                const intervalField = $('#rent-payment-interval');
                if (intervalField.length > 0) {
                    intervalField.val(data.interval);
                } else {
                    setTimeout(function () {
                        $('#rent-payment-interval').val(data.interval);
                    }, 100);
                }
            } else {
                $('#rent-payment-interval').val('1');
            }
        } catch (_) {
            $('#rent-payment-interval').val('1');
        }
    });

    $.post('https://next_housing/getPapSettings', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data) {
                const papEnabledBool = parseToggleValue(data.enabled, false);
                const papAllowRentBool = parseToggleValue(data.allowRent, false);
                $('#pap-enabled').prop('checked', papEnabledBool);
                $('#pap-allow-rent').prop('checked', papAllowRentBool);
                $('#pap-command').val(data.command || 'classifieds');
                $('#pap-listing-fee').val(data.listingFee || 0);
                $('#pap-max-listings').val((data.listingLimit !== undefined ? data.listingLimit : data.maxListings) || 3);
                $('#pap-listing-duration').val(data.listingDuration || 14);
            } else {
                $('#pap-enabled').prop('checked', false);
                $('#pap-allow-rent').prop('checked', false);
                $('#pap-command').val('classifieds');
                $('#pap-listing-fee').val(0);
                $('#pap-max-listings').val(3);
                $('#pap-listing-duration').val(14);
            }
        } catch (_) {
            $('#pap-enabled').prop('checked', false);
            $('#pap-allow-rent').prop('checked', false);
            $('#pap-command').val('classifieds');
            $('#pap-listing-fee').val(0);
            $('#pap-max-listings').val(3);
            $('#pap-listing-duration').val(14);
        }
    });
}

function initializeSettingsWardrobe() {
    if (typeof window.startSettingsHydration === 'function') {
        window.startSettingsHydration(1500);
    }

    cloneWardrobeInteriorOptionsFromCreateForm();

    $.post('https://next_housing/getWardrobeEnabled', JSON.stringify({}), function (resp) {
        try {
            $('#wardrobe-enabled').prop('checked', getToggleEnabledFromResponse(resp, true));
        } catch (_) {
            $('#wardrobe-enabled').prop('checked', false);
        }
    });

    $.post('https://next_housing/getWardrobeSystem', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            const system = data && data.system ? data.system : (typeof resp === 'string' ? resp : 'illenium-appearance');
            $('#wardrobe-system').val(system);
        } catch (_) {
            $('#wardrobe-system').val('illenium-appearance');
        }
    });

    $.post('https://next_housing/getWardrobeCustomCoordsEnabled', JSON.stringify({}), function (resp) {
        try {
            const enabled = getToggleEnabledFromResponse(resp, false);
            $('#wardrobe-custom-coords-enabled').prop('checked', enabled);
            window.nhWardrobeCustomCoordsEnabled = enabled;
        } catch (_) {
            $('#wardrobe-custom-coords-enabled').prop('checked', false);
            window.nhWardrobeCustomCoordsEnabled = false;
        }

        if (typeof window.updateWardrobeGlobalCoordsVisibility === 'function') {
            window.updateWardrobeGlobalCoordsVisibility();
        }
    });

    $.post('https://next_housing/getWardrobeInteriorCoordsMap', JSON.stringify({}), function (resp) {
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            const overrides = payload && payload.overrides && typeof payload.overrides === 'object'
                ? payload.overrides
                : (payload && typeof payload === 'object' ? payload : {});
            window.nhWardrobeInteriorCoordsOverrides = normalizeWardrobeInteriorCoordsOverrides(overrides);
        } catch (_) {
            window.nhWardrobeInteriorCoordsOverrides = {};
        }

        loadSelectedWardrobeInteriorCoords();
        if (typeof window.updateWardrobeGlobalCoordsVisibility === 'function') {
            window.updateWardrobeGlobalCoordsVisibility();
        }
    });
}



window.scanTimeoutId = null;

$(document).on('click', '.tab-btn', function () {
    const t = $(this).data('tab');
    activateTab(t);
    if (t === 'edit') {
        if (typeof hasManageHouseData === 'function' && hasManageHouseData()) {
            return;
        }

        beginManageScan({
            keepCurrentInfo: true,
            suppressLoading: true,
            fallbackToEmpty: false
        });
    }
});

window.__nhExtendedAutoSaveTimer = null;

function queueExtendedAutoSave() {
    if (window.__nhExtendedAutoSaveTimer) {
        clearTimeout(window.__nhExtendedAutoSaveTimer);
    }

    window.__nhExtendedAutoSaveTimer = setTimeout(function () {
        window.__nhExtendedAutoSaveTimer = null;
        if (typeof window.saveExtendedScriptTitle === 'function') {
            window.saveExtendedScriptTitle();
        }
    }, 600);
}

const EXTENDED_AUTO_SAVE_SELECTOR = [
    '#extended-script-title',
    '#extended-script-title-nh',
    '#extended-script-title-agency',
    '#extended-script-title-pap',
    '#extended-script-title-garage',
    '#extended-script-title-wardrobe',
    '#extended-logo-url'
].join(', ');

$(document).on('keydown', EXTENDED_AUTO_SAVE_SELECTOR, function (e) {
    if (e.key !== 'Enter') return;
    e.preventDefault();
    if (window.__nhExtendedAutoSaveTimer) {
        clearTimeout(window.__nhExtendedAutoSaveTimer);
        window.__nhExtendedAutoSaveTimer = null;
    }
    if (typeof window.saveExtendedScriptTitle === 'function') {
        window.saveExtendedScriptTitle({ force: true });
    }
});

$(document).on('input', EXTENDED_AUTO_SAVE_SELECTOR, function () {
    queueExtendedAutoSave();
});

$(document).on('blur', EXTENDED_AUTO_SAVE_SELECTOR, function () {
    if (window.__nhExtendedAutoSaveTimer) {
        clearTimeout(window.__nhExtendedAutoSaveTimer);
        window.__nhExtendedAutoSaveTimer = null;
    }
    if (typeof window.saveExtendedScriptTitle === 'function') {
        window.saveExtendedScriptTitle();
    }
});

$(document).on('change', '#extended-per-menu-titles-enabled', function () {
    const currentState = window.nhExtendedState || {};
    const maxLength = Number(currentState.maxLength) || 48;
    const canEdit = currentState.available === true && currentState.canEdit === true;
    const currentPayload = readExtendedPayloadFromInputs();

    applyExtendedPayloadToInputs(currentPayload, maxLength, canEdit);
    queueExtendedAutoSave();
});

$(document).on('change', '#extended-square-dot-enabled', function () {
    const currentState = window.nhExtendedState || {};
    const maxLength = Number(currentState.maxLength) || 48;
    const canEdit = currentState.available === true && currentState.canEdit === true;
    const currentPayload = readExtendedPayloadFromInputs();

    applyExtendedPayloadToInputs(currentPayload, maxLength, canEdit);
    queueExtendedAutoSave();
});

$(document).on('change', '#extended-logo-enabled', function () {
    const currentState = window.nhExtendedState || {};
    const maxLength = Number(currentState.maxLength) || 48;
    const canEdit = currentState.available === true && currentState.canEdit === true;
    const currentPayload = readExtendedPayloadFromInputs();

    applyExtendedPayloadToInputs(currentPayload, maxLength, canEdit);
    queueExtendedAutoSave();
});

$(document).on('input', '#extended-logo-url', function () {
    $('#extended-logo-data').val('');
    setExtendedLogoPreview($(this).val(), $('#extended-logo-enabled').is(':checked'));
});

$(document).on('click', '#extended-logo-upload-btn', function () {
    if ($(this).prop('disabled')) return;
    const fileInput = $('#extended-logo-upload');
    if (!fileInput.length) return;
    fileInput.val('');
    fileInput.trigger('click');
});

$(document).on('change', '#extended-logo-upload', function () {
    const input = this;
    if (!input || !input.files || input.files.length === 0) return;

    const file = input.files[0];
    if (file.size > (12 * 1024 * 1024)) {
        setExtendedStatus(
            getExtendedTranslation('extended_logo_upload_error', 'Unable to process logo image.'),
            'error',
            { notify: true }
        );
        input.value = '';
        return;
    }
    const uploadBtn = $('#extended-logo-upload-btn');
    const previousLabel = uploadBtn.text();
    uploadBtn.prop('disabled', true);
    uploadBtn.text(getExtendedTranslation('extended_logo_uploading', 'Compressing...'));

    compressExtendedLogoFile(file).then(function (dataUrl) {
        const normalizedDataUrl = normalizeExtendedLogoSource(dataUrl, EXTENDED_DEFAULT_LOGO_SOURCE);
        if (!isExtendedLogoDataUri(normalizedDataUrl)) {
            throw new Error('invalid_logo_data');
        }

        $('#extended-logo-data').val(normalizedDataUrl);
        $('#extended-logo-url').val('');
        setExtendedLogoPreview(normalizedDataUrl, $('#extended-logo-enabled').is(':checked'));
        queueExtendedAutoSave();
    }).catch(function () {
        setExtendedStatus(
            getExtendedTranslation('extended_logo_upload_error', 'Unable to process logo image.'),
            'error',
            { notify: true }
        );
    }).finally(function () {
        uploadBtn.prop('disabled', false);
        uploadBtn.text(previousLabel || getExtendedTranslation('extended_logo_upload_btn', 'Upload logo'));
        input.value = '';
    });
});

$(document).on('click', '#extended-logo-reset-btn', function () {
    if ($(this).prop('disabled')) return;
    $('#extended-logo-data').val('');
    $('#extended-logo-url').val('');
    setExtendedLogoPreview(EXTENDED_DEFAULT_LOGO_SOURCE, $('#extended-logo-enabled').is(':checked'));
    queueExtendedAutoSave();
});

$(document).on('click', '.sidebar-item[data-section="settings-wardrobe"]', function () {
    initializeSettingsWardrobe();
});

const ADMIN_SCROLL_CONTAINERS_SELECTOR = '#tab-edit .create-form, #tab-edit #houses-list-view .manage-houses-list-container, #tab-agency .card.card-content, #tab-settings .card.card-content, #tab-shells .card.card-content, #tab-create #section-create-main > .create-settings-list, #tab-extended .card.card-content, #tab-agency .card.card-sidebar .sidebar-menu, #tab-settings .card.card-sidebar .sidebar-menu, #tab-shells .card.card-sidebar .sidebar-menu, #tab-extended .card.card-sidebar .sidebar-menu';
const adminScrollVisibilityTimers = new WeakMap();
const adminLastScrollTop = new WeakMap();

function clearAdminContainerScrolling(element) {
    if (!element) {
        return;
    }

    const existingTimer = adminScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
        adminScrollVisibilityTimers.delete(element);
    }

    $(element).removeClass('is-scrolling');
}

function markAdminContainerScrolling(element) {
    if (!element) {
        return;
    }

    const maxScrollTop = Math.max(0, (element.scrollHeight || 0) - (element.clientHeight || 0));
    const scrollTop = Math.max(0, Math.min(element.scrollTop || 0, maxScrollTop));
    const previousTop = adminLastScrollTop.has(element) ? adminLastScrollTop.get(element) : null;
    adminLastScrollTop.set(element, scrollTop);

    if (maxScrollTop <= 0) {
        clearAdminContainerScrolling(element);
        return;
    }

    const atEdge = scrollTop <= 0 || scrollTop >= (maxScrollTop - 1);
    if (previousTop !== null && atEdge && Math.abs(scrollTop - previousTop) < 0.5) {
        clearAdminContainerScrolling(element);
        return;
    }

    const $element = $(element);
    $element.addClass('is-scrolling');

    const existingTimer = adminScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
    }

    const hideTimer = setTimeout(function () {
        $element.removeClass('is-scrolling');
        adminScrollVisibilityTimers.delete(element);
    }, 220);

    adminScrollVisibilityTimers.set(element, hideTimer);
}

function shouldBlockAdminEdgeWheel(element, deltaY) {
    if (!element || !Number.isFinite(deltaY) || deltaY === 0) {
        return false;
    }

    const maxScrollTop = Math.max(0, (element.scrollHeight || 0) - (element.clientHeight || 0));
    const scrollTop = Math.max(0, Math.min(element.scrollTop || 0, maxScrollTop));
    if (maxScrollTop <= 0) {
        return true;
    }

    const pushingUpAtTop = deltaY < 0 && scrollTop <= 0;
    const pushingDownAtBottom = deltaY > 0 && scrollTop >= (maxScrollTop - 1);
    return pushingUpAtTop || pushingDownAtBottom;
}

function bindAdminScrollVisibility() {
    $(ADMIN_SCROLL_CONTAINERS_SELECTOR).each(function () {
        if (this.dataset.scrollVisibilityBound === '1') return;
        this.dataset.scrollVisibilityBound = '1';
        this.classList.add('nh-scroll-managed');
        this.classList.add('admin-scroll');

        const element = this;
        adminLastScrollTop.set(element, element.scrollTop || 0);
        element.addEventListener('scroll', function () {
            markAdminContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('mouseleave', function () {
            clearAdminContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('touchend', function () {
            clearAdminContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('wheel', function (event) {
            const deltaY = typeof event.deltaY === 'number' ? event.deltaY : 0;
            if (shouldBlockAdminEdgeWheel(element, deltaY)) {
                clearAdminContainerScrolling(element);
                event.preventDefault();
                event.stopPropagation();
                return;
            }
            markAdminContainerScrolling(element);
        }, { passive: false });
    });
}

$(document).ready(function () {
    bindAdminScrollVisibility();
});

$(document).on(
    'wheel',
    ADMIN_SCROLL_CONTAINERS_SELECTOR,
    function (e) {
        e.stopPropagation();
    }
);

$(document).on(
    'wheel',
    '#tab-edit #houses-list-view .manage-houses-list-container',
    function (e) {
        e.stopPropagation();
    }
);

$(document).on(
    'wheel',
    '#tab-edit #houses-list-view .manage-list-main-content',
    function (e) {
        const container = this.querySelector('.manage-houses-list-container');
        if (!container || container.contains(e.target)) return;

        const originalEvent = e.originalEvent;
        if (!originalEvent) return;

        container.scrollTop += originalEvent.deltaY || 0;
        e.preventDefault();
        e.stopPropagation();
    }
);

$(document).on('click', '#btn-scan', function () {
    $.post('https://next_housing/scan', JSON.stringify({}))
});



function GetCoords() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "house" }))
}

function GetCoordsH() {
    if (window.nhGaragesEnabled !== true) {
        return;
    }
    $.post('https://next_housing/coords', JSON.stringify({ type: "garage" }))
}

function GetCoordsEntrance() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "entrance" }))
}

function GetCoordsGarageManage() {
    if (window.nhGaragesEnabled !== true) {
        return;
    }
    $.post('https://next_housing/coords', JSON.stringify({ type: "garage-manage" }))
}

function GetCoordsStashSettings() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "stash-settings" }))
}

function GetCoordsWardrobeSettings() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "wardrobe-settings" }))
}



function Reset() {
    $('#statuschange').prop('checked', false);
    $('#player').val('');
    $('#money').val('');
    $('#housex').val('');
    $('#housey').val('');
    $('#housez').val('');
    $('#garagex').val('');
    $('#garagey').val('');
    $('#garagez').val('');
    $('#garageh').val('');
    $('#interior-select').val('1');
    $('#givebuilderkey').prop('checked', true);
    $('#belongstoagency').prop('checked', false);

    StatusChange();
}

function Finish() {
    const checked = $('#statuschange').is(':checked');
    const ID = $('#player').val();
    const money = $('#money').val();
    const housex = $('#housex').val();
    const housey = $('#housey').val();
    const housez = $('#housez').val();

    const garagesEnabled = window.nhGaragesEnabled === true;
    const garagex = garagesEnabled ? $('#garagex').val() : '';
    const garagey = garagesEnabled ? $('#garagey').val() : '';
    const garagez = garagesEnabled ? $('#garagez').val() : '';
    const garageh = garagesEnabled ? $('#garageh').val() : '';

    const interior = $('#interior-select').val();
    const givebuilderkey = $('#givebuilderkey').is(':checked');
    const belongstoagency = $('#belongstoagency').is(':checked');

    if (!housex || !housey || !housez || housex.trim() === '' || housey.trim() === '' || housez.trim() === '') {
        $.post('https://next_housing/validationError', JSON.stringify({
            message: (translations && translations.house_coords_required) ? translations.house_coords_required : undefined
        }));
        return;
    }

    if (!checked && (!money || money.trim() === '' || isNaN(parseFloat(money)) || parseFloat(money) < 0)) {
        $.post('https://next_housing/validationError', JSON.stringify({
            message: (translations && translations.house_price_required) ? translations.house_price_required : undefined
        }));
        return;
    }

    if (checked && (!ID || ID.trim() === '' || isNaN(parseInt(ID)) || parseInt(ID) <= 0)) {
        $.post('https://next_housing/validationError', JSON.stringify({
            message: (translations && translations.player_id_invalid) ? translations.player_id_invalid : undefined
        }));
        return;
    }

    $("#container").removeClass('show');
    $("#preview-container").hide();

    $.post('https://next_housing/datas', JSON.stringify({
        isplayer: checked,
        player: ID,
        money: checked ? 0 : money,
        house: { x: housex, y: housey, z: housez },
        garage: { x: garagex, y: garagey, z: garagez, h: garageh },
        interior: interior,
        givebuilderkey: givebuilderkey,
        belongstoagency: belongstoagency
    }));

    $.post('http://next_housing/exit', JSON.stringify({}));

    $('#statuschange').prop('checked', false);
    $('#player').val('');
    $('#money').val('');
    $('#housex').val('');
    $('#housey').val('');
    $('#housez').val('');
    $('#garagex').val('');
    $('#garagey').val('');
    $('#garagez').val('');
    $('#garageh').val('');
    $('#interior-select').val('1');
    $('#givebuilderkey').prop('checked', true);
    $('#belongstoagency').prop('checked', false);
    StatusChange();
}

function StatusChange() {
    const checked = $('#statuschange').is(':checked');
    const assignHint = $('#assign-player-hint');
    if (checked) {
        $("#player2").show();
        $("#money2").hide();
        if (assignHint.length) assignHint.hide();
    } else {
        $("#player2").hide();
        $("#money2").show();
        if (assignHint.length) assignHint.show();
    }
}



function Preview() {
    const interiorVal = $('#interior-select').val();
    const imageurl = getInteriorImageUrl(interiorVal);
    loadPreviewImage(imageurl);
}

function Preview2() {
    const interiorVal = $('#interior-change').val();
    const imageurl = getInteriorImageUrl(interiorVal);
    loadPreviewImage(imageurl);

    triggerAutoSaveManage();
}

function Close() {
    $("#preview-container").hide();
}

function CancelInteriorChange() {
    $("#preview-container").hide();
}

function InteriorChange() {
    $("#preview-container").hide();

    const interior = $('#interior-change').val();
    const houseid = $('#houseid').text();

    window.initialInterior = interior;
    window.currentInterior = interior;

    if (window.initialValues) {
        window.initialValues.interior = interior;
    }

    const interiorName = getInteriorName(interior);
    $("#interiornow").text(interiorName);

    $.post('https://next_housing/interior', JSON.stringify({
        id: houseid,
        interior: interior
    }));
}



let savedMenuState = null;

function saveMenuState() {
    const isMenuVisible = $("#container").hasClass('show');
    if (isMenuVisible) {
        const activeTab = $(".tab-btn.active").data('tab') || 'edit';

        savedMenuState = {
            wasOpen: true,
            activeTab: activeTab
        };
    } else {
        savedMenuState = {
            wasOpen: false,
            activeTab: null
        };
    }
}

function restoreMenuState() {
    if (savedMenuState && savedMenuState.wasOpen) {
        setTimeout(function () {
            $("#nui-background").show();
            $("#container").addClass('show');
            activateTab(savedMenuState.activeTab);

            if (savedMenuState.activeTab === 'edit') {
                beginManageScan({
                    keepCurrentInfo: true,
                    suppressLoading: true,
                    fallbackToEmpty: false
                });
            }

            savedMenuState = null;
        }, 200);
    }
}

function launchInteriorVisit(interiorVal) {
    const coords = getInteriorPreviewCoords(interiorVal);

    if (!coords) {
        const interiorName = getInteriorName(interiorVal);
        const message = translations.visit_3d_not_available
            ? translations.visit_3d_not_available.replace('%s', interiorName)
            : "La visite 3D n'est pas encore disponible pour " + interiorName + ".";
        $.post('https://next_housing/notify', JSON.stringify({
            message: message,
            type: "error",
            duration: 3000
        }));
        return;
    }

    saveMenuState();
    $.post('http://next_housing/exit', JSON.stringify({}));

    setTimeout(function () {
        $.post('https://next_housing/visitInterior', JSON.stringify({
            interior: interiorVal,
            coords: coords
        }));
    }, 200);
}

function VisitInterior() {
    const interiorVal = $('#interior-change').val();
    launchInteriorVisit(interiorVal);
}

function VisitInteriorCreate() {
    const interiorVal = $('#interior-select').val();
    launchInteriorVisit(interiorVal);
}



function parseManageModalResponse(response, fallbackMessage) {
    let payload = response;
    if (typeof payload === 'string') {
        try {
            payload = JSON.parse(payload);
        } catch (_) {
            payload = null;
        }
    }

    if (payload && typeof payload === 'object') {
        if (Object.prototype.hasOwnProperty.call(payload, 'success')) {
            return payload;
        }

        if (Object.prototype.hasOwnProperty.call(payload, 'status')) {
            return {
                success: payload.status === true,
                message: payload.message
            };
        }
    }

    if (response === true || response === 'ok') {
        return { success: true };
    }

    return {
        success: false,
        message: fallbackMessage || (translations.update_error)
    };
}

function showManageModalMessage(message, title) {
    const resolvedMessage = message || (translations.update_error);
    const resolvedTitle = title || (translations.job_modal_error || translations.confirm);
    const safeMessage = $('<div>').text(resolvedMessage).html().replace(/\n/g, '<br>');

    window.ModalManager.open({
        title: resolvedTitle,
        stack: true,
        containerClass: 'multimodal-message-modal',
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${safeMessage}
            </div>
        `,
        buttons: [
            {
                text: translations.job_modal_ok || translations.close,
                class: 'pap-btn primary multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ]
    });
}

function getManageCancelLabel() {
    return translations.cancel || translations.job_modal_cancel_btn;
}

function DeleteHouse() {
    const houseid = $('#houseid').text();

    window.ModalManager.open({
        title: translations.confirm,
        containerClass: 'multimodal-message-modal',
        autoCancelButton: true,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${translations.delete_confirm_msg}
            </div>
        `,
        buttons: [
            {
                text: translations.delete_yes,
                class: 'pap-btn danger multimodal-action-btn',
                onClick: function () {
                    $.post('https://next_housing/delete', JSON.stringify({
                        id: houseid
                    }));
                    window.ModalManager.close();
                    setTimeout(function () {
                        CloseMenu();
                    }, 100);
                }
            }
        ]
    });
}

function LockStatus() {
    const houseid = $('#houseid').text();
    if (!houseid) {
        return;
    }

    $.post('https://next_housing/lock', JSON.stringify({
        id: houseid
    }))
}

function EditOwner() {
    const houseid = $('#houseid').text();
    if (!houseid) {
        return;
    }

    window.currentEditOwnerHouseId = houseid;
    const ownerLabel = translations.new_owner_identifier;
    const ownerPlaceholder = translations.enter_identifier;
    const confirmLabel = translations.confirm;

    window.ModalManager.open({
        title: translations.edit_owner,
        containerClass: 'agency-contract-modal manage-edit-modal',
        integrateFooterInMainBlock: true,
        footerClass: 'agency-contract-footer',
        mainBlockHeader: {
            title: translations.edit_owner,
            target: '.manage-edit-main-block'
        },
        bodyHTML: `
            <div class="agency-modal-main-block agency-contract-create-modal manage-edit-main-block">
                <div class="pap-form-group agency-contract-field">
                    <label for="new-owner-identifier" class="pap-form-label">${ownerLabel}</label>
                    <input type="text" id="new-owner-identifier" class="pap-form-input agency-contract-control" placeholder="${ownerPlaceholder}" />
                </div>
            </div>
        `,
        buttons: [
            {
                text: confirmLabel,
                class: 'pap-btn secondary agency-contract-btn multimodal-action-btn',
                onClick: function () {
                    ConfirmEditOwner();
                }
            },
            {
                text: getManageCancelLabel(),
                class: 'pap-btn secondary agency-contract-btn multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function ($modal) {
            const $identifierInput = $modal.find('#new-owner-identifier');
            $identifierInput.trigger('focus');
            $identifierInput.on('keydown', function (event) {
                if (event.key !== 'Enter') return;
                event.preventDefault();
                ConfirmEditOwner();
            });
        },
        onClose: function () {
            window.currentEditOwnerHouseId = null;
        }
    });
}
function ConfirmEditOwner() {
    const houseid = window.currentEditOwnerHouseId;
    const $identifierInput = $('#new-owner-identifier');
    const newIdentifier = String($identifierInput.val() || '').trim();

    if (!houseid) {
        return;
    }

    if (!newIdentifier) {
        showManageModalMessage(
            translations.enter_identifier,
            translations.edit_owner
        );
        $identifierInput.trigger('focus');
        return;
    }

    $.post('https://next_housing/updateOwner', JSON.stringify({
        id: houseid,
        identifier: newIdentifier
    }), function (response) {
        const result = parseManageModalResponse(response, translations.owner_update_error);
        if (result.success === true) {
            window.ModalManager.close();
            return;
        }

        showManageModalMessage(
            result.message || (translations.owner_update_error),
            translations.edit_owner
        );
    }).fail(function () {
        showManageModalMessage(
            translations.owner_update_error,
            translations.edit_owner
        );
    });
}
function EditPrice() {
    const houseid = $('#houseid').text();
    if (!houseid) {
        return;
    }

    const currentPrice = $('#price_display').text().replace(/[^0-9]/g, '');
    window.currentEditPriceHouseId = houseid;
    const priceLabel = translations.new_price;
    const pricePlaceholder = translations.enter_price;
    const confirmLabel = translations.confirm;

    window.ModalManager.open({
        title: translations.edit_price,
        containerClass: 'agency-contract-modal manage-edit-modal',
        integrateFooterInMainBlock: true,
        footerClass: 'agency-contract-footer',
        mainBlockHeader: {
            title: translations.edit_price,
            target: '.manage-edit-main-block'
        },
        bodyHTML: `
            <div class="agency-modal-main-block agency-contract-create-modal manage-edit-main-block">
                <div class="pap-form-group agency-contract-field">
                    <label for="new-price" class="pap-form-label">${priceLabel}</label>
                    <input type="number" id="new-price" class="pap-form-input agency-contract-control" placeholder="${pricePlaceholder}" value="${currentPrice || ''}" min="0" />
                </div>
            </div>
        `,
        buttons: [
            {
                text: confirmLabel,
                class: 'pap-btn secondary agency-contract-btn multimodal-action-btn',
                onClick: function () {
                    ConfirmEditPrice();
                }
            },
            {
                text: getManageCancelLabel(),
                class: 'pap-btn secondary agency-contract-btn multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function ($modal) {
            const $priceInput = $modal.find('#new-price');
            $priceInput.trigger('focus');
            $priceInput.on('keydown', function (event) {
                if (event.key !== 'Enter') return;
                event.preventDefault();
                ConfirmEditPrice();
            });
        },
        onClose: function () {
            window.currentEditPriceHouseId = null;
        }
    });
}
function ConfirmEditPrice() {
    const houseid = window.currentEditPriceHouseId;
    const $priceInput = $('#new-price');
    const newPriceRaw = String($priceInput.val() || '').trim();
    const parsedPrice = Number(newPriceRaw);

    if (!houseid) {
        return;
    }

    if (!newPriceRaw || !Number.isFinite(parsedPrice) || parsedPrice < 0) {
        showManageModalMessage(
            translations.job_error_invalid_price || translations.invalid_price || translations.house_price_required,
            translations.edit_price
        );
        $priceInput.trigger('focus');
        return;
    }

    $.post('https://next_housing/updatePrice', JSON.stringify({
        id: houseid,
        price: parsedPrice
    }), function (response) {
        const result = parseManageModalResponse(response, translations.update_error);
        if (result.success === true) {
            window.ModalManager.close();
            return;
        }

        showManageModalMessage(
            result.message || (translations.update_error),
            translations.edit_price
        );
    }).fail(function () {
        showManageModalMessage(
            translations.update_error,
            translations.edit_price
        );
    });
}

let resetMarketConfirmCallback = null;

function ResetHouseToMarket() {
    const houseid = parseInt($('#houseid').text(), 10);

    if (!houseid || Number.isNaN(houseid) || houseid <= 0) {
        return;
    }

    const confirmText = translations.reset_house_market_confirm;
    const confirmTitle = translations.confirm;

    window.ModalManager.open({
        title: confirmTitle,
        containerClass: 'multimodal-message-modal',
        autoCancelButton: true,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">${confirmText}</div>
        `,
        buttons: [
            {
                text: translations.confirm,
                class: 'pap-btn danger multimodal-action-btn',
                onClick: function () {
                    if (resetMarketConfirmCallback) {
                        resetMarketConfirmCallback(true);
                        resetMarketConfirmCallback = null;
                    }
                    window.ModalManager.close();
                }
            }
        ],
        onClose: function () {
            if (resetMarketConfirmCallback) {
                resetMarketConfirmCallback(false);
                resetMarketConfirmCallback = null;
            }
        }
    });

    resetMarketConfirmCallback = function (confirmed) {
        if (confirmed) {
            $.post('https://next_housing/resetHouseToMarket', JSON.stringify({
                id: houseid
            }), function (response) {
                let result = response;
                if (typeof response === 'string') {
                    try {
                        result = JSON.parse(response);
                    } catch (e) {
                        result = { success: false, message: translations.house_reset_error };
                    }
                }
                if (result && result.success) {
                } else if (result && result.message) {
                    alert(result.message);
                }
            }).fail(function (xhr, status, error) {
                alert(translations.house_reset_error);
            });
        }
    };
}



function ResetChanges() {
    if (!window.initialValues) {
        return;
    }

    $('#interior-change').val(window.initialValues.interior);
    window.currentInterior = window.initialValues.interior;
    const interiorName = getInteriorName(window.initialValues.interior);
    $("#interiornow").text(interiorName);

    $("#entrancex").val(window.initialValues.entranceX || '');
    $("#entrancey").val(window.initialValues.entranceY || '');
    $("#entrancez").val(window.initialValues.entranceZ || '');

    $("#garagex-manage").val(window.initialValues.garageX || '');
    $("#garagey-manage").val(window.initialValues.garageY || '');
    $("#garagez-manage").val(window.initialValues.garageZ || '');
    $("#garageh-manage").val(window.initialValues.garageH || '');

    if (typeof window.triggerAutoSaveManage === 'function') {
        window.triggerAutoSaveManage();
    }
}


$(document).on('keydown', function (e) {
    if (e.key === 'Escape') {
    }
});



function loadAllHouses() {
    const loading = $('#manage-houses-loading');
    const emptyState = $('#manage-houses-empty');
    const housesList = $('#manage-houses-list');
    const requestToken = ++manageHousesRequestToken;
    const hadExistingData = typeof allHousesData !== 'undefined'
        && Array.isArray(allHousesData)
        && allHousesData.length > 0;

    if (typeof allHousesData === 'undefined') {
        allHousesData = [];
    }

    if (manageHousesActiveRequest && typeof manageHousesActiveRequest.abort === 'function') {
        try {
            manageHousesActiveRequest.abort();
        } catch (_) {
        }
    }

    if (hadExistingData) {
        loading.hide();
        emptyState.hide();
        housesList.show();
    } else {
        loading.show();
        emptyState.hide();
        housesList.hide();
        housesList.empty();
    }

    manageHousesLoadingInProgress = true;

    if (typeof refreshHousePreviewPlaceholdersSetting === 'function') {
        refreshHousePreviewPlaceholdersSetting(function (changed) {
            if (changed && typeof listModeActive !== 'undefined' && listModeActive && typeof renderManageHousesList === 'function') {
                renderManageHousesList();
            }
        });
    }

    manageHousesActiveRequest = $.post('https://next_housing/getAllHouses', JSON.stringify({}), function (resp) {
        if (requestToken !== manageHousesRequestToken) {
            return;
        }

        manageHousesActiveRequest = null;

        try {
            if (!resp) {
                manageHousesLoadingInProgress = false;
                loading.hide();
                if (!hadExistingData) {
                    allHousesData = [];
                }
                renderManageHousesList();
                return;
            }

            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            allHousesData = Array.isArray(data)
                ? data.map(function (house) {
                    return normalizeManageHouseRecord(house);
                })
                : [];
            manageHousesLoadingInProgress = false;
            loading.hide();
            renderManageHousesList();
        } catch (e) {
            manageHousesLoadingInProgress = false;
            if (!hadExistingData) {
                allHousesData = [];
            }
            loading.hide();
            renderManageHousesList();
        }
    }).fail(function (xhr, status, error) {
        if (requestToken !== manageHousesRequestToken || status === 'abort') {
            return;
        }

        manageHousesActiveRequest = null;
        manageHousesLoadingInProgress = false;
        if (!hadExistingData) {
            allHousesData = [];
        }
        loading.hide();
        renderManageHousesList();
    });
}

window.cancelManageHousesPendingRequest = function () {
    if (manageHousesActiveRequest && typeof manageHousesActiveRequest.abort === 'function') {
        try {
            manageHousesActiveRequest.abort();
        } catch (_) {
        }
    }

    if (manageHousesLoadingInProgress === true || manageHousesActiveRequest) {
        manageHousesRequestToken += 1;
    }

    manageHousesActiveRequest = null;
    manageHousesLoadingInProgress = false;
    $('#manage-houses-loading').hide();
};

function getManageHouseValue(house, keys, fallbackValue) {
    if (!house || !Array.isArray(keys)) {
        return fallbackValue;
    }

    for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (house[key] !== undefined && house[key] !== null) {
            return house[key];
        }
    }

    return fallbackValue;
}

function normalizeManageHouseImages(imagesValue) {
    if (Array.isArray(imagesValue)) {
        return imagesValue.filter(function (image) {
            return typeof image === 'string' && image.trim() !== '';
        });
    }

    if (typeof imagesValue === 'string') {
        const trimmedValue = imagesValue.trim();
        if (trimmedValue === '') {
            return [];
        }

        try {
            const decodedImages = JSON.parse(trimmedValue);
            if (Array.isArray(decodedImages)) {
                return decodedImages.filter(function (image) {
                    return typeof image === 'string' && image.trim() !== '';
                });
            }
        } catch (_) {
        }

        return [trimmedValue];
    }

    return [];
}

function normalizeManageHouseRecord(house) {
    const sourceHouse = house && typeof house === 'object' ? house : {};
    const normalizedHouse = Object.assign({}, sourceHouse);
    const normalizedImages = normalizeManageHouseImages(sourceHouse.images);
    const lockedValue = getManageHouseValue(sourceHouse, ['locked', 'isLocked', 'is_locked'], false);
    const buyableValue = getManageHouseValue(sourceHouse, ['buyable', 'isBuyable', 'is_buyable'], false);
    const agencyValue = getManageHouseValue(sourceHouse, ['belongs_to_agency', 'belongsToAgency'], false);

    normalizedHouse.bidentifier = getManageHouseValue(sourceHouse, ['bidentifier', 'builderIdentifier'], '');
    normalizedHouse.bname = getManageHouseValue(sourceHouse, ['bname', 'builderName'], '');
    normalizedHouse.oidentifier = getManageHouseValue(sourceHouse, ['oidentifier', 'ownerIdentifier'], null);
    normalizedHouse.oname = getManageHouseValue(sourceHouse, ['oname', 'ownerName'], null);
    normalizedHouse.hcoords = getManageHouseValue(sourceHouse, ['hcoords', 'coords', 'house_coords'], { x: 0, y: 0, z: 0 });
    normalizedHouse.gcoords = getManageHouseValue(sourceHouse, ['gcoords', 'garageCoords', 'garage_coords'], { x: 0, y: 0, z: 0 });
    normalizedHouse.scoords = getManageHouseValue(sourceHouse, ['scoords', 'stashCoords', 'stash_coords'], null);
    normalizedHouse.locked = lockedValue === true || lockedValue === 1;
    normalizedHouse.buyable = buyableValue === true || buyableValue === 1;
    normalizedHouse.belongs_to_agency = agencyValue === true || agencyValue === 1;
    normalizedHouse.images = normalizedImages;

    return normalizedHouse;
}

window.normalizeManageHouseRecord = normalizeManageHouseRecord;

function showManageHouseInfo(house) {
    house = normalizeManageHouseRecord(house);

    const houseData = {
        id: house.id,
        name: house.name || null,
        builderIdentifier: house.bidentifier || "",
        builderName: house.bname || getTranslation('job_modal_unknown'),
        ownerIdentifier: house.oidentifier || null,
        ownerName: house.oname || null,
        coords: house.hcoords || { x: 0, y: 0, z: 0 },
        garageCoords: house.gcoords || { x: 0, y: 0, z: 0 },
        stashCoords: house.scoords || null,
        zoneName: house.zoneName || getTranslation('job_house_unknown_zone'),
        hasGarage: !!(house.gcoords && house.gcoords.x && house.gcoords.y),
        interior: house.interior || 1,
        isLocked: house.locked || false,
        isBuyable: house.buyable || false,
        price: house.price || 0,
        status: house.oidentifier ? getTranslation('job_house_sold') : getTranslation('job_house_available'),
        images: house.images || [],
        canManageMedia: true,
        isReadOnly: false,
        belongsToAgency: house.belongs_to_agency === true || house.belongs_to_agency === 1,
        canRent: house.canRent === true,
        canBuy: house.canBuy === true || !house.oidentifier
    };

    if (typeof showHouseDetails === 'function') {
        showHouseDetails(houseData);
    } else {
        const houseNumber = getTranslationWithFallbacks(['job_house_number', 'house_number'], 'Property #');
        const houseTypeLabel = getTranslationWithFallbacks(['job_house_type', 'house_type'], 'Type');
        const ownerLabel = getTranslationWithFallbacks(['owner', 'job_modal_owner'], 'Owner');
        const priceLabel = getTranslationWithFallbacks(['price', 'job_house_price'], 'Price');
        const noneText = getTranslationWithFallbacks(['none', 'job_house_no_owner'], 'None');
        const notDefinedText = getTranslationWithFallbacks(['not_defined', 'job_house_not_defined'], 'Not defined');

        alert(houseNumber + house.id + '\n' +
            houseTypeLabel + ': ' + getHouseTypeFromInterior(house.interior) + '\n' +
            ownerLabel + ': ' + (house.oname || noneText) + '\n' +
            priceLabel + ': ' + (house.price ? formatPrice(house.price) : notDefinedText));
    }
}

function teleportToHouse(house) {
    house = normalizeManageHouseRecord(house);

    const getErrorMsg = function () {
        return getTranslationWithFallbacks(['invalid_coords_house', 'invalid_coords'], 'Invalid coordinates for this property');
    };

    if (!house || !house.id) {

        alert(getErrorMsg());
        return;
    }

    if (!house.hcoords) {
        alert(getErrorMsg());
        return;
    }

    const x = parseFloat(house.hcoords.x);
    const y = parseFloat(house.hcoords.y);
    const z = parseFloat(house.hcoords.z) || 0;

    if (isNaN(x) || isNaN(y) || !isFinite(x) || !isFinite(y)) {
        alert(getErrorMsg());
        return;
    }

    $.post('https://next_housing/teleportToHouse', JSON.stringify({
        houseId: house.id,
        x: x,
        y: y,
        z: z
    })).fail(function () {

    });
}



window.addEventListener('message', function (event) {
    if (event.data.type === 'housesUpdated' && listModeActive) {
        if (window.nhManageSkipNextReloadUntil && Date.now() < window.nhManageSkipNextReloadUntil) {
            return;
        }
        loadAllHouses();
    }
});

window.addEventListener('message', function (event) {
    if (event.data.type === "showJobInterface") {
    } else if (event.data.type === "hideJobInterface" || event.data.type === "closeJobInterface") {
    }
});


window.currentShellEdit = null;

function ShellGetBaseCoords() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "shell-base" }));
}

function ShellGetEntryCoordsEdit() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "shell-entry-edit" }));
}

function ShellGetStashCoordsEdit() {
    $.post('https://next_housing/coords', JSON.stringify({ type: "shell-stash-edit" }));
}

function CreateShell() {
    const name = $('#shell-name-create').val();
    const model = $('#shell-model-create').val();
    const ipl = $('#shell-ipl-create').val();

    const bx = $('#shell-base-x').val();
    const by = $('#shell-base-y').val();
    const bz = $('#shell-base-z').val();

    if (!name || name.trim() === '') {
        alert(getTranslation('fill_all_fields'));
        return;
    }

    $.post('https://next_housing/createShell', JSON.stringify({
        name: name,
        model: model,
        ipl: ipl,
        base: { x: bx, y: by, z: bz }
    }), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.success) {
                $('#shell-name-create').val('');
                $('#shell-model-create').val('');
                $('#shell-ipl-create').val('');
                $('#shell-base-x').val('');
                $('#shell-base-y').val('');
                $('#shell-base-z').val('');

                if (typeof initializeShellsSidebar === 'function') initializeShellsSidebar();
                if (typeof activateSection === 'function') activateSection('shells-list');
            } else {
                alert(data.message || getTranslation('error_creating_shell'));
            }
        } catch (e) { }
    });
}

function openShellEdit(shell) {
    if (!shell) return;
    window.currentShellEdit = shell.id;

    $('#shell-name-edit').val(shell.name);
    $('#shell-model-edit').val(shell.model || '');
    $('#shell-ipl-edit').val(shell.ipl || '');

    if (shell.entry) {
        $('#shell-entry-x-edit').val(shell.entry.x);
        $('#shell-entry-y-edit').val(shell.entry.y);
        $('#shell-entry-z-edit').val(shell.entry.z);
    } else {
        $('#shell-entry-x-edit').val('');
        $('#shell-entry-y-edit').val('');
        $('#shell-entry-z-edit').val('');
    }

    if (shell.stash) {
        $('#shell-stash-x-edit').val(shell.stash.x);
        $('#shell-stash-y-edit').val(shell.stash.y);
        $('#shell-stash-z-edit').val(shell.stash.z);
    } else {
        $('#shell-stash-x-edit').val('');
        $('#shell-stash-y-edit').val('');
        $('#shell-stash-z-edit').val('');
    }

    $('#shells-save-btn').hide();
    $('#shells-save-edit-btn').show();
    $('#shells-cancel-btn').show();
    $('#shells-action-row').show();

    if (typeof activateSection === 'function') {
        $('.sidebar-item[data-section="shells-edit"]').show();
        activateSection('shells-edit');
    }
}

function CancelShellEdit() {
    window.currentShellEdit = null;
    $('#shells-save-edit-btn').hide();
    $('#shells-cancel-btn').hide();
    $('#shells-save-btn').show();

    if (typeof activateSection === 'function') {
        activateSection('shells-list');
        $('.sidebar-item[data-section="shells-edit"]').hide();
    }
}

function SaveShellEdit() {
    if (!window.currentShellEdit) return;

    const name = $('#shell-name-edit').val();
    const model = $('#shell-model-edit').val();
    const ipl = $('#shell-ipl-edit').val();

    const ex = $('#shell-entry-x-edit').val();
    const ey = $('#shell-entry-y-edit').val();
    const ez = $('#shell-entry-z-edit').val();

    const sx = $('#shell-stash-x-edit').val();
    const sy = $('#shell-stash-y-edit').val();
    const sz = $('#shell-stash-z-edit').val();

    $.post('https://next_housing/updateShell', JSON.stringify({
        id: window.currentShellEdit,
        name: name,
        model: model,
        ipl: ipl,
        entry: { x: ex, y: ey, z: ez },
        stash: { x: sx, y: sy, z: sz }
    }), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.success) {
                CancelShellEdit();
                if (typeof initializeShellsSidebar === 'function') initializeShellsSidebar();
            } else {
                alert(data.message || getTranslation('error_updating_shell'));
            }
        } catch (e) { }
    });
}



