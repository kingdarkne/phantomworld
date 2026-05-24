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
function nhResolveResourceName() {
    try {
        if (typeof window.GetParentResourceName === 'function') {
            const nativeName = String(window.GetParentResourceName() || '').trim();
            if (nativeName !== '') {
                return nativeName;
            }
        }
    } catch (_) {
    }

    const hostName = String((window.location && window.location.hostname) || '').trim();
    if (hostName.startsWith('cfx-nui-')) {
        const stripped = hostName.slice('cfx-nui-'.length).trim();
        if (stripped !== '') {
            return stripped;
        }
    }

    if (hostName !== '' && hostName !== 'nui-game-internal' && hostName !== 'localhost' && hostName !== '127.0.0.1') {
        return hostName;
    }

    return 'next_housing';
}


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

let housesData = [];
let filteredHouses = [];
let contractsData = [];
let unpaidData = [];
let houseAgencyContractTypes = {};
let filteredContracts = [];
let selectedHouseForContract = null;
let currentHouseSearch = '';
let currentHouseFilter = 'all';
let suppressHousesFadeUntil = 0;
let hasRenderedContracts = false;
let hasRenderedUnpaid = false;
let hasRenderedTreasury = false;
let openContractDrawerType = null;
let openContractId = null;
let inlineEditingContractKey = null;
let inlineContractSaveInProgress = false;
let pendingDrawerOpenAnimationType = null;
let pendingContractOpenAnimationKey = null;
let housesRenderToken = 0;
let housesRenderChunkTimer = null;
let housesRenderChunkRaf = null;
let pendingJobHousesRefreshTimer = null;
const CONTRACT_NAME_MAX_LENGTH = 40;
const CONTRACT_TILE_TITLE_MAX_LENGTH = 26;
const HOUSE_RENDER_CHUNK_SIZE = 28;
const HOUSE_RENDER_SYNC_THRESHOLD = 48;
const HOUSE_FILTER_KEYS = {
    all: 'job_filter_all',
    vacant: 'job_filter_vacant',
    agency: 'job_filter_agency',
    sold: 'job_filter_sold'
};
const HOUSE_FILTER_DEFAULT_LABELS = {
    all: 'Tous les logements',
    vacant: 'Proprietes vacantes',
    agency: 'Proprietes de l\'agence',
    sold: 'Autres (deja achetees)'
};

let confirmCallback = null;
let isModalOpen = false;
let housePreviewPlaceholdersEnabled = true;
let housePreviewPlaceholdersEnabledLoaded = false;
let currentHouseDetailsModalData = null;
const houseImageRequests = {};
const pendingHouseMediaOverrides = {};
const HOUSE_MEDIA_OVERRIDE_TTL_MS = 15000;
const JOB_SCROLL_CONTAINERS_SELECTOR = '#job-tab-houses .houses-list-container';
const jobScrollVisibilityTimers = new WeakMap();
const jobLastScrollTop = new WeakMap();
const JOB_DEFAULT_COMMAND = 'realestate';

if (typeof window.translations === 'undefined') {
    window.translations = {};
}
if (typeof window.currentLocale === 'undefined') {
    window.currentLocale = 'en';
}

function clearJobContainerScrolling(element) {
    if (!element) {
        return;
    }

    const existingTimer = jobScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
        jobScrollVisibilityTimers.delete(element);
    }

    $(element).removeClass('is-scrolling');
}

function markJobContainerScrolling(element) {
    if (!element) {
        return;
    }

    const maxScrollTop = Math.max(0, (element.scrollHeight || 0) - (element.clientHeight || 0));
    const scrollTop = Math.max(0, Math.min(element.scrollTop || 0, maxScrollTop));
    const previousTop = jobLastScrollTop.has(element) ? jobLastScrollTop.get(element) : null;
    jobLastScrollTop.set(element, scrollTop);

    if (maxScrollTop <= 0) {
        clearJobContainerScrolling(element);
        return;
    }

    const atEdge = scrollTop <= 0 || scrollTop >= (maxScrollTop - 1);
    if (previousTop !== null && atEdge && Math.abs(scrollTop - previousTop) < 0.5) {
        clearJobContainerScrolling(element);
        return;
    }

    const $element = $(element);
    $element.addClass('is-scrolling');

    const existingTimer = jobScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
    }

    const hideTimer = setTimeout(function () {
        $element.removeClass('is-scrolling');
        jobScrollVisibilityTimers.delete(element);
    }, 220);

    jobScrollVisibilityTimers.set(element, hideTimer);
}

function shouldBlockJobEdgeWheel(element, deltaY) {
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

function bindJobScrollVisibility() {
    $(JOB_SCROLL_CONTAINERS_SELECTOR).each(function () {
        if (this.dataset.jobScrollVisibilityBound === '1') return;
        this.dataset.jobScrollVisibilityBound = '1';
        this.classList.add('nh-scroll-managed');
        this.classList.add('job-scroll');

        const element = this;
        jobLastScrollTop.set(element, element.scrollTop || 0);
        element.addEventListener('scroll', function () {
            markJobContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('mouseleave', function () {
            clearJobContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('touchend', function () {
            clearJobContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('wheel', function (event) {
            const deltaY = typeof event.deltaY === 'number' ? event.deltaY : 0;
            if (shouldBlockJobEdgeWheel(element, deltaY)) {
                clearJobContainerScrolling(element);
                event.preventDefault();
                event.stopPropagation();
                return;
            }
            markJobContainerScrolling(element);
        }, { passive: false });
    });
}

function normalizeCommandHint(command, fallbackCommand) {
    const fallback = String(fallbackCommand || '').trim().replace(/^\/+/, '') || 'command';
    const normalized = String(command || '').trim().replace(/^\/+/, '');
    return '/' + (normalized || fallback);
}

function updateJobCommandHint(rawCommand) {
    const commandHint = $('#job-command-hint');
    if (!commandHint.length) {
        return;
    }
    commandHint.text(normalizeCommandHint(rawCommand, JOB_DEFAULT_COMMAND));
}






function showJobAlert(message, title) {
    title = title || (window.translations.job_modal_info);

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    let escapedMessage = escapeHtml(message);
    let formattedMessage = escapedMessage.replace(/\n/g, '<br>');
    formattedMessage = formattedMessage.replace(/(https?:\/\/[^\s]+)/g, '<a href="$1" target="_blank" class="compression-tool-link" style="color: var(--accent); text-decoration: underline;">$1</a>');

    window.ModalManager.open({
        title: title,
        containerClass: 'multimodal-message-modal',
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${formattedMessage}
            </div>
        `,
        buttons: [
            {
                text: window.translations.job_modal_close,
                class: 'pap-btn primary multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ]
    });
}

function showJobConfirm(message, title, callback) {
    return showJobConfirmWithOptions(message, title, callback, {});
}

function showJobConfirmWithOptions(message, title, callback, options) {
    options = options || {};
    title = title || (window.translations.job_modal_confirmation);
    const safeMessage = $('<div>').text(message || '').html().replace(/\n/g, '<br>');
    const containerClass = ['multimodal-message-modal', options.containerClass].filter(Boolean).join(' ');

    let handled = false;
    window.ModalManager.open({
        title: title,
        stack: options.stack === true,
        containerClass: containerClass,
        autoCancelButton: true,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${safeMessage}
            </div>
        `,
        buttons: [
            {
                text: window.translations.confirm,
                class: 'pap-btn primary multimodal-action-btn',
                onClick: function () {
                    handled = true;
                    if (callback) callback(true);
                    window.ModalManager.close();
                }
            }
        ],
        onClose: function () {
            if (!handled && callback) {
                callback(false);
            }
        }
    });
}



window.closeHouseDetailsModal = closeHouseDetailsModal;

window.closeModal = function () { window.ModalManager.close(); };








$(document).on('keydown', function (e) {
    if (e.key === 'Escape') {
        if ($('#image-lightbox').length && !$('#image-lightbox').hasClass('hidden')) {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            return;
        }

        if ($('#player-contract-interface').length && !$('#player-contract-interface').hasClass('hidden')) {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            if (typeof declineContractOnClose === 'function') {
                declineContractOnClose();
            }
            return;
        }

        if (window.ModalManager && window.ModalManager.isOpen) {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            window.ModalManager.close();
            return;
        }

        if ($('#job-interface').length && !$('#job-interface').hasClass('hidden')) {
            if (typeof isModalOpen !== 'undefined' && !isModalOpen) {
                if (typeof closeInterface === 'function') {
                    e.preventDefault();
                    e.stopPropagation();
                    if (typeof e.stopImmediatePropagation === 'function') {
                        e.stopImmediatePropagation();
                    }
                    closeInterface();
                }
            }
        }
    }
});

$(document).ready(function () {
    jobLoadCurrencySymbol();

    initializeInterface();
    setupEventListeners();
    bindJobScrollVisibility();

    window.addEventListener('message', function (event) {
        const data = event.data;
        if (!data || typeof data !== 'object') {
            return;
        }

        if (data && data.currencySymbol !== undefined && data.currencySymbol !== null) {
            const normalizedSymbol = String(data.currencySymbol).trim();
            window.currencySymbol = normalizedSymbol !== '' ? normalizedSymbol : '$';
            window.currencySymbolLoaded = true;
        }

        if (data.type === 'languageChanged') {
            if (data.translations) {
                window.translations = data.translations;
                window.currentLocale = data.locale || 'en';
                translateJobInterface();
            }
            return;
        }

        if (data.translations) {
            window.translations = data.translations;
            window.currentLocale = data.locale || 'en';
            translateJobInterface();
        }

        if (data.type === 'housePreviewPlaceholdersSettingChanged') {
            applyHousePreviewPlaceholdersSetting(data.enabled, true);
            filterHouses(false);

            if (currentHouseDetailsModalData) {
                renderHouseImages(currentHouseDetailsModalData.images || [], currentHouseDetailsModalData);
            }
            return;
        }

        if (data.type === 'openJobInterface' || data.type === 'showJobInterface') {
            if (data && data.housePreviewPlaceholdersEnabledLoaded === true) {
                applyHousePreviewPlaceholdersSetting(data.housePreviewPlaceholdersEnabled, true);
            } else {
                applyHousePreviewPlaceholdersSetting(data && data.housePreviewPlaceholdersEnabled, false);
            }

            updateJobCommandHint(data.jobCommand);
            const incomingHouses = Array.isArray(data.houses) ? data.houses : [];
            applyPendingHouseMediaOverrides(incomingHouses);
            openInterface(incomingHouses, data.extended || null);
            setTimeout(function () {
                translateJobInterface();
            }, 100);
        } else if (data.type === 'jobCommandChanged') {
            updateJobCommandHint(data.jobCommand);
        } else if (data.type === 'updateHouses') {
            const incomingHouses = Array.isArray(data.houses) ? data.houses : [];
            applyPendingHouseMediaOverrides(incomingHouses);
            housesData = normalizeHousesPayload(incomingHouses);
            filterHouses();
            if (typeof window.nhJobMapOnHousesUpdated === 'function') {
                window.nhJobMapOnHousesUpdated(housesData);
            }
        } else if (data.type === 'updateContracts') {
            contractsData = data.contracts || [];
            rebuildHouseAgencyContractTypes();
            $('#contracts-loading').addClass('hidden');
            filterContracts();
            hasRenderedContracts = true;
            if ($('#job-tab-houses').hasClass('active')) {
                renderHouses(false);
            }
        } else if (data.type === 'updateUnpaid') {
            unpaidData = Array.isArray(data.unpaid) ? data.unpaid : [];
            renderUnpaid(unpaidData);
            hasRenderedUnpaid = true;
            $('#contracts-loading').addClass('hidden');
            if ($('#job-tab-contracts').hasClass('active')) {
                renderContracts();
            }
        } else if (data.type === 'updateTreasury') {
            const balance = parseFloat(data.balance) || 0;
            if (jobShouldLoadCurrencySymbol()) {
                jobLoadCurrencySymbol();
            }
            $('#treasury-balance').text(formatPrice(balance));

            const salesCount = parseInt(data.sales, 10) || 0;
            const rentsCount = parseInt(data.rents, 10) || 0;

            $('#treasury-sales-count').text(salesCount);
            $('#treasury-rents-count').text(rentsCount);

            $('#treasury-loading').addClass('hidden');
            hasRenderedTreasury = true;

            checkTreasuryWithdrawAccess();
        } else if (data.type === 'withdrawTreasuryResult') {
            const $btn = $('#treasury-withdraw-btn');

            if (data.success) {
                $('#treasury-withdraw-amount').val('');
                refreshTreasury();
            } else {
                
            }

            const withdrawText = window.translations.job_treasury_withdraw_btn;
            $btn.prop('disabled', false).html('<span class="btn-icon">&#10003;</span><span class="btn-text">' + withdrawText + '</span>');
        } else if (data.type === 'showContract') {
            displayContractToPlayer(data.contract);
        } else if (data.type === 'contractSigned') {
            if (!$('#job-interface').hasClass('hidden')) {
                refreshHouses();
                if ($('#job-tab-contracts').hasClass('active')) {
                    refreshContracts();
                }
            }
        } else if (data.type === 'closeContractInterface') {
            closePlayerContractInterface(
                typeof data.keepJobFocus === 'boolean' ? data.keepJobFocus : undefined,
                true
            );
        } else if (data.type === 'closeJobInterface' || data.type === 'hideJobInterface') {
            closeInterface();
        }

        if (data.extended && typeof window.nhJobMapUpdateExtendedState === 'function') {
            window.nhJobMapUpdateExtendedState(data.extended);
        }
    });
});

function initializeInterface() {
    const jobInterface = $('#job-interface');
    if (jobInterface.length) {
        jobInterface.addClass('hidden');
    }
}

function setupEventListeners() {
    $('#job-close-btn').on('click', function () {
        closeInterface();
    });

    $(document).on('click', '.compression-tool-link', function (e) {
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
    });

    $(document).on('click', '.edit-house-title-btn', function (e) {
        e.stopPropagation();
        const house = $('#dynamic-global-modal').data('house');
        if (!canManageHouseMedia(house)) {
            return;
        }
        const $container = $(this).closest('.house-title-container');
        const $header = $container.closest('.pap-main-block-header');
        const $headerTitle = $header.find('h3').first();
        const $input = $container.find('.house-title-input');
        const $modalBody = $container.closest('.pap-modal-body');
        const previousScrollTop = $modalBody.length ? $modalBody.scrollTop() : null;
        const currentTitle = ($headerTitle.text() || '').trim();

        if (currentTitle) {
            $input.val(currentTitle);
            $input.data('original-title', currentTitle);
        }

        $header.addClass('is-editing');
        $headerTitle.addClass('house-title-editing');
        $input.removeClass('hidden');
        $container.find('.edit-house-title-btn').addClass('hidden');
        $container.find('.upload-house-title-btn').addClass('hidden');
        $container.find('.save-house-title-btn').removeClass('hidden');
        $container.find('.cancel-house-title-btn').removeClass('hidden');

        const inputEl = $input.get(0);
        if (inputEl) {
            try {
                inputEl.focus({ preventScroll: true });
            } catch (_) {
                inputEl.focus();
            }
            if (typeof inputEl.select === 'function') {
                inputEl.select();
            }
        }

        if (previousScrollTop !== null) {
            window.requestAnimationFrame(function () {
                $modalBody.scrollTop(previousScrollTop);
            });
        }
    });

    $(document).on('click', '.upload-house-title-btn', function (e) {
        e.preventDefault();
        e.stopPropagation();
        if (typeof e.stopImmediatePropagation === 'function') {
            e.stopImmediatePropagation();
        }
        const house = $('#dynamic-global-modal').data('house');
        if (!canManageHouseMedia(house)) {
            return;
        }
        uploadHouseImage($(this));
    });

    $(document).on('click', '.cancel-house-title-btn', function (e) {
        e.stopPropagation();
        const house = $('#dynamic-global-modal').data('house');
        const canManageMedia = canManageHouseMedia(house);
        const $container = $(this).closest('.house-title-container');
        const $header = $container.closest('.pap-main-block-header');
        const $headerTitle = $header.find('h3').first();
        const $input = $container.find('.house-title-input');
        const originalTitle = ($input.data('original-title') || $headerTitle.text() || '').toString().trim();

        if (originalTitle) {
            $headerTitle.text(originalTitle);
            $input.val(originalTitle);
        }

        $header.removeClass('is-editing');
        $headerTitle.removeClass('house-title-editing');
        $input.addClass('hidden');
        if (canManageMedia) {
            $container.find('.edit-house-title-btn').removeClass('hidden');
            $container.find('.upload-house-title-btn').removeClass('hidden');
        } else {
            $container.find('.edit-house-title-btn').addClass('hidden');
            $container.find('.upload-house-title-btn').addClass('hidden');
        }
        $container.find('.save-house-title-btn').addClass('hidden');
        $container.find('.cancel-house-title-btn').addClass('hidden');
    });

    $(document).on('click', '.save-house-title-btn', function (e) {
        e.stopPropagation();
        const house = $('#dynamic-global-modal').data('house');
        if (!canManageHouseMedia(house)) {
            return;
        }
        const $container = $(this).closest('.house-title-container');
        const $header = $container.closest('.pap-main-block-header');
        const $headerTitle = $header.find('h3').first();
        const $input = $container.find('.house-title-input');
        const houseId = $container.find('.house-title-input').data('house-id');
        const newHouseName = $input.val().trim().toUpperCase();

        $input.val(newHouseName);

        if (!newHouseName) {
            showJobAlert(window.translations.job_error_name_empty, window.translations.job_error_error);
            return;
        }
        
        const isPapMode = house && house.isPapProperty === true;
        const callbackName = isPapMode ? 'papUpdateHouseName' : 'updateHouseName';

        $.post(`http://next_housing/${callbackName}`, JSON.stringify({
            houseId: houseId,
            houseName: newHouseName,
            adminMode: window.nhIsAdmin === true
        }), function (response) {
            let result = response;
            if (typeof response === 'string') {
                try {
                    result = JSON.parse(response);
                } catch (error) {
                    console.error('[next_housing] updateHouseName invalid JSON response:', error, response);
                    showJobAlert(window.translations.job_error_update_failed, window.translations.job_error_error);
                    return;
                }
            }

            if (result.success) {
                $header.removeClass('is-editing');
                $headerTitle.text(newHouseName).removeClass('house-title-editing');
                $input.val(newHouseName).data('original-title', newHouseName).addClass('hidden');
                $container.find('.edit-house-title-btn').removeClass('hidden');
                $container.find('.upload-house-title-btn').removeClass('hidden');
                $container.find('.save-house-title-btn').addClass('hidden');
                $container.find('.cancel-house-title-btn').addClass('hidden');
                $container
                    .closest('.pap-modal')
                    .find('.pap-main-block-header h3')
                    .first()
                    .text(newHouseName);
                $container
                    .closest('.pap-modal')
                    .find('#dynamic-modal-hint')
                    .first()
                    .text(newHouseName);

                if (house) {
                    house.name = newHouseName;
                }
                syncHouseNameLocally(houseId, newHouseName);

                refreshAfterHouseMediaOrTitleUpdate(isPapMode, house);
            } else {
                showJobAlert(result.message || (window.translations.job_error_update_failed), window.translations.job_error_error);
            }
        }).fail(function () {
            showJobAlert(window.translations.job_error_connection, window.translations.job_error_error);
        });
    });

    $(document).on('keydown', '.house-title-input', function (e) {
        if (e.key === 'Enter') {
            $(this).closest('.house-title-container').find('.save-house-title-btn').click();
        } else if (e.key === 'Escape') {
            $(this).closest('.house-title-container').find('.cancel-house-title-btn').click();
        }
    });

    $('.job-tab-btn[data-tab]').on('click', function () {
        const tabName = $(this).data('tab');
        if (!tabName) {
            return;
        }
        switchTab(tabName);
        saveToLocalStorage('next_housing_job_activeTab', tabName);
    });

    $('#contract-type').on('change', function () {
        const type = $(this).val();
        if (type === 'rent') {
            $('#contract-duration-group').show();
        } else {
            $('#contract-duration-group').hide();
        }
        translateCreateContractModal();
    });

    $('#create-contract-btn').on('click', function () {
        createContract();
    });

    $('#update-contract-btn').on('click', function () {
        updateContract();
    });

    $('#clear-signature-icon').on('click', function (e) {
        e.stopPropagation();
        clearSignature();
    });


    $('#treasury-withdraw-btn').on('click', function () {
        withdrawTreasury();
    });

    $('#refresh-current-tab-btn').on('click', function () {
        refreshCurrentTab();
    });

    $(document).on('click', '.job-house-filter-btn', function () {
        const filterValue = $(this).data('filter');
        setCurrentHouseFilter(filterValue, true);
    });

    $('#house-filter-type').on('change', function () {
        setCurrentHouseFilter($(this).val(), true);
    });

    $('#house-search-input').on('input', function () {
        currentHouseSearch = ($(this).val() || '').toString();
        renderHouses();
    });
}

function parseHousePreviewSetting(value, fallback) {
    if (typeof value === 'boolean') {
        return value;
    }
    if (typeof value === 'number') {
        return value === 1;
    }
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === '1' || normalized === 'true' || normalized === 'yes' || normalized === 'on') {
            return true;
        }
        if (normalized === '0' || normalized === 'false' || normalized === 'no' || normalized === 'off') {
            return false;
        }
    }
    return fallback;
}

function applyHousePreviewPlaceholdersSetting(enabled, loaded) {
    housePreviewPlaceholdersEnabled = parseHousePreviewSetting(enabled, housePreviewPlaceholdersEnabled);
    housePreviewPlaceholdersEnabledLoaded = loaded === true;
}

function canUseHousePreviewPlaceholders() {
    return housePreviewPlaceholdersEnabledLoaded === true && housePreviewPlaceholdersEnabled === true;
}

window.nhSetHousePreviewPlaceholdersSetting = function (enabled, loaded) {
    applyHousePreviewPlaceholdersSetting(enabled, loaded);
};

function resolveInteriorPreviewImagePath(interiorVal) {
    const interior = String(interiorVal);
    const interiorNum = parseInt(interiorVal, 10);

    if (!Number.isFinite(interiorNum) || interiorNum <= 0) {
        return null;
    }

    if (interiorNum >= 47 && interiorNum <= 70) {
        const apartmentNames = {
            '47': 'modern', '48': 'modern', '49': 'modern',
            '50': 'mody', '51': 'mody', '52': 'mody',
            '53': 'vibrant', '54': 'vibrant', '55': 'vibrant',
            '56': 'sharp', '57': 'sharp', '58': 'sharp',
            '59': 'monochrome', '60': 'monochrome', '61': 'monochrome',
            '62': 'seductive', '63': 'seductive', '64': 'seductive',
            '65': 'regal', '66': 'regal', '67': 'regal',
            '68': 'aqua', '69': 'aqua', '70': 'aqua'
        };
        const apartmentName = apartmentNames[interior];
        return apartmentName ? `./images/${apartmentName}.jpg` : `./images/${interior}.jpg`;
    }

    if (interiorNum >= 11 && interiorNum <= 46) {
        const officeStyles = {
            '11': 'executive-rich', '20': 'executive-rich', '29': 'executive-rich', '38': 'executive-rich',
            '12': 'executive-cool', '21': 'executive-cool', '30': 'executive-cool', '39': 'executive-cool',
            '13': 'executive-contrast', '22': 'executive-contrast', '31': 'executive-contrast', '40': 'executive-contrast',
            '14': 'old-spice-warm', '23': 'old-spice-warm', '32': 'old-spice-warm', '41': 'old-spice-warm',
            '15': 'old-spice-classical', '24': 'old-spice-classical', '33': 'old-spice-classical', '42': 'old-spice-classical',
            '16': 'old-spice-vintage', '25': 'old-spice-vintage', '34': 'old-spice-vintage', '43': 'old-spice-vintage',
            '17': 'power-broker-ice', '26': 'power-broker-ice', '35': 'power-broker-ice', '44': 'power-broker-ice',
            '18': 'power-broker-conservative', '27': 'power-broker-conservative', '36': 'power-broker-conservative', '45': 'power-broker-conservative',
            '19': 'power-broker-polished', '28': 'power-broker-polished', '37': 'power-broker-polished', '46': 'power-broker-polished'
        };
        const officeStyle = officeStyles[interior];
        return officeStyle ? `./images/${officeStyle}.jpg` : `./images/${interior}.jpg`;
    }

    return `./images/${interior}.jpg`;
}

function getHouseInteriorPreviewImage(house) {
    if (!house || house.interior === undefined || house.interior === null) {
        return null;
    }

    return resolveInteriorPreviewImagePath(house.interior);
}

function getHouseCardImageSource(house) {
    if (house && Array.isArray(house.images) && house.images.length > 0 && house.images[0]) {
        return house.images[0];
    }

    if (canUseHousePreviewPlaceholders()) {
        return getHouseInteriorPreviewImage(house);
    }

    return null;
}

function normalizeHouseImagesState(house) {
    if (!house || typeof house !== 'object') {
        return house;
    }

    if (!Array.isArray(house.images)) {
        house.images = [];
    }

    if (house.imagesLoaded !== true) {
        house.imagesLoaded = house.images.length > 0;
    }

    return house;
}

function normalizeHousesPayload(houses) {
    if (!Array.isArray(houses)) {
        return [];
    }

    for (let i = 0; i < houses.length; i += 1) {
        normalizeHouseImagesState(houses[i]);
    }

    return houses;
}

function parseNuiPayload(rawPayload) {
    if (typeof rawPayload === 'string') {
        try {
            return JSON.parse(rawPayload);
        } catch (_) {
            return {};
        }
    }

    if (rawPayload && typeof rawPayload === 'object') {
        return rawPayload;
    }

    return {};
}

function syncHouseImagesLocally(houseId, images) {
    const numericId = parseInt(houseId, 10);
    if (!Number.isFinite(numericId)) {
        return;
    }

    const safeImages = Array.isArray(images) ? images : [];

    const applyImages = function (house) {
        if (!house || parseInt(house.id, 10) !== numericId) {
            return false;
        }

        house.images = [...safeImages];
        house.imagesLoaded = true;
        return true;
    };

    if (Array.isArray(housesData)) {
        for (let i = 0; i < housesData.length; i += 1) {
            if (applyImages(housesData[i])) {
                break;
            }
        }
    }

    if (Array.isArray(filteredHouses)) {
        for (let i = 0; i < filteredHouses.length; i += 1) {
            if (applyImages(filteredHouses[i])) {
                break;
            }
        }
    }

    if (currentHouseDetailsModalData && parseInt(currentHouseDetailsModalData.id, 10) === numericId) {
        currentHouseDetailsModalData.images = [...safeImages];
        currentHouseDetailsModalData.imagesLoaded = true;
    }

    pendingHouseMediaOverrides[String(numericId)] = {
        images: [...safeImages],
        expiresAt: Date.now() + HOUSE_MEDIA_OVERRIDE_TTL_MS
    };
}

function syncHouseNameLocally(houseId, houseName) {
    const numericId = parseInt(houseId, 10);
    if (!Number.isFinite(numericId)) {
        return;
    }

    const safeName = houseName !== null && houseName !== undefined ? String(houseName) : '';

    const applyName = function (house) {
        if (!house || parseInt(house.id, 10) !== numericId) {
            return false;
        }

        house.name = safeName;
        return true;
    };

    if (Array.isArray(housesData)) {
        for (let i = 0; i < housesData.length; i += 1) {
            if (applyName(housesData[i])) {
                break;
            }
        }
    }

    if (Array.isArray(filteredHouses)) {
        for (let i = 0; i < filteredHouses.length; i += 1) {
            if (applyName(filteredHouses[i])) {
                break;
            }
        }
    }

    if (currentHouseDetailsModalData && parseInt(currentHouseDetailsModalData.id, 10) === numericId) {
        currentHouseDetailsModalData.name = safeName;
    }

    const key = String(numericId);
    const existingOverride = pendingHouseMediaOverrides[key] || {};
    pendingHouseMediaOverrides[key] = Object.assign({}, existingOverride, {
        name: safeName,
        expiresAt: Date.now() + HOUSE_MEDIA_OVERRIDE_TTL_MS
    });
}

function scheduleJobHousesRefresh(delayMs) {
    if (pendingJobHousesRefreshTimer) {
        clearTimeout(pendingJobHousesRefreshTimer);
        pendingJobHousesRefreshTimer = null;
    }

    const waitMs = Number.isFinite(delayMs) ? Math.max(0, delayMs) : 2000;
    pendingJobHousesRefreshTimer = setTimeout(function () {
        pendingJobHousesRefreshTimer = null;
        refreshHouses();
    }, waitMs);
}

function applyPendingHouseMediaOverrides(houses) {
    if (!Array.isArray(houses) || !houses.length) {
        return houses;
    }

    const now = Date.now();
    Object.keys(pendingHouseMediaOverrides).forEach(function (key) {
        const entry = pendingHouseMediaOverrides[key];
        if (!entry || !Number.isFinite(entry.expiresAt) || entry.expiresAt <= now) {
            delete pendingHouseMediaOverrides[key];
        }
    });

    for (let i = 0; i < houses.length; i += 1) {
        const house = houses[i];
        const houseId = parseInt(house && house.id, 10);
        if (!Number.isFinite(houseId)) {
            continue;
        }

        const override = pendingHouseMediaOverrides[String(houseId)];
        if (!override) {
            continue;
        }

        if (override.name !== undefined) {
            house.name = override.name;
        }

        if (Array.isArray(override.images)) {
            house.images = [...override.images];
            house.imagesLoaded = true;
        }
    }

    return houses;
}

function fetchHouseImagesForModal(house) {
    if (!house || typeof house !== 'object') {
        return;
    }

    normalizeHouseImagesState(house);

    const numericId = parseInt(house.id, 10);
    if (!Number.isFinite(numericId) || house.imagesLoaded === true) {
        return;
    }

    if (houseImageRequests[numericId]) {
        return;
    }

    houseImageRequests[numericId] = true;
    const resourceName = jobGetResourceName();
    $.post(`https://${resourceName}/getHouseImages`, JSON.stringify({ houseId: numericId }), function (response) {
        const payload = parseNuiPayload(response);
        if (!payload || payload.success !== true) {
            return;
        }

        const liveHouse = (typeof window.nhGetJobHouseById === 'function')
            ? window.nhGetJobHouseById(numericId)
            : house;
        if (liveHouse && liveHouse.imagesLoaded === true) {
            return;
        }

        const images = Array.isArray(payload.images) ? payload.images : [];
        syncHouseImagesLocally(numericId, images);

        if (currentHouseDetailsModalData && parseInt(currentHouseDetailsModalData.id, 10) === numericId) {
            renderHouseImages(images, currentHouseDetailsModalData);
        }
    }).always(function () {
        delete houseImageRequests[numericId];
    });
}

function refreshHousePreviewPlaceholdersSetting(callback) {
    const resourceName = jobGetResourceName();
    $.post(`https://${resourceName}/getHousePreviewPlaceholdersEnabled`, JSON.stringify({}), function (resp) {
        let nextValue = housePreviewPlaceholdersEnabled;
        try {
            const payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (payload && Object.prototype.hasOwnProperty.call(payload, 'enabled')) {
                nextValue = parseHousePreviewSetting(payload.enabled, housePreviewPlaceholdersEnabled);
            }
        } catch (_) {
        }

        const changed = nextValue !== housePreviewPlaceholdersEnabled || housePreviewPlaceholdersEnabledLoaded !== true;
        applyHousePreviewPlaceholdersSetting(nextValue, true);

        if (callback) {
            callback(changed);
        }
    }).fail(function () {
        if (callback) {
            callback(false);
        }
    });
}





function openInterface(houses, extendedState) {
    const mainContainer = $('#container');
    if (mainContainer) {
        mainContainer.removeClass('show');
    }
    $('#nui-background').hide();

    if (window.ModalManager) {
        window.ModalManager.close();
    }

    const jobInterface = $('#job-interface');
    if (jobInterface.length === 0) {
        console.error('[Next Housing] Interface job introuvable dans le DOM');
        return;
    }

    jobInterface.removeClass('hidden');
    jobInterface.css({
        'display': 'flex',
        'visibility': 'visible',
        'opacity': '1'
    });
    jobInterface.removeClass('job-open-anim');
    if (jobInterface[0]) {
        void jobInterface[0].offsetWidth;
    }
    jobInterface.addClass('job-open-anim');
    setTimeout(function () {
        jobInterface.removeClass('job-open-anim');
    }, 900);

    housesData = normalizeHousesPayload(houses || []);
    bindJobScrollVisibility();
    currentHouseSearch = '';
    suppressHousesFadeUntil = Date.now() + 700;
    inlineEditingContractKey = null;
    inlineContractSaveInProgress = false;
    pendingDrawerOpenAnimationType = null;
    pendingContractOpenAnimationKey = null;
    $('#house-search-input').val('');

    if (typeof window.nhJobMapOnInterfaceOpen === 'function') {
        window.nhJobMapOnInterfaceOpen({
            houses: housesData,
            extended: extendedState || null
        });
    }

    const restoredTab = restoreJobInterfaceState();



    translateJobInterface();

    setTimeout(function () {
        translateJobInterface();
        if (restoredTab !== 'treasury') {
            checkTreasuryWithdrawAccess();
        }
    }, 200);

    if (restoredTab !== 'contracts') {
        
        $.post('http://next_housing/getContracts', JSON.stringify({}));
    }

    if (housePreviewPlaceholdersEnabledLoaded !== true) {
        refreshHousePreviewPlaceholdersSetting(function (changed) {
            if (!changed) {
                return;
            }

            filterHouses(false);
            if (currentHouseDetailsModalData) {
                renderHouseImages(currentHouseDetailsModalData.images || [], currentHouseDetailsModalData);
            }
        });
    }
}

function closeInterface() {
    if (isModalOpen) {
        return;
    }

    cancelScheduledHouseRender();
    const jobInterface = $('#job-interface');
    jobInterface.removeClass('job-open-anim');
    jobInterface.addClass('hidden');
    jobInterface.css('display', 'none');
    $('#job-loading').addClass('hidden');
    housesData = [];
    filteredHouses = [];
    inlineEditingContractKey = null;
    inlineContractSaveInProgress = false;
    pendingDrawerOpenAnimationType = null;
    pendingContractOpenAnimationKey = null;

    if (typeof window.nhJobMapOnInterfaceClose === 'function') {
        window.nhJobMapOnInterfaceClose();
    }

    $.post('http://next_housing/closeJobInterface', JSON.stringify({}));
}

window.nhGetJobHouseById = function (houseId) {
    const numericId = parseInt(houseId, 10);
    if (!Number.isFinite(numericId) || !Array.isArray(housesData)) {
        return null;
    }

    for (let i = 0; i < housesData.length; i += 1) {
        const house = housesData[i];
        if (house && parseInt(house.id, 10) === numericId) {
            return house;
        }
    }

    return null;
};

window.nhOpenJobHouseDetails = function (houseId) {
    const house = window.nhGetJobHouseById(houseId);
    if (!house || typeof showHouseDetails !== 'function') {
        return false;
    }

    showHouseDetails(house);
    return true;
};











function resolveHousePlaceholderSource(svgPath) {
    const rawPath = (typeof svgPath === 'string' ? svgPath.trim() : '');
    if (rawPath === '' || /^ph:/i.test(rawPath)) {
        return '';
    }

    if (/^(?:https?:|data:|nui:)/i.test(rawPath)) {
        return rawPath;
    }

    let normalizedPath = rawPath.replace(/^\.?\//, '');
    if (!/^core\/ui\//i.test(normalizedPath)) {
        normalizedPath = `core/ui/${normalizedPath}`;
    }

    let resourceName = 'next_housing';
    try {
        if (typeof GetParentResourceName === 'function') {
            const candidate = GetParentResourceName();
            if (candidate && candidate.trim() !== '') {
                resourceName = candidate.trim();
            }
        }
    } catch (_) {
    }

    return `nui://${resourceName}/${normalizedPath}`;
}

const HOUSE_PLACEHOLDER_ICON_CLASS = 'ph ph-house-line';

function resolvePlaceholderIconClass(placeholderSpec) {
    const rawSpec = (typeof placeholderSpec === 'string' ? placeholderSpec.trim() : '');
    if (/^ph:/i.test(rawSpec)) {
        const iconName = rawSpec.slice(3).trim();
        if (iconName !== '') {
            return `ph ph-${iconName}`;
        }
    }
    return HOUSE_PLACEHOLDER_ICON_CLASS;
}

function createHouseIconPlaceholder(placeholderClass, placeholderSpec) {
    const placeholder = $('<div>').addClass(placeholderClass);
    const iconClass = resolvePlaceholderIconClass(placeholderSpec);
    placeholder.append($('<i>').addClass(iconClass).attr('aria-hidden', 'true'));
    return placeholder;
}

function createImagePlaceholder(svgPath, placeholderClass) {
    const primarySource = resolveHousePlaceholderSource(svgPath);
    if (!primarySource) {
        return createHouseIconPlaceholder(placeholderClass, svgPath);
    }

    const svgImg = $('<img>')
        .attr('src', primarySource)
        .attr('alt', 'Placeholder')
        .on('error', function () {
            const parent = $(this).parent();
            if (parent && parent.length) {
                parent.empty().append(
                    $('<i>')
                        .addClass(resolvePlaceholderIconClass(svgPath))
                        .attr('aria-hidden', 'true')
                );
            }
        });

    const placeholder = $('<div>').addClass(placeholderClass);
    placeholder.append(svgImg);
    return placeholder;
}










function createHeaderImageContainer(imageSrc, altText, containerClass, placeholderClass, placeholderSvg) {
    const headerImage = $('<div>').addClass(containerClass);

    if (imageSrc) {
        const img = $('<img>')
            .attr('src', imageSrc)
            .attr('alt', altText)
            .on('error', function () {
                $(this).hide();
                if (!headerImage.find('.' + placeholderClass).length) {
                    headerImage.append(createImagePlaceholder(placeholderSvg, placeholderClass));
                }
            });
        headerImage.append(img);
    } else {

        headerImage.append(createImagePlaceholder(placeholderSvg, placeholderClass));
    }

    return headerImage;
}





function cancelScheduledHouseRender() {
    housesRenderToken += 1;
    if (housesRenderChunkTimer) {
        clearTimeout(housesRenderChunkTimer);
        housesRenderChunkTimer = null;
    }
    if (housesRenderChunkRaf) {
        if (typeof window.cancelAnimationFrame === 'function') {
            window.cancelAnimationFrame(housesRenderChunkRaf);
        }
        housesRenderChunkRaf = null;
    }
}

function scheduleHouseRenderChunk(callback) {
    housesRenderChunkTimer = setTimeout(function () {
        housesRenderChunkTimer = null;
        if (typeof window.requestAnimationFrame === 'function') {
            housesRenderChunkRaf = window.requestAnimationFrame(function () {
                housesRenderChunkRaf = null;
                callback();
            });
            return;
        }
        callback();
    }, 0);
}

function captureHousesScrollState() {
    const candidates = [];
    const seen = new Set();
    const pushCandidate = function (element) {
        if (!element || seen.has(element)) {
            return;
        }
        seen.add(element);
        candidates.push(element);
    };

    const housesList = document.getElementById('houses-list');
    if (housesList && housesList.closest) {
        pushCandidate(housesList.closest('.houses-list-container'));
    }
    pushCandidate(document.querySelector('#job-tab-houses .houses-list-container'));
    pushCandidate(document.querySelector('.job-houses-main .houses-list-container'));

    return candidates.map(function (element) {
        return {
            element: element,
            scrollTop: element.scrollTop || 0
        };
    });
}

function restoreHousesScrollState(scrollState) {
    if (!Array.isArray(scrollState) || scrollState.length === 0) {
        return;
    }

    scrollState.forEach(function (entry) {
        if (!entry || !entry.element) {
            return;
        }

        const el = entry.element;
        const maxScrollTop = Math.max(0, (el.scrollHeight || 0) - (el.clientHeight || 0));
        const targetTop = Math.max(0, Math.min(entry.scrollTop || 0, maxScrollTop));
        el.scrollTop = targetTop;
    });
}

function restoreHousesScrollStateDeferred(scrollState) {
    restoreHousesScrollState(scrollState);

    if (typeof window.requestAnimationFrame === 'function') {
        window.requestAnimationFrame(function () {
            restoreHousesScrollState(scrollState);
        });
    }

    setTimeout(function () {
        restoreHousesScrollState(scrollState);
    }, 60);
}

function renderHouses(enableFadeAnimation = true) {
    const housesList = $('#houses-list');
    const loading = $('#job-loading');
    const emptyState = $('#job-empty-state');
    const searchQuery = (currentHouseSearch || '').trim().toLowerCase();
    const scrollState = captureHousesScrollState();

    cancelScheduledHouseRender();
    housesList.empty();
    loading.addClass('hidden');
    emptyState.addClass('hidden');
    housesList.removeClass('job-list-fade');
    if (enableFadeAnimation && housesList.length) {
        void housesList[0].offsetWidth;
    }
    if (enableFadeAnimation) {
        housesList.addClass('job-list-fade');
    }
    emptyState.removeClass('job-empty-fade');

    const housesToRender = searchQuery
        ? filteredHouses.filter(function (house) {
            const houseName = (house.name || '').toString().toLowerCase();
            const houseId = String(house.id || '').toLowerCase();
            const zoneName = (house.zoneName || '').toString().toLowerCase();
            const houseType = (getHouseType(house.interior) || '').toString().toLowerCase();
            return houseName.includes(searchQuery)
                || houseId.includes(searchQuery)
                || zoneName.includes(searchQuery)
                || houseType.includes(searchQuery);
        })
        : filteredHouses;

    if (housesToRender.length === 0) {
        let emptyMessage = window.translations.job_no_houses;

        if (searchQuery.length > 0) {
            emptyMessage = window.translations.job_empty_search;
        } else if (currentHouseFilter === 'vacant') {
            emptyMessage = window.translations.job_empty_vacant;
        } else if (currentHouseFilter === 'agency') {
            emptyMessage = window.translations.job_empty_agency;
        }

        emptyState.find('p').text(emptyMessage);
        if (enableFadeAnimation && emptyState.length) {
            void emptyState[0].offsetWidth;
        }
        if (enableFadeAnimation) {
            emptyState.addClass('job-empty-fade');
        }
        emptyState.removeClass('hidden');
        restoreHousesScrollStateDeferred(scrollState);
        return;
    }

    const reversedHouses = [...housesToRender].reverse();
    if (!housesList.length) {
        restoreHousesScrollStateDeferred(scrollState);
        return;
    }

    const listElement = housesList[0];
    const shouldRenderSync = reversedHouses.length <= HOUSE_RENDER_SYNC_THRESHOLD;
    if (shouldRenderSync) {
        const fragment = document.createDocumentFragment();
        reversedHouses.forEach(function (house) {
            const houseCard = createHouseCard(house);
            if (houseCard && houseCard.length > 0) {
                fragment.appendChild(houseCard[0]);
            }
        });
        listElement.appendChild(fragment);
        translateJobInterface();
        restoreHousesScrollStateDeferred(scrollState);
        return;
    }

    loading.removeClass('hidden');
    const renderToken = housesRenderToken;
    let index = 0;

    const renderChunk = function () {
        if (renderToken !== housesRenderToken) {
            return;
        }

        const endIndex = Math.min(index + HOUSE_RENDER_CHUNK_SIZE, reversedHouses.length);
        const fragment = document.createDocumentFragment();
        for (; index < endIndex; index += 1) {
            const houseCard = createHouseCard(reversedHouses[index]);
            if (houseCard && houseCard.length > 0) {
                fragment.appendChild(houseCard[0]);
            }
        }

        if (fragment.childNodes.length > 0) {
            listElement.appendChild(fragment);
        }

        if (index < reversedHouses.length) {
            scheduleHouseRenderChunk(renderChunk);
            return;
        }

        loading.addClass('hidden');
        translateJobInterface();
        restoreHousesScrollStateDeferred(scrollState);
    };

    renderChunk();
}

function houseHasOwner(house) {
    if (!house || typeof house !== 'object') {
        return false;
    }

    const rawOwner = house.ownerIdentifier;
    const normalizedOwner = rawOwner === null || rawOwner === undefined ? '' : String(rawOwner).trim();
    if (normalizedOwner === '') {
        return false;
    }

    const loweredOwner = normalizedOwner.toLowerCase();
    return loweredOwner !== 'null' && loweredOwner !== 'nil';
}

function canManageHouseMedia(house) {
    if (window.nhIsAdmin === true) {
        return true;
    }

    if (!house || typeof house !== 'object') {
        return false;
    }

    if (house.canManageMedia === true || house.canManageMedia === 1 || house.canManageMedia === '1') {
        return true;
    }

    if (house.canManageMedia === false || house.canManageMedia === 0 || house.canManageMedia === '0') {
        return false;
    }

    const isReadOnly = house.isReadOnly === true || house.isReadOnly === 1 || house.isReadOnly === '1';
    return !isReadOnly;
}

function createHouseCard(house) {
    const hasOwner = houseHasOwner(house);
    const status = hasOwner ? 'sold' : 'available';
    let statusText = hasOwner ? (window.translations.job_house_sold) : (window.translations.job_house_available);
    const agencyContractType = house.agencyContractType || houseAgencyContractTypes[String(house.id)];

    if (house.hasPapContract) {
        statusText = window.translations.job_house_pap_contract;
    } else if (agencyContractType === 'rent') {
        statusText = window.translations.job_house_agency;
    } else if (!hasOwner && house.belongsToAgency) {
        statusText = window.translations.job_house_agency;
    }

    const price = house.price ? formatPrice(house.price) : (window.translations.job_house_not_defined);
    const zoneName = house.zoneName || (window.translations.job_house_unknown_zone);
    const hasGarage = getGarageAvailabilityLabel(house.hasGarage);

    const card = $('<div>').addClass('house-card').addClass(status);

    if (house.hasPapContract) {
        card.addClass('pap-contract');
    }

    const firstImage = getHouseCardImageSource(house);
    const headerImage = createHeaderImageContainer(
        firstImage,
        (window.translations.job_house_number) + house.id,
        'house-header-image',
        'house-image-placeholder',
        'ph:house-line'
    );
    const houseTitle = house.name || ((window.translations.job_house_number) + house.id);
    const titleContainer = $('<div>').addClass('house-title-container');
    const headerTop = $('<div>').addClass('house-image-overlay-top');
    const statusBadge = $('<div>').addClass('house-status').text(statusText);

    if (house.coords && house.coords.x && house.coords.y) {
        const gpsIcon = $('<button>')
            .addClass('gps-icon-btn')
            .attr('title', window.translations.job_house_view_on_map)
            .html('<i class="ph ph-map-pin"></i>')
            .on('click', function (e) {
                e.stopPropagation();
                viewHouseOnMap(house.coords, house.id);
            });
        titleContainer.append(gpsIcon);
    }

    titleContainer.append($('<h4>').addClass('house-id').text(houseTitle));

    const info = $('<div>').addClass('house-info');
    const infoGrid = $('<div>').addClass('house-info-grid');

    const houseType = getHouseType(house.interior);
    infoGrid.append(createInfoItem(window.translations.job_house_type, houseType));
    infoGrid.append(createInfoItem(window.translations.job_house_location, zoneName));
    infoGrid.append(createInfoItem(window.translations.job_house_price, price));
    infoGrid.append(createInfoItem(window.translations.job_house_garage, hasGarage));

    info.append(infoGrid);
    const imageOverlay = $('<div>').addClass('house-image-overlay');
    imageOverlay.append(headerTop);
    imageOverlay.append(info);

    headerTop.append(titleContainer);
    headerTop.append(statusBadge);

    headerImage.append(imageOverlay);
    card.append(headerImage);

    const actions = $('<div>').addClass('house-actions');

    if (house.hasPapContract) {
        actions.append(createHouseActionNotice(window.translations.job_house_pap_managed));
    } else {
        if (hasOwner) {
            actions.append(createHouseActionNotice(getHouseOwnerNoticeText(house)));
        }

        if (!hasOwner && house.belongsToAgency) {
            actions.append(createHouseActionButton(
                window.translations.job_house_create_contract,
                'ph ph-signature',
                '',
                function (e) {
                    e.stopPropagation();
                    openCreateContractModal(house);
                }
            ));
        }

        if (!hasOwner && !house.belongsToAgency && house.canBuy) {
            actions.append(createHouseActionButton(
                window.translations.job_house_buy,
                'ph ph-shopping-cart',
                'buy-btn',
                function (e) {
                    e.stopPropagation();
                    openBuyHouseModal(house);
                }
            ));
        }
    }

    card.on('click', function (e) {
        if (!$(e.target).closest('button, .gps-icon-btn').length) {
            showHouseDetails(house);
        }
    });

    if (actions.children().length > 0) {
        card.append(actions);
    }

    return card;
}

function createHouseActionNotice(text) {
    const noticeText = String(text || '').trim();

    return $('<span>')
        .addClass('pap-contract-notice')
        .append($('<i>').addClass('ph ph-lock').attr('aria-hidden', 'true'))
        .append($('<span>').text(noticeText));
}
function createHouseActionButton(text, iconClass, extraClass, onClick) {
    const button = $('<button>').addClass('action-btn');

    if (extraClass) {
        button.addClass(extraClass);
    }

    button
        .append($('<i>').addClass(iconClass).attr('aria-hidden', 'true'))
        .append($('<span>').text(String(text || '').trim()))
        .on('click', onClick);

    return button;
}

function rebuildHouseAgencyContractTypes() {
    const bestByHouse = {};
    houseAgencyContractTypes = {};

    contractsData.forEach(function (contract) {
        const houseId = String(contract.houseId || '');
        if (!houseId) {
            return;
        }

        const status = String(contract.status || '').toLowerCase();
        const type = String(contract.type || '').toLowerCase();

        let priority = 99;
        if (status === 'active' && type === 'rent') {
            priority = 0;
        } else if (status === 'completed' && type === 'sale') {
            priority = 1;
        } else if (status === 'active' && type === 'sale') {
            priority = 2;
        } else if (status === 'completed' && type === 'rent') {
            priority = 3;
        } else {
            return;
        }

        const contractId = parseInt(contract.id, 10) || 0;
        const previous = bestByHouse[houseId];
        if (!previous || priority < previous.priority || (priority === previous.priority && contractId > previous.contractId)) {
            bestByHouse[houseId] = { type: type, priority: priority, contractId: contractId };
        }
    });

    Object.keys(bestByHouse).forEach(function (houseId) {
        houseAgencyContractTypes[houseId] = bestByHouse[houseId].type;
    });
}

function getHouseOwnerNoticeText(house) {
    const contractType = house.agencyContractType || houseAgencyContractTypes[String(house.id)];
    if (contractType === 'rent') {
        return window.translations.job_house_rented_to_private;
    }

    if (contractType === 'sale') {
        return window.translations.job_house_sold_to_private;
    }

    return window.translations.job_house_private_purchase;
}
function getHouseType(interior) {
    const interiorNum = parseInt(interior) || 0;

    if (interiorNum >= 1000) {
        return window.translations.job_house_type_shell;
    }

    
    if (interiorNum === 1 || interiorNum === 3) {
        return window.translations.job_house_type_studio;
    }
    
    else if (interiorNum === 6 || interiorNum === 7) {
        return window.translations.job_house_type_house;
    }
    
    else if ((interiorNum >= 2 && interiorNum <= 5) || (interiorNum >= 47 && interiorNum <= 70)) {
        return window.translations.job_house_type_apartment;
    }
    
    else if (interiorNum >= 11 && interiorNum <= 46) {
        return window.translations.job_house_type_office;
    }
    
    else {
        return window.translations.job_house_type_unknown;
    }
}

function createInfoItem(label, value) {
    const item = $('<div>').addClass('house-info-item');
    item.append($('<span>').addClass('house-info-label').text(label));
    item.append($('<span>').addClass('house-info-value').text(value));
    return item;
}

function getGarageAvailabilityLabel(hasGarage, options) {
    const opts = options && typeof options === 'object' ? options : {};

    if (window.nhGaragesEnabled === false) {
        return (window.translations && window.translations.pap_property_unavailable)
            || (window.translations && window.translations.not_defined)
            || 'Unavailable';
    }

    const yesKey = opts.yesKey || 'job_house_yes';
    const noKey = opts.noKey || 'job_house_no';
    const yesText = (window.translations && window.translations[yesKey])
        || (window.translations && window.translations.job_house_yes)
        || 'Yes';
    const noText = (window.translations && window.translations[noKey])
        || (window.translations && window.translations.job_house_no)
        || 'No';

    return hasGarage ? yesText : noText;
}

function getHouseFilterLabel(filterValue) {
    const key = HOUSE_FILTER_KEYS[filterValue] || HOUSE_FILTER_KEYS.all;
    if (window.translations && window.translations[key]) {
        return window.translations[key];
    }
    return HOUSE_FILTER_DEFAULT_LABELS[filterValue] || HOUSE_FILTER_DEFAULT_LABELS.all;
}

function syncHouseFilterUI() {
    const validHouseFilters = ['all', 'vacant', 'agency', 'sold'];
    if (!validHouseFilters.includes(currentHouseFilter)) {
        currentHouseFilter = 'all';
    }

    const houseFilterSelect = $('#house-filter-type');
    if (houseFilterSelect.length > 0 && houseFilterSelect.val() !== currentHouseFilter) {
        houseFilterSelect.val(currentHouseFilter);
    }

    $('.job-house-filter-btn').removeClass('active');
    $('.job-house-filter-btn[data-filter="' + currentHouseFilter + '"]').addClass('active');

    const titleElement = $('#job-houses-filter-title');
    if (titleElement.length > 0) {
        const key = HOUSE_FILTER_KEYS[currentHouseFilter] || HOUSE_FILTER_KEYS.all;
        titleElement.attr('data-translate', key);
        titleElement.text(getHouseFilterLabel(currentHouseFilter));
    }
}

function setCurrentHouseFilter(filterValue, shouldSave) {
    const validHouseFilters = ['all', 'vacant', 'agency', 'sold'];
    const normalizedFilter = validHouseFilters.includes(filterValue) ? filterValue : 'all';
    currentHouseFilter = normalizedFilter;
    filterHouses();
    if (shouldSave) {
        saveToLocalStorage('next_housing_job_houseFilter', currentHouseFilter);
    }
}





function filterHouses(enableFadeAnimation = true) {
    syncHouseFilterUI();

    const houseSearchInput = $('#house-search-input');
    if (houseSearchInput.length > 0) {
        houseSearchInput.attr('placeholder', window.translations.job_search_houses_placeholder);
    }

    filteredHouses = housesData.filter(function (house) {
        const hasOwner = houseHasOwner(house);
        const belongsToAgency = house.belongsToAgency === true || house.belongsToAgency === 1 || house.belongsToAgency === '1';
        const agencyContractType = String(house.agencyContractType || houseAgencyContractTypes[String(house.id)] || '').toLowerCase();
        const isAgencyRent = agencyContractType === 'rent';
        const isVacant = !hasOwner;

        switch (currentHouseFilter) {
            case 'vacant':
                return isVacant && !belongsToAgency;
            case 'agency':
                return belongsToAgency || isAgencyRent;
            case 'sold':
                return hasOwner && !belongsToAgency && !isAgencyRent;
            case 'all':
            default:
                return true;
        }
    });

    const shouldAnimateRender = enableFadeAnimation && Date.now() >= suppressHousesFadeUntil;
    renderHouses(shouldAnimateRender);
}





function refreshHouses() {
    $.post('http://next_housing/refreshHouses', JSON.stringify({}));
}

function syncManageHouseLocally(updatedHouse) {
    if (!updatedHouse || typeof updatedHouse !== 'object') {
        return false;
    }

    if (typeof allHousesData === 'undefined' || !Array.isArray(allHousesData) || allHousesData.length === 0) {
        return false;
    }

    let changed = false;

    allHousesData = allHousesData.map(function (house) {
        if (!house || house.id !== updatedHouse.id) {
            return house;
        }

        changed = true;
        return Object.assign({}, house, {
            name: updatedHouse.name !== undefined ? updatedHouse.name : house.name,
            images: Array.isArray(updatedHouse.images) ? [...updatedHouse.images] : house.images
        });
    });

    return changed;
}

function isJobInterfaceVisible() {
    const $jobInterface = $('#job-interface');
    if (!$jobInterface.length) {
        return false;
    }

    return !$jobInterface.hasClass('hidden') && $jobInterface.is(':visible');
}

function refreshAfterHouseMediaOrTitleUpdate(isPapMode, updatedHouse) {
    if (isPapMode && typeof papRefreshCurrentTab === 'function') {
        papRefreshCurrentTab();
        return;
    }

    if (isJobInterfaceVisible()) {
        suppressHousesFadeUntil = Date.now() + 700;
        filterHouses(false);
        scheduleJobHousesRefresh(2000);
        return;
    }

    const syncedManageHouse = syncManageHouseLocally(updatedHouse);
    if (typeof listModeActive !== 'undefined' && listModeActive && typeof renderManageHousesList === 'function') {
        if (syncedManageHouse || (typeof allHousesData !== 'undefined' && Array.isArray(allHousesData) && allHousesData.length > 0)) {
            if (typeof window.cancelManageHousesPendingRequest === 'function') {
                window.cancelManageHousesPendingRequest();
            }
            window.nhManageSkipNextReloadUntil = Date.now() + 2000;
            renderManageHousesList();
            return;
        }
    }

    if (typeof loadAllHouses === 'function') {
        loadAllHouses();
        return;
    }

    if (typeof loadAllHousesData === 'function') {
        loadAllHousesData();
    }
}

function escapeModalHtml(value) {
    if (value === null || value === undefined) return '';
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function renderUnpaid(unpaidList) {
    unpaidData = Array.isArray(unpaidList) ? unpaidList : [];

    const unpaidContainer = $('#unpaid-list');
    if (unpaidContainer.length === 0) {
        return;
    }
    unpaidContainer.empty();

    if (unpaidData.length === 0) {
        $('#unpaid-empty-state').removeClass('hidden');
        return;
    }

    $('#unpaid-empty-state').addClass('hidden');

    unpaidData.forEach(function (item) {
        unpaidContainer.append(createUnpaidDrawerCard(item));
    });
}


window.showHouseDetails = function (house, contract) {
    const houseName = house.name || (((window.translations && window.translations.job_house_number) || (window.translations && window.translations.house_number) || '') + house.id);
    const isPapMode = house && house.isPapProperty === true;
    const canManageMedia = canManageHouseMedia(house);

    const hasOwner = houseHasOwner(house);
    const agencyContractType = house.agencyContractType || houseAgencyContractTypes[String(house.id)];
    let status = hasOwner ? (window.translations && window.translations.job_house_sold) : (window.translations && window.translations.job_house_available);
    if (house.hasPapContract) {
        status = (window.translations && window.translations.job_house_pap_contract);
    } else if (agencyContractType === 'rent') {
        status = (window.translations && window.translations.job_house_agency);
    } else if (!hasOwner && house.belongsToAgency) {
        status = (window.translations && window.translations.job_house_agency);
    }
    let zoneName = house.zoneName || (window.translations && window.translations.job_house_unknown_zone);

    if (zoneName === 'Zone inconnue' && window.translations && window.translations.job_house_unknown_zone) {
        zoneName = window.translations.job_house_unknown_zone;
    }

    const hasGarage = getGarageAvailabilityLabel(house.hasGarage);

    const statusLabel = (window.translations && window.translations.job_modal_status);
    const ownerLabel = (window.translations && window.translations.job_modal_owner);
    const locationLabel = (window.translations && window.translations.job_house_location);
    const priceLabel = (window.translations && window.translations.job_house_price);
    const interiorLabel = (window.translations && window.translations.job_modal_interior);
    const buyableLabel = (window.translations && window.translations.job_modal_buyable);
    const garageLabel = (window.translations && window.translations.job_house_garage);
    const noneText = (window.translations && window.translations.job_modal_no) || (window.translations && window.translations.none);
    const notDefinedText = (window.translations && window.translations.job_house_not_defined) || (window.translations && window.translations.not_defined);
    const yesText = (window.translations && window.translations.job_house_yes);
    const noText = (window.translations && window.translations.job_house_no);
    const descriptionLabel = (window.translations && window.translations.pap_listing_description_label) || 'Description';
    const descriptionPlaceholder = (window.translations && window.translations.job_contract_not_defined) || notDefinedText || '-';
    const rawPapDescription = house && typeof house.listingDescription === 'string' ? house.listingDescription.trim() : '';
    const papDescriptionText = rawPapDescription !== '' ? rawPapDescription : descriptionPlaceholder;
    const papDescriptionClass = rawPapDescription !== '' ? '' : ' pap-modal-description-placeholder';

    let additionalDetailsHTML = '';
    let papContractNoticeHTML = '';
    let papDescriptionHTML = '';
    if (house.hasPapContract) {
        const papContractText = (window.translations && window.translations.job_house_pap_contract_notice);
        papContractNoticeHTML = `<p class="modal-pap-contract-note">${escapeModalHtml(papContractText)}</p>`;
    }

    if (isPapMode) {
        papDescriptionHTML = `
            <div class="pap-modal-description-block">
                <span class="pap-modal-description-label">${escapeModalHtml(descriptionLabel)}</span>
                <p class="pap-modal-description-text${papDescriptionClass}">${escapeModalHtml(papDescriptionText)}</p>
            </div>
        `;
    }

    if (contract && contract.createdAt) {
        const createdAtLabel = (window.translations && window.translations.job_modal_created_at);
        additionalDetailsHTML += `
        <div class="modal-detail-row">
            <span class="modal-detail-label">${escapeModalHtml(createdAtLabel)}:</span>
            <span class="modal-detail-value">${escapeModalHtml(formatDate(contract.createdAt))}</span>
        </div>
        `;
    }

    const titleControlsHTML = canManageMedia ? `
                <div class="house-title-container agency-house-title-container">
                    <input
                        type="text"
                        class="house-title-input hidden"
                        data-house-id="${escapeModalHtml(house.id)}"
                        value="${escapeModalHtml(houseName)}"
                        maxlength="64"
                    />
                    <button class="edit-house-title-btn" title="${escapeModalHtml((window.translations && window.translations.job_modal_edit))}">
                        <i class="ph ph-pencil-simple"></i>
                    </button>
                    <button id="upload-image-btn" type="button" class="upload-house-title-btn" title="${escapeModalHtml((window.translations && window.translations.job_images_add_image))}">
                        <i class="ph ph-image"></i>
                        <span>${escapeModalHtml((window.translations && window.translations.job_images_add_image))}</span>
                    </button>
                    <button class="save-house-title-btn hidden" title="${escapeModalHtml((window.translations && window.translations.job_modal_save))}">
                        <i class="ph ph-check"></i>
                    </button>
                    <button class="cancel-house-title-btn hidden" title="${escapeModalHtml((window.translations && window.translations.job_modal_cancel_btn))}">
                        <i class="ph ph-x"></i>
                    </button>
                </div>
    ` : '';

    window.ModalManager.open({
        title: (window.translations && window.translations.job_modal_property_info),
        containerClass: 'house-details-modal',
        hint: houseName,
        mainBlockHeader: {
            title: houseName,
            target: '.agency-house-details-main-block'
        },
        bodyHTML: `
            <div class="agency-modal-main-block agency-house-details-main-block">
                ${titleControlsHTML}

                <div id="house-images-container" class="house-images-container agency-house-images-container"></div>
                ${papDescriptionHTML}

                <div id="modal-house-details" class="modal-house-details agency-house-details-info">
                    ${additionalDetailsHTML}
                    <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(statusLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(status)}</span></div>
                    <div class="modal-detail-grid">
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml((window.translations && window.translations.job_modal_house_id))}:</span> <span class="modal-detail-value">#${escapeModalHtml(house.id)}</span></div>
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(ownerLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(house.ownerName || noneText)}</span></div>
                    </div>
                    <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(locationLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(zoneName)}</span></div>
                    <div class="modal-detail-grid">
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(priceLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(house.price ? formatPrice(house.price) : notDefinedText)}</span></div>
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(buyableLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(house.isBuyable ? yesText : noText)}</span></div>
                    </div>
                    <div class="modal-detail-grid">
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(interiorLabel)}:</span> <span class="modal-detail-value">#${escapeModalHtml(house.interior || 1)}</span></div>
                        <div class="modal-detail-row"><span class="modal-detail-label">${escapeModalHtml(garageLabel)}:</span> <span class="modal-detail-value">${escapeModalHtml(hasGarage)}</span></div>
                    </div>
                    ${papContractNoticeHTML}
                </div>
            </div>
        `,
        onOpen: function ($modal) {
            $modal.closest('.pap-modal').data('house', house);

            const $mainBlock = $modal.find('.agency-house-details-main-block').first();
            const $mainHeader = $mainBlock.children('.pap-main-block-header').first();
            const $titleControls = $mainBlock.children('.agency-house-title-container').first();
            if ($mainHeader.length && $titleControls.length) {
                $mainHeader.append($titleControls);
            }

            normalizeHouseImagesState(house);
            currentHouseDetailsModalData = house;
            renderHouseImages(house.images || [], house);
            fetchHouseImagesForModal(house);
            translateJobInterface();

            isModalOpen = true;
            const resourceName = jobGetResourceName();
            fetch(`https://${resourceName}/modalOpened`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            }).catch(function () { });
        },
        onClose: function () {
            isModalOpen = false;
            currentHouseDetailsModalData = null;
        }
    });
}

function renderHouseImages(images, house) {
    const imagesContainer = $('#house-images-container');
    if (!imagesContainer.length) {
        return;
    }

    const canManageMedia = canManageHouseMedia(house);

    imagesContainer.empty();

    if (!images || images.length === 0) {
        const previewPlaceholder = canUseHousePreviewPlaceholders() ? getHouseInteriorPreviewImage(house) : null;
        if (previewPlaceholder) {
            const imagesGrid = $('<div>').addClass('house-images-grid');
            const imageItem = $('<div>').addClass('house-image-item preview-placeholder-item');
            const img = $('<img>')
                .attr('src', previewPlaceholder)
                .addClass('house-image')
                .css('cursor', 'pointer')
                .on('error', function () {
                    const imageItemContainer = $(this).closest('.house-image-item');
                    $(this).remove();
                    if (!imageItemContainer.find('.house-image-placeholder').length) {
                        imageItemContainer.append(createImagePlaceholder('ph:house-line', 'house-image-placeholder'));
                    }
                })
                .on('click', function (e) {
                    e.stopPropagation();
                    showImageLightbox(previewPlaceholder, [previewPlaceholder], 0);
                });

            imageItem.append(img);
            imagesGrid.append(imageItem);
            imagesContainer.html(imagesGrid);
            return;
        }

        const noImagesText = (window.translations && window.translations.job_images_no_images) || 'No images';
        const noImagesElement = $('<div>').addClass('no-images');
        noImagesElement.append($('<i>').addClass(HOUSE_PLACEHOLDER_ICON_CLASS).attr('aria-hidden', 'true'));
        noImagesElement.append($('<span>').text(noImagesText));
        imagesContainer.html(noImagesElement);
        return;
    }

    const imagesGrid = $('<div>').addClass('house-images-grid');

    images.forEach(function (imageData, index) {
        const imageItem = $('<div>').addClass('house-image-item');

        const img = $('<img>')
            .attr('src', imageData)
            .addClass('house-image')
            .css('cursor', 'pointer')
            .on('error', function () {
                const imageItemContainer = $(this).closest('.house-image-item');
                $(this).remove();
                if (!imageItemContainer.find('.house-image-placeholder').length) {
                    imageItemContainer.append(createImagePlaceholder('ph:house-line', 'house-image-placeholder'));
                }
            })
            .on('click', function (e) {
                e.stopPropagation();
                showImageLightbox(imageData, images, index);
            });

        imageItem.append(img);
        if (canManageMedia) {
            const deleteBtn = $('<button>')
                .addClass('delete-image-btn')
                .html('<i class="ph ph-x"></i>')
                .attr('title', window.translations.job_images_delete_title)
                .on('click', function (e) {
                    e.stopPropagation();
                    deleteHouseImage(index + 1);
                });

            imageItem.append(deleteBtn);
        }
        imagesGrid.append(imageItem);
    });

    imagesContainer.html(imagesGrid);

    translateJobInterface();
}

function showImageLightbox(imageSrc, allImages, currentIndex) {
    
    let $lightbox = $('#image-lightbox');
    if (!$lightbox.length) {
        $lightbox = $('<div>').attr('id', 'image-lightbox').addClass('image-lightbox hidden');
        $('body').append($lightbox);
    }

    const $content = $('<div>').addClass('lightbox-content');
    const $img = $('<img>').attr('src', imageSrc).addClass('lightbox-image');
    const $closeBtn = $('<button>').addClass('lightbox-close').html('<i class="ph ph-x"></i>');

    
    const $prevBtn = $('<button>').addClass('lightbox-nav lightbox-prev').html('<i class="ph ph-caret-left"></i>');
    const $nextBtn = $('<button>').addClass('lightbox-nav lightbox-next').html('<i class="ph ph-caret-right"></i>');

    const updateImage = (index) => {
        if (index < 0) index = allImages.length - 1;
        if (index >= allImages.length) index = 0;
        currentIndex = index;
        $img.fadeOut(200, function () {
            $img.attr('src', allImages[currentIndex]).fadeIn(200);
        });
    };

    const closeLightbox = function () {
        $lightbox.addClass('hidden');
        if (window.__nextHousingLightboxKeyHandler) {
            document.removeEventListener('keydown', window.__nextHousingLightboxKeyHandler, true);
            window.__nextHousingLightboxKeyHandler = null;
        }
    };

    $content.append($img);

    
    if (allImages && allImages.length > 1) {
        $lightbox.empty().append($prevBtn).append($content).append($nextBtn);

        $prevBtn.on('click', function (e) {
            e.stopPropagation();
            updateImage(currentIndex - 1);
        });

        $nextBtn.on('click', function (e) {
            e.stopPropagation();
            updateImage(currentIndex + 1);
        });
    } else {
        $lightbox.empty().append($content);
    }

    $lightbox.append($closeBtn);

    $closeBtn.on('click', function () {
        closeLightbox();
    });

    $lightbox.off('click.imageLightbox').on('click.imageLightbox', function (e) {
        if ($(e.target).hasClass('image-lightbox')) {
            closeLightbox();
        }
    });

    if (window.__nextHousingLightboxKeyHandler) {
        document.removeEventListener('keydown', window.__nextHousingLightboxKeyHandler, true);
        window.__nextHousingLightboxKeyHandler = null;
    }

    window.__nextHousingLightboxKeyHandler = function (e) {
        if ($lightbox.hasClass('hidden')) return;

        if (e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            closeLightbox();
        } else if (e.key === 'ArrowLeft') {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            updateImage(currentIndex - 1);
        } else if (e.key === 'ArrowRight') {
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
            updateImage(currentIndex + 1);
        }
    };

    document.addEventListener('keydown', window.__nextHousingLightboxKeyHandler, true);

    $lightbox.removeClass('hidden');
}

function deleteHouseImage(imageIndex) {
    const house = $('#dynamic-global-modal').data('house');
    if (!house) {
        return;
    }
    if (!canManageHouseMedia(house)) {
        return;
    }

    const confirmText = window.translations.job_images_delete_confirm;
    const titleText = window.translations.job_modal_confirmation;

    showJobConfirmWithOptions(confirmText, titleText, function (confirmed) {
        if (!confirmed) {
            return;
        }

        const isPapMode = house.isPapProperty === true;
        const callbackName = isPapMode ? 'papRemoveHouseImage' : 'removeHouseImage';

        $.post(`http://next_housing/${callbackName}`, JSON.stringify({
            houseId: house.id,
            imageIndex: imageIndex,
            adminMode: window.nhIsAdmin === true
        }), function (response) {
            let result = response;
            if (typeof response === 'string') {
                try {
                    result = JSON.parse(response);
                } catch (error) {
                    console.error('[next_housing] removeHouseImage invalid JSON response:', error, response);
                    showJobAlert(window.translations.job_images_error_delete, window.translations.job_error_error);
                    return;
                }
            }
            if (result.success) {
                const currentImages = Array.isArray(house.images) ? [...house.images] : [];
                if (imageIndex >= 1 && imageIndex <= currentImages.length) {
                    currentImages.splice((imageIndex - 1), 1);
                }
                syncHouseImagesLocally(house.id, currentImages);

                renderHouseImages(house.images || [], house);
                refreshAfterHouseMediaOrTitleUpdate(isPapMode, house);
            } else {
                showJobAlert(result.message || (window.translations.job_images_error_delete), window.translations.job_error_error);
            }
        }).fail(function () {
            showJobAlert(window.translations.job_images_error_connection, window.translations.job_error_error);
        });
    }, { stack: true });
}

function uploadHouseImage(triggerButton) {
    const house = $('#dynamic-global-modal').data('house');
    if (!house) {
        showJobAlert(window.translations.job_images_error_house_not_found, window.translations.job_error_error);
        return;
    }
    if (!canManageHouseMedia(house)) {
        return;
    }

    const $btn = (triggerButton && triggerButton.length)
        ? triggerButton
        : $('#dynamic-global-modal .upload-house-title-btn:visible').first();

    if ($btn.prop('disabled')) {
        return;
    }

    const input = $('<input>')
        .attr('type', 'file')
        .attr('accept', 'image/*')
        .css({
            position: 'absolute',
            left: '-9999px',
            opacity: 0,
            pointerEvents: 'none'
        });

    $('body').append(input);

    const resetButton = function () {
        $btn
            .prop('disabled', false)
            .removeClass('is-uploading')
            .attr('title', window.translations.job_images_add_image);
        $btn.find('span').text(window.translations.job_images_add_image);
    };

    const cleanup = function () {
        input.off('change');
        input.remove();
    };

    input.on('change', function (e) {
        const file = e.target.files[0];

        cleanup();

        if (!file) {
            return;
        }

        if (!file.type || !file.type.match(/^image\/(jpeg|jpg|png|gif|webp)$/i)) {
            showJobAlert(window.translations.job_images_error_invalid_format, window.translations.job_error_error);
            return;
        }

        if (file.size > 2 * 1024 * 1024) {
            const errorMsg = (window.translations.job_images_error_too_large_with_tool || window.translations.job_images_error_too_large);
            showJobAlert(errorMsg, window.translations.job_error_error);
            return;
        }

        if (file.size === 0) {
            showJobAlert(window.translations.job_images_error_empty, window.translations.job_error_error);
            return;
        }

        const reader = new FileReader();

        reader.onerror = function () {
            resetButton();
            showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
        };

        reader.onload = function (e) {
            try {
                const originalImageData = e.target.result;

                if (!originalImageData || typeof originalImageData !== 'string') {
                    resetButton();
                    showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                    return;
                }

                $btn
                    .prop('disabled', true)
                    .addClass('is-uploading')
                    .attr('title', window.translations.job_images_upload_progress);
                $btn.find('span').text(window.translations.job_images_upload_progress);

                const img = new Image();
                img.onload = function () {
                    try {
                        const maxWidth = 1280;
                        const maxHeight = 720;
                        let width = img.width;
                        let height = img.height;

                        if (width > maxWidth || height > maxHeight) {
                            const ratio = Math.min(maxWidth / width, maxHeight / height);
                            width = Math.floor(width * ratio);
                            height = Math.floor(height * ratio);
                        }

                        const canvas = document.createElement('canvas');
                        canvas.width = width;
                        canvas.height = height;
                        const ctx = canvas.getContext('2d');

                        ctx.imageSmoothingEnabled = true;
                        ctx.imageSmoothingQuality = 'high';

                        ctx.drawImage(img, 0, 0, width, height);

                        const maxSize = 800 * 1024;

                        function isValidImageFormat(imageData) {
                            return imageData && imageData.startsWith('data:image/jpeg;base64,');
                        }

                        let compressedImageData = null;
                        const qualities = [0.75, 0.65, 0.55, 0.45, 0.35];

                        for (let i = 0; i < qualities.length; i++) {
                            compressedImageData = canvas.toDataURL('image/jpeg', qualities[i]);

                            if (!isValidImageFormat(compressedImageData)) {
                                resetButton();
                                showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                                return;
                            }

                            if (compressedImageData.length <= maxSize) {
                                break;
                            }
                        }

                        if (compressedImageData.length > maxSize) {
                            width = Math.floor(width * 0.5);
                            height = Math.floor(height * 0.5);
                            canvas.width = width;
                            canvas.height = height;
                            ctx.drawImage(img, 0, 0, width, height);
                            compressedImageData = canvas.toDataURL('image/jpeg', 0.6);

                            if (!isValidImageFormat(compressedImageData)) {
                                resetButton();
                                showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                                return;
                            }

                            if (compressedImageData.length > maxSize) {
                                resetButton();
                                const errorMsg = (window.translations.job_images_error_too_large_with_tool || window.translations.job_images_error_too_large);
                                showJobAlert(errorMsg, window.translations.job_error_error);
                                return;
                            }
                        }

                        uploadCompressedImage(compressedImageData);
                    } catch (error) {
                        resetButton();
                        console.error('Erreur lors de la compression:', error);
                        showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                    }
                };

                img.onerror = function () {
                    resetButton();
                    showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                };

                img.src = originalImageData;

                function uploadCompressedImage(imageData) {
                    const resourceName = jobGetResourceName();

                    const requestData = {
                        houseId: house.id,
                        imageData: imageData,
                        adminMode: window.nhIsAdmin === true
                    };

                    const isPapMode = house.isPapProperty === true;
                    const callbackName = isPapMode ? 'papAddHouseImage' : 'addHouseImage';

                    let timeoutId = setTimeout(function () {
                        resetButton();
                        showJobAlert(window.translations.job_images_error_connection, window.translations.job_error_error);
                    }, 20000);

                    fetch(`https://${resourceName}/${callbackName}`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify(requestData)
                    })
                        .then(function (response) {
                            clearTimeout(timeoutId);

                            if (!response.ok) {
                                throw new Error('HTTP error! status: ' + response.status);
                            }

                            return response.text();
                        })
                        .then(function (text) {
                            resetButton();

                            try {
                                const result = text ? (typeof text === 'string' ? JSON.parse(text) : text) : null;

                                if (result && result.success) {
                                    const shouldReopenJobModal = !isPapMode && isJobInterfaceVisible();

                                    if (!isPapMode) {
                                        if (!Array.isArray(house.images)) {
                                            house.images = [];
                                        }
                                        house.images.push(imageData);
                                        house.imagesLoaded = true;

                                        syncHouseImagesLocally(house.id, house.images);
                                    }

                                    refreshAfterHouseMediaOrTitleUpdate(isPapMode, house);

                                    if (shouldReopenJobModal) {
                                        setTimeout(function () {
                                            const updatedHouse = housesData.find(function (h) {
                                                return h.id === house.id;
                                            });
                                            if (updatedHouse) {
                                                showHouseDetails(updatedHouse);
                                            }
                                        }, 500);
                                    } else if (!isPapMode) {
                                        renderHouseImages(house.images || [], house);
                                    }
                                } else {
                                    const errorMsg = result && result.message ? result.message : (window.translations.job_images_error_add);
                                    showJobAlert(errorMsg, window.translations.job_error_error);
                                }
                            } catch (parseError) {
                                console.error('Erreur lors du parsing de la rÃ©ponse:', parseError, 'RÃ©ponse:', text);
                                showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
                            }
                        })
                        .catch(function (error) {
                            clearTimeout(timeoutId);
                            resetButton();
                            console.error('Erreur lors de l\'upload:', error);
                            showJobAlert(window.translations.job_images_error_connection, window.translations.job_error_error);
                        });
                }
            } catch (error) {
                resetButton();
                console.error('Erreur lors du traitement de l\'image:', error);
                showJobAlert(window.translations.job_images_error_add, window.translations.job_error_error);
            }
        };

        reader.readAsDataURL(file);
    });

    input.on('cancel', function () {
        cleanup();
    });

    input[0].click();
}

function closeHouseDetailsModal() {
    window.ModalManager.close();
}





if (typeof window.currencySymbol === 'undefined') {
    window.currencySymbol = '$';
}

if (typeof window.currencySymbolLoaded === 'undefined') {
    window.currencySymbolLoaded = false;
}

function jobGetCurrencySymbol() {
    const rawSymbol = window.currencySymbol === undefined || window.currencySymbol === null
        ? ''
        : String(window.currencySymbol);
    const cleanedSymbol = rawSymbol.trim();
    return cleanedSymbol !== '' ? cleanedSymbol : '$';
}

function jobShouldLoadCurrencySymbol() {
    return window.currencySymbolLoaded !== true;
}

function jobGetResourceName() {
    return nhResolveResourceName();
}

function jobLoadCurrencySymbol(attempt) {
    const currentAttempt = attempt || 1;
    const maxAttempts = 8;
    const resourceName = jobGetResourceName();

    $.post(`https://${resourceName}/getCurrencySymbol`, JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.symbol !== undefined && data.symbol !== null) {
                window.currencySymbol = String(data.symbol).trim();
            } else {
                window.currencySymbol = '$';
            }
            window.currencySymbol = jobGetCurrencySymbol();
            window.currencySymbolLoaded = true;

            const treasuryBalance = $('#treasury-balance');
            if (treasuryBalance.length && treasuryBalance.text()) {
                const currentText = treasuryBalance.text();
                const balanceMatch = currentText.match(/[\d\s]+/);
                if (balanceMatch) {
                    const balance = parseFloat(balanceMatch[0].replace(/\s/g, '')) || 0;
                    treasuryBalance.text(formatPrice(balance));
                } else {
                    refreshTreasury();
                }
            }
        } catch (e) {
            console.error('Erreur lors du chargement du symbole de monnaie:', e);
            window.currencySymbol = '$';
            window.currencySymbolLoaded = false;
        }
    }).fail(function () {
        if (currentAttempt < maxAttempts) {
            setTimeout(function () {
                jobLoadCurrencySymbol(currentAttempt + 1);
            }, 250);
            return;
        }

        console.warn('Echec du chargement du symbole de monnaie apres retries');
        window.currencySymbol = '$';
        window.currencySymbolLoaded = false;
    });
}

const jobPriceFormatter = new Intl.NumberFormat('fr-FR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
});

function formatPrice(price) {
    const currencySymbol = jobGetCurrencySymbol();
    if (typeof price === 'undefined' || price === null) return '0 ' + currencySymbol;
    const numericPrice = Number(price);
    const formatted = jobPriceFormatter.format(Number.isFinite(numericPrice) ? numericPrice : 0);
    return formatted + ' ' + currencySymbol;
}

function formatPriceDisplayValue(value, fallbackText) {
    const fallback = fallbackText || '-';
    if (value === undefined || value === null || value === '') return fallback;

    const rawValue = String(value).trim();
    if (!rawValue) return fallback;

    const numericPart = rawValue.replace(/[^\d-]/g, '');
    if (numericPart && numericPart !== '-') {
        const numericValue = Number(numericPart);
        if (Number.isFinite(numericValue)) {
            return formatPrice(numericValue);
        }
    }

    const currencySymbol = jobGetCurrencySymbol();
    return rawValue.includes(currencySymbol) ? rawValue : `${rawValue} ${currencySymbol}`;
}

function formatCurrencyLabel(labelText, fallbackLabel) {
    const currencySymbol = jobGetCurrencySymbol();
    const baseLabel = String(labelText || fallbackLabel || '').trim();
    if (!baseLabel) {
        return `Prix (${currencySymbol})`;
    }

    if (baseLabel.includes('%s')) {
        return baseLabel.replace(/%s/g, currencySymbol);
    }

    if (baseLabel.includes('$')) {
        return baseLabel.replace(/\$/g, currencySymbol);
    }

    if (baseLabel.includes(currencySymbol)) {
        return baseLabel;
    }

    if (/\([^)]*\)/.test(baseLabel)) {
        return baseLabel.replace(/\([^)]*\)/, `(${currencySymbol})`);
    }

    const fullWidthParenPattern = /\uFF08[^\uFF09]*\uFF09/;
    if (fullWidthParenPattern.test(baseLabel)) {
        return baseLabel.replace(fullWidthParenPattern, `\uFF08${currencySymbol}\uFF09`);
    }

    return `${baseLabel} (${currencySymbol})`;
}
function formatCoords(coords) {
    if (!coords) {
        return 'N/A';
    }
    const x = typeof coords.x === 'number' ? coords.x : parseFloat(coords.x) || 0;
    const y = typeof coords.y === 'number' ? coords.y : parseFloat(coords.y) || 0;
    const z = typeof coords.z === 'number' ? coords.z : parseFloat(coords.z) || 0;

    if (isNaN(x) || isNaN(y) || isNaN(z)) {
        return 'N/A';
    }

    return `X: ${x.toFixed(2)}, Y: ${y.toFixed(2)}, Z: ${z.toFixed(2)}`;
}





function translateJobInterface() {
    if (!window.translations || Object.keys(window.translations).length === 0) return;

    $("[data-translate]").not('option').each(function () {
        const $el = $(this);
        const key = $el.attr('data-translate');
        if (key && window.translations[key]) {
            const translationText = window.translations[key];
            if (translationText.includes('<') || translationText.includes('&lt;')) {
                $el.html(translationText);
            } else {
                $el.text(translationText);
            }
        }
    });


    $("[data-translate-placeholder]").each(function () {
        const key = $(this).attr('data-translate-placeholder');
        if (window.translations[key]) {
            $(this).attr('placeholder', window.translations[key]);
        }
    });

    const houseFilterSelect = $('#house-filter-type');
    if (houseFilterSelect.length > 0) {
        houseFilterSelect.find('option').each(function () {
            const key = $(this).attr('data-translate');
            if (key && window.translations[key]) {
                const translationText = window.translations[key];
                $(this).text(translationText);
            }
        });
        if (window.refreshCustomDropdown) {
            window.refreshCustomDropdown('house-filter-type');
        }
    }

    syncHouseFilterUI();

    const houseSearchInput = $('#house-search-input');
    if (houseSearchInput.length > 0) {
        houseSearchInput.attr('placeholder', window.translations.job_search_houses_placeholder);
    }

    const contractTypeSelect = $('#contract-type');
    if (contractTypeSelect.length > 0) {
        contractTypeSelect.find('option').each(function () {
            const key = $(this).attr('data-translate');
            if (key && window.translations[key]) {
                const translationText = window.translations[key];
                $(this).text(translationText);
            }
        });
        if (window.refreshCustomDropdown) {
            window.refreshCustomDropdown('contract-type');
        }
    }



    translateCreateContractModal();

    $('[data-translate-contract-edit="job_contract_edit"]').each(function () {
        if (window.translations.job_contract_edit) {
            $(this).text(window.translations.job_contract_edit);
        }
    });

    const refreshTitle = window.translations.job_refresh_title;
    $('#refresh-current-tab-btn').attr('title', refreshTitle);
}

function translateCreateContractModal() {
    if (!window.translations || Object.keys(window.translations).length === 0) return;

    let $modal = $('#create-contract-modal');
    if ($modal.length === 0) {
        $modal = $('#dynamic-global-modal:not(.hidden) .agency-contract-create-modal').first();
    }
    if ($modal.length === 0) return;

    $modal.find('[data-translate]').not('option').each(function () {
        const $el = $(this);
        const key = $el.attr('data-translate');
        if (key && window.translations[key]) {
            const translationText = window.translations[key];
            if (translationText.includes('<') || translationText.includes('&lt;')) {
                $el.html(translationText);
            } else {
                $el.text(translationText);
            }
        }
    });

    $modal.find('[data-translate-placeholder]').each(function () {
        const $el = $(this);
        const key = $el.attr('data-translate-placeholder');
        if (key && window.translations[key]) {
            $el.attr('placeholder', window.translations[key]);
        }
    });

    $modal.find('#contract-type option').each(function () {
        const $option = $(this);
        const key = $option.attr('data-translate');
        if (key && window.translations[key]) {
            $option.text(window.translations[key]);
        }
    });

    if (window.refreshCustomDropdown) {
        window.refreshCustomDropdown('contract-type');
    }

    if (typeof updateContractDurationOptions === 'function') {
        updateContractDurationOptions();
    }

    const contractType = $modal.find('#contract-type').val() || 'sale';
    const $priceLabel = $modal.find('#contract-price-label');
    if ($priceLabel.length > 0) {
        const priceKey = contractType === 'rent' ? 'job_contract_rent_price_label' : 'job_contract_sale_price_label';
        const fallbackLabel = contractType === 'rent' ? 'Loyer mensuel' : 'Prix de vente';
        const rawLabel = window.translations[priceKey] || `${fallbackLabel} ($)`;
        const priceLabel = formatCurrencyLabel(rawLabel, fallbackLabel);
        $priceLabel.text(priceLabel);
        $priceLabel.attr('data-translate', priceKey);
    }
}





function switchTab(tabName) {
    if (!tabName) {
        return;
    }

    $('.job-tab-btn').removeClass('active');
    $('.job-tab-panel').removeClass('active');

    $(`.job-tab-btn[data-tab="${tabName}"]`).addClass('active');
    $(`#job-tab-${tabName}`).addClass('active');

    saveToLocalStorage('next_housing_job_activeTab', tabName);

    if (tabName === 'houses') {
        filterHouses();
    } else if (tabName === 'contracts') {
        refreshContracts();
    } else if (tabName === 'map') {
        if (typeof window.nhJobMapOpenTab === 'function') {
            window.nhJobMapOpenTab(false);
        }
    } else if (tabName === 'treasury') {
        if (jobShouldLoadCurrencySymbol()) {
            jobLoadCurrencySymbol();
        }
        refreshTreasury();
    }
}





function getJobTabToRestore() {
    const savedTab = getFromLocalStorage('next_housing_job_activeTab');
    if (savedTab === 'unpaid') {
        return 'contracts';
    }
    if (savedTab === 'map') {
        const mapTabButton = $('.job-tab-btn[data-tab="map"]');
        if (!mapTabButton.length || mapTabButton.is(':hidden')) {
            return 'houses';
        }
    }
    if (savedTab && $(`.job-tab-btn[data-tab="${savedTab}"]`).length > 0) {
        return savedTab;
    }
    return 'houses';
}

function restoreJobInterfaceState(tabName) {
    const tabToRestore = tabName || getJobTabToRestore();

    const savedHouseFilter = getFromLocalStorage('next_housing_job_houseFilter');
    const validHouseFilters = ['all', 'vacant', 'agency', 'sold'];
    if (savedHouseFilter && validHouseFilters.includes(savedHouseFilter)) {
        currentHouseFilter = savedHouseFilter;
    } else {
        currentHouseFilter = 'all';
    }
    syncHouseFilterUI();

    setTimeout(function () {
        $('.job-tab-btn').removeClass('active');
        $('.job-tab-panel').removeClass('active');

        $(`.job-tab-btn[data-tab="${tabToRestore}"]`).addClass('active');
        $(`#job-tab-${tabToRestore}`).addClass('active');

        saveToLocalStorage('next_housing_job_activeTab', tabToRestore);

        if (tabToRestore === 'contracts') {
            refreshContracts();
            suppressHousesFadeUntil = 0;
        } else if (tabToRestore === 'map') {
            if (typeof window.nhJobMapOpenTab === 'function') {
                window.nhJobMapOpenTab(false);
            }
            suppressHousesFadeUntil = 0;
        } else if (tabToRestore === 'treasury') {
            if (jobShouldLoadCurrencySymbol()) {
                jobLoadCurrencySymbol();
            }
            refreshTreasury();
            suppressHousesFadeUntil = 0;
        } else {
            filterHouses(false);
        }
    }, 50);

    return tabToRestore;
}

function refreshCurrentTab() {
    const activeTab = $('.job-tab-btn.active').data('tab');

    if (activeTab === 'houses') {
        refreshHouses();
    } else if (activeTab === 'contracts') {
        refreshContracts();
    } else if (activeTab === 'map') {
        if (typeof window.nhJobMapOpenTab === 'function') {
            window.nhJobMapOpenTab(true);
        }
    } else if (activeTab === 'treasury') {
        refreshTreasury();
    }
}





function refreshContracts() {
    if (!hasRenderedContracts || !hasRenderedUnpaid) {
        $('#contracts-loading').removeClass('hidden');
    }
    $('#contracts-empty-state').addClass('hidden');

    $.post('http://next_housing/getContracts', JSON.stringify({}), function (response) {
    });
    refreshUnpaid();
}

function filterContracts() {
    filteredContracts = contractsData;
    renderContracts();
}

function renderContracts() {
    const contractsList = $('#contracts-list');
    const contractsContainer = contractsList.closest('.contracts-container');
    $('#contracts-loading').addClass('hidden');
    contractsList.empty();
    contractsContainer.children('.contracts-pattern-layer').remove();

    const groupedContracts = groupContractsByType(filteredContracts);
    if (groupedContracts.length === 0) {
        openContractDrawerType = null;
        openContractId = null;
        $('#contracts-empty-state').removeClass('hidden');
        return;
    }

    $('#contracts-empty-state').addClass('hidden');
    normalizeContractOpenState(groupedContracts);

    groupedContracts.forEach(function (group) {
        if (group.type === 'stats') {
            contractsList.append(createStatsDrawer(
                group.stats || buildContractsStats(filteredContracts, unpaidData),
                groupedContracts.length,
                contractsContainer
            ));
        } else if (group.type === 'unpaid') {
            contractsList.append(createUnpaidDrawer(group.unpaidItems || []));
        } else {
            contractsList.append(createContractDrawer(group.type, group.contracts));
        }
    });

    if (window.initCustomDropdowns) {
        window.initCustomDropdowns();
    }
    $('.contract-inline-edit-select').each(function () {
        const wrapper = this.nextElementSibling;
        if (wrapper && wrapper.classList && wrapper.classList.contains('custom-dropdown')) {
            wrapper.classList.add('contract-inline-dropdown');
            if (wrapper._listContainer && wrapper._listContainer.classList) {
                wrapper._listContainer.classList.add('contract-inline-dropdown-list');
            }
        }
    });

    translateJobInterface();
    pendingDrawerOpenAnimationType = null;
    pendingContractOpenAnimationKey = null;
}

function groupContractsByType(contracts) {
    const groupsByType = {
        sale: [],
        rent: [],
        other: []
    };

    contracts.forEach(function (contract) {
        const type = getContractTypeGroup(contract);
        groupsByType[type].push(contract);
    });

    const groupedContracts = ['sale', 'rent']
        .map(function (type) {
            return {
                type: type,
                contracts: sortContractsForDrawer(groupsByType[type])
            };
        });

    if (groupsByType.other.length > 0) {
        groupedContracts.push({
            type: 'other',
            contracts: sortContractsForDrawer(groupsByType.other)
        });
    }

    groupedContracts.push({
        type: 'unpaid',
        contracts: [],
        unpaidItems: sortUnpaidForDrawer(unpaidData)
    });

    groupedContracts.push({
        type: 'stats',
        contracts: [],
        stats: buildContractsStats(contracts, unpaidData)
    });

    return groupedContracts;
}

function sortContractsForDrawer(contracts) {
    return contracts.slice().sort(function (a, b) {
        const aTime = a && a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const bTime = b && b.createdAt ? new Date(b.createdAt).getTime() : 0;
        if (bTime !== aTime) {
            return bTime - aTime;
        }

        const aId = parseInt(a && a.id, 10) || 0;
        const bId = parseInt(b && b.id, 10) || 0;
        return bId - aId;
    });
}

function sortUnpaidForDrawer(unpaidList) {
    return unpaidList.slice().sort(function (a, b) {
        const aDays = parseInt(a && a.daysUnpaid, 10) || 0;
        const bDays = parseInt(b && b.daysUnpaid, 10) || 0;
        if (bDays !== aDays) {
            return bDays - aDays;
        }

        const aRent = parseInt(a && a.monthlyRent, 10) || 0;
        const bRent = parseInt(b && b.monthlyRent, 10) || 0;
        return bRent - aRent;
    });
}

function buildContractsStats(contracts, unpaidList) {
    const stats = {
        total: 0,
        sale: 0,
        rent: 0,
        other: 0,
        active: 0,
        pending: 0,
        closed: 0,
        unpaidCount: 0,
        unpaidMonthly: 0
    };

    (contracts || []).forEach(function (contract) {
        stats.total += 1;

        const type = getContractTypeGroup(contract);
        if (type === 'sale') {
            stats.sale += 1;
        } else if (type === 'rent') {
            stats.rent += 1;
        } else {
            stats.other += 1;
        }

        const status = String(contract && contract.status ? contract.status : '').toLowerCase();
        if (status === 'active') {
            stats.active += 1;
        } else if (status === 'pending') {
            stats.pending += 1;
        } else if (status === 'completed' || status === 'cancelled' || status === 'expired') {
            stats.closed += 1;
        }
    });

    stats.unpaidCount = (unpaidList || []).length;
    stats.unpaidMonthly = (unpaidList || []).reduce(function (total, item) {
        return total + (parseInt(item && item.monthlyRent, 10) || 0);
    }, 0);

    return stats;
}

function normalizeContractOpenState(groupedContracts) {
    if (openContractDrawerType) {
        const drawerExists = groupedContracts.some(function (group) {
            return group.type === openContractDrawerType;
        });
        if (!drawerExists) {
            openContractDrawerType = null;
        }
    }

    if (!openContractId) {
        if (inlineEditingContractKey) {
            const inlineEditingExists = groupedContracts.some(function (group) {
                return group.contracts.some(function (contract) {
                    return getContractUniqueKey(contract) === inlineEditingContractKey;
                });
            });
            if (!inlineEditingExists) {
                inlineEditingContractKey = null;
                inlineContractSaveInProgress = false;
            }
        }
        return;
    }

    let matchedType = null;
    groupedContracts.forEach(function (group) {
        const hasContract = group.contracts.some(function (contract) {
            return getContractUniqueKey(contract) === openContractId;
        });
        if (hasContract) {
            matchedType = group.type;
        }
    });

    if (!matchedType) {
        openContractId = null;
        return;
    }

    openContractDrawerType = matchedType;

    if (inlineEditingContractKey) {
        const inlineEditingExists = groupedContracts.some(function (group) {
            return group.contracts.some(function (contract) {
                return getContractUniqueKey(contract) === inlineEditingContractKey;
            });
        });
        if (!inlineEditingExists) {
            inlineEditingContractKey = null;
            inlineContractSaveInProgress = false;
        }
    }
}

function createContractDrawer(drawerType, contracts) {
    const isOpen = openContractDrawerType === drawerType;
    const selectedContract = isOpen
        ? contracts.find(function (contract) {
            return getContractUniqueKey(contract) === openContractId;
        })
        : null;
    const listTileWidth = 52;
    const listTileGap = 6;
    const listPaddingX = 20;
    const listPanelChrome = 2;
    const inlineContractWidth = selectedContract
        ? Math.min(560, Math.max(420, Math.round((window.innerWidth || 1280) * 0.36)))
        : 0;
    const listPanelWidth = Math.max(
        90,
        (contracts.length * listTileWidth)
        + (Math.max(contracts.length - 1, 0) * listTileGap)
        + (selectedContract ? listTileGap + inlineContractWidth : 0)
        + listPaddingX
        + listPanelChrome
    );

    const drawer = $('<div>')
        .addClass('contract-drawer')
        .attr('data-drawer-type', drawerType)
        .css('--drawer-list-width', `${listPanelWidth}px`);

    if (isOpen) {
        drawer.addClass('is-open');
        if (pendingDrawerOpenAnimationType === drawerType) {
            drawer.addClass('is-opening');
        }
    }
    const drawerButton = $('<button>')
        .attr('type', 'button')
        .addClass('contract-drawer-spine')
        .attr('aria-expanded', isOpen ? 'true' : 'false');

    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-name')
            .text(getContractTypeLabel(drawerType).toUpperCase())
    );
    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-count')
            .text(String(contracts.length))
    );

    drawerButton.on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        if (openContractDrawerType === drawerType) {
            openContractDrawerType = null;
            openContractId = null;
            pendingDrawerOpenAnimationType = null;
            pendingContractOpenAnimationKey = null;
        } else {
            openContractDrawerType = drawerType;
            if (!contracts.some(function (contract) {
                return getContractUniqueKey(contract) === openContractId;
            })) {
                openContractId = null;
            }
            pendingDrawerOpenAnimationType = drawerType;
            pendingContractOpenAnimationKey = null;
        }

        renderContracts();
    });

    const listPanel = $('<div>').addClass('contract-drawer-list-panel');
    const listPanelInner = $('<div>').addClass('contract-drawer-panel-inner');
    const listHeaderText = window.translations.job_tab_contracts;
    const listHeader = $('<div>').addClass('contract-drawer-list-header').text(listHeaderText.toUpperCase());
    const contractList = $('<div>').addClass('contract-list-mode');

    contracts.forEach(function (contract) {
        const contractItem = createContractListItem(contract, drawerType);
        contractList.append(contractItem);

        if (selectedContract && getContractUniqueKey(contract) === getContractUniqueKey(selectedContract)) {
            contractList.append(createContractInlinePanel(selectedContract));
        }
    });

    listPanelInner.append(listHeader);
    listPanelInner.append(contractList);
    listPanel.append(listPanelInner);

    drawer.append(drawerButton);
    drawer.append(listPanel);

    return drawer;
}

function createStatsDrawer(stats, totalDrawerCount, contractsContainer) {
    const drawerType = 'stats';
    const isOpen = openContractDrawerType === drawerType;
    const containerElement = contractsContainer && contractsContainer.length ? contractsContainer.get(0) : null;
    const containerWidth = containerElement ? containerElement.clientWidth : Math.round((window.innerWidth || 1280) * 0.58);
    const drawerSpineWidth = 58;
    const drawerGap = 10;
    const panelGap = 8;
    const sideSafety = 12;
    const count = Math.max(1, parseInt(totalDrawerCount, 10) || 1);
    const allSpinesWidth = (count * drawerSpineWidth) + (Math.max(count - 1, 0) * drawerGap);
    const maxPanelWidth = Math.max(120, containerWidth - allSpinesWidth - panelGap - sideSafety);
    const drawerPanelWidth = maxPanelWidth;

    const drawer = $('<div>')
        .addClass('contract-drawer')
        .addClass('contract-drawer-stats')
        .attr('data-drawer-type', drawerType)
        .css('--drawer-list-width', `${drawerPanelWidth}px`);

    if (isOpen) {
        drawer.addClass('is-open');
        if (pendingDrawerOpenAnimationType === drawerType) {
            drawer.addClass('is-opening');
        }
    }

    const drawerButton = $('<button>')
        .attr('type', 'button')
        .addClass('contract-drawer-spine')
        .attr('aria-expanded', isOpen ? 'true' : 'false');

    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-name')
            .text(getContractTypeLabel(drawerType).toUpperCase())
    );
    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-count')
            .text(String((stats && stats.total) || 0))
    );

    drawerButton.on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        if (openContractDrawerType === drawerType) {
            openContractDrawerType = null;
            pendingDrawerOpenAnimationType = null;
        } else {
            openContractDrawerType = drawerType;
            pendingDrawerOpenAnimationType = drawerType;
        }

        openContractId = null;
        pendingContractOpenAnimationKey = null;
        renderContracts();
    });

    const listPanel = $('<div>').addClass('contract-drawer-list-panel');
    const listPanelInner = $('<div>').addClass('contract-drawer-panel-inner');
    const listHeaderText = window.translations.job_contract_stats;
    const listHeader = $('<div>').addClass('contract-drawer-list-header').text(listHeaderText.toUpperCase());
    const statsList = $('<div>').addClass('contract-list-mode contract-stats-mode');
    statsList.append(createContractsStatsCard(stats || buildContractsStats(filteredContracts, unpaidData)));

    listPanelInner.append(listHeader);
    listPanelInner.append(statsList);
    listPanel.append(listPanelInner);

    drawer.append(drawerButton);
    drawer.append(listPanel);

    return drawer;
}

function createContractsStatsCard(stats) {
    const card = $('<div>').addClass('contract-stats-card');
    const titleText = window.translations.job_contract_stats;
    const contractsText = window.translations.job_tab_contracts;
    const saleText = window.translations.job_contract_type_sale;
    const rentText = window.translations.job_contract_type_rent;
    const otherText = window.translations.job_contract_type_other;
    const activeText = window.translations.job_contract_status_active;
    const closedText = window.translations.job_contract_status_completed;
    const unpaidText = window.translations.job_tab_unpaid;

    const total = Math.max(0, parseInt(stats && stats.total, 10) || 0);
    const sale = Math.max(0, parseInt(stats && stats.sale, 10) || 0);
    const rent = Math.max(0, parseInt(stats && stats.rent, 10) || 0);
    const other = Math.max(0, parseInt(stats && stats.other, 10) || 0);
    const active = Math.max(0, parseInt(stats && stats.active, 10) || 0);
    const closed = Math.max(0, parseInt(stats && stats.closed, 10) || 0);
    const unpaidCount = Math.max(0, parseInt(stats && stats.unpaidCount, 10) || 0);

    const typeTotal = sale + rent + other;
    const hasTypeData = typeTotal > 0;
    const salePercent = hasTypeData ? Math.round((sale / typeTotal) * 100) : 0;
    const rentPercent = hasTypeData ? Math.round((rent / typeTotal) * 100) : 0;
    const otherPercent = hasTypeData ? Math.max(0, 100 - salePercent - rentPercent) : 0;

    const activePercent = total > 0 ? Math.round((active / total) * 100) : 0;
    const closedPercent = total > 0 ? Math.round((closed / total) * 100) : 0;
    const unpaidPercent = total > 0 ? Math.round((unpaidCount / total) * 100) : 0;

    const head = $('<div>').addClass('contract-stats-head');
    const headText = $('<div>').addClass('contract-stats-head-text');
    headText.append($('<div>').addClass('contract-stats-title').text(titleText.toUpperCase()));
    head.append(headText);
    head.append(
        $('<div>')
            .addClass('contract-stats-head-pulse')
            .text(`${contractsText.toUpperCase()} : ${total}`)
    );
    card.append(head);

    const kpiRow = $('<div>').addClass('contract-stats-kpis');
    kpiRow.append(createStatsBadge(contractsText, total, 'total'));
    kpiRow.append(createStatsBadge(saleText, sale, 'sale'));
    kpiRow.append(createStatsBadge(rentText, rent, 'rent'));
    kpiRow.append(createStatsBadge(unpaidText, unpaidCount, 'unpaid'));
    card.append(kpiRow);

    const dashboard = $('<div>').addClass('contract-stats-dashboard');

    const splitChart = $('<div>').addClass('contract-stats-section contract-stats-section-types');
    splitChart.append(
        $('<div>')
            .addClass('contract-stats-section-title')
            .text((window.translations.job_contract_type_label).toUpperCase())
    );

    const donutWrap = $('<div>').addClass('contract-stats-donut-wrap');
    const donut = $('<div>').addClass('contract-stats-donut');
    if (hasTypeData) {
        const splitOne = salePercent;
        const splitTwo = salePercent + rentPercent;
        donut.css(
            'background',
            `conic-gradient(var(--stats-sale-color) 0 ${splitOne}%, var(--stats-rent-color) ${splitOne}% ${splitTwo}%, var(--stats-other-color) ${splitTwo}% 100%)`
        );
    } else {
        donut.css('background', 'conic-gradient(rgba(255,255,255,0.08) 0 100%)');
    }
    const donutCenter = $('<div>').addClass('contract-stats-donut-center');
    donutCenter.append($('<span>').addClass('contract-stats-donut-total').text(String(total)));
    donutCenter.append($('<span>').addClass('contract-stats-donut-caption').text((contractsText || 'Contracts').toUpperCase()));
    donut.append(donutCenter);

    const legend = $('<div>').addClass('contract-stats-legend');
    legend.append(createStatsLegendRow(saleText, sale, salePercent, 'sale'));
    legend.append(createStatsLegendRow(rentText, rent, rentPercent, 'rent'));
    legend.append(createStatsLegendRow(otherText, other, otherPercent, 'other'));
    donutWrap.append(donut);
    donutWrap.append(legend);
    splitChart.append(donutWrap);

    const activityChart = $('<div>').addClass('contract-stats-section contract-stats-section-activity');
    activityChart.append(
        $('<div>')
            .addClass('contract-stats-section-title')
            .text((window.translations.job_contract_conditions).toUpperCase())
    );

    const activityWrap = $('<div>').addClass('contract-stats-activity-wrap');

    const activityLegend = $('<div>').addClass('contract-stats-legend contract-stats-legend-activity');
    activityLegend.append(createStatsLegendRow(activeText, active, activePercent, 'active'));
    activityLegend.append(createStatsLegendRow(closedText, closed, closedPercent, 'closed'));
    activityLegend.append(createStatsLegendRow(unpaidText, unpaidCount, unpaidPercent, 'unpaid'));
    activityWrap.append(activityLegend);

    activityChart.append(activityWrap);

    dashboard.append(splitChart);
    dashboard.append(activityChart);
    card.append(dashboard);
    return card;
}

function createStatsBadge(label, value, tone) {
    const badge = $('<div>').addClass('contract-stats-kpi');
    if (tone) {
        badge.addClass(`tone-${tone}`);
    }
    badge.append($('<span>').addClass('contract-stats-kpi-label').text(String(label || '').toUpperCase()));
    badge.append($('<span>').addClass('contract-stats-kpi-value').text(String(value || 0)));
    return badge;
}

function createStatsLegendRow(label, value, percent, tone) {
    const row = $('<div>').addClass('contract-stats-legend-row');
    row.append($('<span>').addClass(`contract-stats-dot tone-${tone}`));
    row.append($('<span>').addClass('contract-stats-legend-label').text(String(label || '')));
    row.append($('<span>').addClass('contract-stats-legend-value').text(`${value} | ${percent}%`));
    const track = $('<div>').addClass('contract-stats-legend-track');
    const fill = $('<span>').addClass(`contract-stats-legend-fill tone-${tone}`);
    fill.css('width', `${Math.max(0, Math.min(100, percent || 0))}%`);
    track.append(fill);
    row.append(track);
    return row;
}

function createUnpaidDrawer(unpaidItems) {
    const drawerType = 'unpaid';
    const isOpen = openContractDrawerType === drawerType;
    const drawerPanelWidth = Math.min(560, Math.max(340, Math.round((window.innerWidth || 1280) * 0.34)));

    const drawer = $('<div>')
        .addClass('contract-drawer')
        .addClass('contract-drawer-unpaid')
        .attr('data-drawer-type', drawerType)
        .css('--drawer-list-width', `${drawerPanelWidth}px`);

    if (isOpen) {
        drawer.addClass('is-open');
        if (pendingDrawerOpenAnimationType === drawerType) {
            drawer.addClass('is-opening');
        }
    }

    const drawerButton = $('<button>')
        .attr('type', 'button')
        .addClass('contract-drawer-spine')
        .attr('aria-expanded', isOpen ? 'true' : 'false');

    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-name')
            .text(getContractTypeLabel(drawerType).toUpperCase())
    );
    drawerButton.append(
        $('<span>')
            .addClass('contract-drawer-count')
            .text(String(unpaidItems.length))
    );

    drawerButton.on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        if (openContractDrawerType === drawerType) {
            openContractDrawerType = null;
            pendingDrawerOpenAnimationType = null;
        } else {
            openContractDrawerType = drawerType;
            pendingDrawerOpenAnimationType = drawerType;
        }

        openContractId = null;
        pendingContractOpenAnimationKey = null;
        renderContracts();
    });

    const listPanel = $('<div>').addClass('contract-drawer-list-panel');
    const listPanelInner = $('<div>').addClass('contract-drawer-panel-inner');
    const listHeaderText = window.translations.job_tab_unpaid;
    const listHeader = $('<div>').addClass('contract-drawer-list-header').text(listHeaderText.toUpperCase());
    const unpaidList = $('<div>').addClass('contract-list-mode unpaid-list-mode');

    if (unpaidItems.length === 0) {
        const emptyText = window.translations.job_unpaid_empty;
        unpaidList.append($('<div>').addClass('unpaid-drawer-empty').text(emptyText));
    } else {
        unpaidItems.forEach(function (item) {
            unpaidList.append(createUnpaidDrawerCard(item));
        });
    }

    listPanelInner.append(listHeader);
    listPanelInner.append(unpaidList);
    listPanel.append(listPanelInner);

    drawer.append(drawerButton);
    drawer.append(listPanel);

    return drawer;
}

function createUnpaidDrawerCard(item) {
    const card = $('<div>').addClass('unpaid-card').addClass('unpaid-drawer-card');
    card.append(createContractInfoItem(window.translations.job_contract_beneficiary, item.playerName || (window.translations.job_modal_unknown)));
    card.append(createContractInfoItem(window.translations.job_contract_property, `#${item.houseId}`));
    card.append(createContractInfoItem(window.translations.job_contract_monthly_rent, formatPrice(item.monthlyRent || 0)));
    const daysUnpaidText = window.translations.job_unpaid_days;
    const daysText = window.translations.job_unpaid_days_unit;
    card.append(createContractInfoItem(daysUnpaidText, `${item.daysUnpaid || 0} ${daysText}`));
    return card;
}

function createContractInlinePanel(contract) {
    const inlinePanel = $('<div>').addClass('contract-inline-panel-item');
    if (pendingContractOpenAnimationKey === getContractUniqueKey(contract)) {
        inlinePanel.addClass('is-opening');
    }
    const inlinePanelInner = $('<div>').addClass('contract-drawer-panel-inner contract-sheet-wrapper contract-inline-panel-inner');
    inlinePanelInner.append(createContractSheet(contract));
    inlinePanel.append(inlinePanelInner);
    return inlinePanel;
}

function createContractListItem(contract, drawerType) {
    const contractType = String(contract.type || '').toLowerCase();
    const contractStatus = String(contract.status || '').toLowerCase();
    const typeText = getContractTypeLabel(contractType);
    const contractTitle = getContractTitle(contract, typeText);
    const contractKey = getContractUniqueKey(contract);
    const isSelected = openContractDrawerType === drawerType && openContractId === contractKey;

    const listItem = $('<div>')
        .addClass('contract-list-item')
        .attr('data-contract-key', contractKey);

    if (isSelected) {
        listItem.addClass('is-selected');
        if (pendingContractOpenAnimationKey === contractKey) {
            listItem.addClass('is-opening');
        }
    }

    const titleContainer = createContractTitleContainer(contract, contractTitle);
    const leftSide = $('<div>').addClass('contract-list-item-main');
    leftSide.append(titleContainer);

    const beneficiaryText = contract.playerName || (window.translations.job_modal_unknown);
    const meta = $('<div>').addClass('contract-list-item-meta');
    meta.append($('<span>').addClass('contract-list-item-meta-line').text(beneficiaryText));
    leftSide.append(meta);

    const statusClassName = (contractStatus || 'unknown').replace(/[^a-z0-9_-]/g, '') || 'unknown';
    const statusText = getContractStatusText(contractStatus);
    const statusBadge = $('<span>')
        .addClass('house-status')
        .addClass('contract-status-badge')
        .addClass('contract-list-status-dot')
        .addClass('contract-status-' + statusClassName)
        .attr('title', statusText)
        .attr('aria-label', statusText)
        .text('');

    const rightSide = $('<div>').addClass('contract-list-item-right');
    rightSide.append(statusBadge);

    listItem.append(leftSide);
    listItem.append(rightSide);

    listItem.on('click', function (e) {
        if ($(e.target).closest('button, .action-btn').length) {
            return;
        }

        openContractDrawerType = drawerType;
        const nextContractId = openContractId === contractKey ? null : contractKey;
        openContractId = nextContractId;
        pendingContractOpenAnimationKey = nextContractId;
        renderContracts();
    });

    return listItem;
}

function createContractTitleContainer(contract, contractTitle) {
    const titleContainer = $('<div>').addClass('contract-title-container');
    const tileTitle = truncateContractTitleForTile(contractTitle);
    const titleDisplay = $('<span>')
        .addClass('contract-title-display')
        .text(tileTitle)
        .attr('title', contractTitle);

    titleContainer.append(titleDisplay);

    return titleContainer;
}

function createContractSheet(contract) {
    const contractType = String(contract.type || '').toLowerCase();
    const contractStatus = String(contract.status || '').toLowerCase();
    const typeText = getContractTypeLabel(contractType);
    const titleText = getContractTitle(contract, typeText);
    const isInlineEditing = isContractInlineEditing(contract);
    const house = getContractHouse(contract);

    const sectionParties = window.translations.job_contract_parties;
    const sectionProperty = window.translations.job_contract_property_section;
    const sectionConditions = window.translations.job_contract_conditions;
    const unknownText = window.translations.job_modal_unknown;
    const durationMonthsLabel = window.translations.job_contract_duration_months;
    const noText = window.translations.job_contract_na;

    const sheet = $('<div>').addClass('contract-sheet-preview');
    const statusClassName = (contractStatus || 'unknown').replace(/[^a-z0-9_-]/g, '') || 'unknown';
    const locationStatusBadge = $('<span>')
        .addClass('house-status')
        .addClass('contract-status-badge')
        .addClass('contract-sheet-location-badge')
        .addClass('contract-status-' + statusClassName)
        .text(getContractStatusText(contractStatus));

    const header = $('<div>').addClass('contract-sheet-header');
    const headerTop = $('<div>').addClass('contract-sheet-header-top');
    headerTop.append($('<span>').addClass('contract-sheet-type').text(typeText.toUpperCase()));
    headerTop.append(locationStatusBadge);
    header.append(headerTop);
    header.append($('<h4>').addClass('contract-sheet-title').text(titleText));

    const headerMeta = $('<div>').addClass('contract-sheet-meta');
    const contractNumberText = window.translations.job_contract_number;
    const numberLabel = contractNumberText + (contract.id || 'N/A');
    headerMeta.append($('<span>').addClass('contract-sheet-number').text(numberLabel));
    header.append(headerMeta);
    sheet.append(header);

    const body = $('<div>').addClass('contract-sheet-body');

    body.append(createContractSheetSection(sectionParties, [
        {
            label: window.translations.job_contract_seller_label,
            value: contract.agentName || 'Agent'
        },
        {
            label: window.translations.job_contract_buyer_label,
            value: contract.playerName || unknownText
        }
    ]));

    body.append(createContractSheetSection(sectionProperty, [
        {
            label: window.translations.job_contract_property,
            value: '#' + (contract.houseId || 'N/A')
        },
        {
            label: window.translations.job_house_location,
            value: (house && house.zoneName) || contract.houseLocation || (window.translations.job_house_unknown_zone)
        },
        {
            label: window.translations.job_contract_interior_label,
            value: String((house && house.interior) || contract.houseInterior || 1)
        },
        {
            label: window.translations.job_contract_garage_label,
            value: getGarageAvailabilityLabel((house && house.garage) || contract.hasGarage, {
                yesKey: 'job_contract_yes',
                noKey: 'job_contract_no'
            })
        }
    ]));

    const conditionsRows = [
        {
            label: window.translations.job_contract_type_label,
            value: typeText
        },
        {
            label: contractType === 'sale'
                ? (window.translations.job_contract_sale_price)
                : (window.translations.job_contract_monthly_rent),
            value: formatPrice(contract.price || 0)
        },
        {
            label: window.translations.job_contract_duration,
            value: contractType === 'rent'
                ? `${contract.durationMonths || 0} ${durationMonthsLabel}`
                : noText
        },
        {
            label: window.translations.job_contract_created_at,
            value: contract.createdAt ? formatDate(contract.createdAt) : noText
        }
    ];
    body.append(createContractSheetSection(sectionConditions, conditionsRows));

    if (contractType === 'rent' && isInlineEditing) {
        body.append(createContractInlineEditSection(contract, typeText));
    }

    body.append(createContractSheetActions(contract, contractType, contractStatus, isInlineEditing));
    sheet.append(body);

    return sheet;
}

function createContractSheetSection(title, rows, options) {
    const section = $('<div>').addClass('contract-sheet-section');
    const header = $('<div>').addClass('contract-sheet-section-header');
    header.append($('<h5>').text(title));
    if (options && options.badge) {
        header.append(options.badge);
    }
    section.append(header);

    rows.forEach(function (row) {
        const line = $('<div>').addClass('contract-sheet-row');
        line.append($('<span>').addClass('contract-sheet-row-label').text(String(row.label || '')));
        const value = $('<span>').addClass('contract-sheet-row-value');
        if (row.badge) {
            value.addClass('has-badge');
            value.append($('<span>').addClass('contract-sheet-row-value-text').text(String(row.value || '-')));
            value.append(row.badge);
        } else {
            value.text(String(row.value || '-'));
        }
        line.append(value);
        section.append(line);
    });

    return section;
}

function isContractInlineEditing(contract) {
    if (!contract) {
        return false;
    }
    return inlineEditingContractKey === getContractUniqueKey(contract);
}

function getContractInlineEditIdBase(contract) {
    const contractKey = getContractUniqueKey(contract) || 'contract';
    return `contract-inline-edit-${String(contractKey).replace(/[^a-zA-Z0-9_-]/g, '_')}`;
}

function truncateContractTitleForTile(text) {
    const value = String(text || '');
    if (value.length <= CONTRACT_TILE_TITLE_MAX_LENGTH) {
        return value;
    }
    return value.slice(0, Math.max(1, CONTRACT_TILE_TITLE_MAX_LENGTH - 3)) + '...';
}

function createContractInlineEditRow(labelText, inputElement) {
    const row = $('<div>').addClass('contract-sheet-row contract-inline-edit-row');
    row.append($('<span>').addClass('contract-sheet-row-label').text(String(labelText || '')));
    const rowValue = $('<span>').addClass('contract-sheet-row-value contract-inline-edit-value');
    rowValue.append(inputElement);
    row.append(rowValue);
    return row;
}

function createContractInlineEditSection(contract, typeText) {
    const sectionTitle = window.translations.job_modal_edit_contract;
    const contractNameLabel = window.translations.job_modal_edit_name;
    const rentLabel = formatCurrencyLabel(window.translations.job_contract_rent_price_label, 'Monthly rent');
    const durationLabel = window.translations.job_contract_duration_label;

    const section = $('<div>').addClass('contract-sheet-section contract-inline-edit-section');
    const header = $('<div>').addClass('contract-sheet-section-header');
    header.append($('<h5>').text(sectionTitle.toUpperCase()));
    section.append(header);

    const idBase = getContractInlineEditIdBase(contract);
    const initialTitle = getContractTitle(contract, typeText);
    const currentPrice = parseInt(contract.price, 10) || 0;
    const currentDuration = parseInt(contract.durationMonths, 10) || 1;

    const nameInput = $('<input>')
        .attr('type', 'text')
        .attr('id', `${idBase}-name`)
        .attr('maxlength', String(CONTRACT_NAME_MAX_LENGTH))
        .addClass('contract-inline-edit-input contract-inline-name-input')
        .val(initialTitle);
    section.append(createContractInlineEditRow(contractNameLabel, nameInput));

    const priceInput = $('<input>')
        .attr('type', 'number')
        .attr('id', `${idBase}-price`)
        .attr('min', '1')
        .addClass('contract-inline-edit-input')
        .val(currentPrice > 0 ? currentPrice : '');
    section.append(createContractInlineEditRow(rentLabel, priceInput));

    const durationSelect = $('<select>')
        .attr('id', `${idBase}-duration`)
        .addClass('contract-inline-edit-select')
        .attr('data-custom-dropdown-disabled', 'true');
    const durationValues = [1, 3, 6, 12];
    if (currentDuration > 0 && !durationValues.includes(currentDuration)) {
        durationValues.push(currentDuration);
    }
    durationValues.sort(function (a, b) { return a - b; });
    durationValues.forEach(function (value) {
        const monthTemplate = window.translations.job_contract_month_option;
        const optionLabel = monthTemplate.replace('%s', String(value));
        durationSelect.append($('<option>').val(String(value)).text(optionLabel));
    });
    durationSelect.val(String(currentDuration));
    section.append(createContractInlineEditRow(durationLabel, durationSelect));

    return section;
}

function parseNuiResponse(response) {
    if (typeof response === 'string') {
        try {
            return JSON.parse(response);
        } catch (_) {
            return response;
        }
    }
    return response;
}

function setInlineContractEditSavingState(isSaving) {
    inlineContractSaveInProgress = !!isSaving;

    const $inlineSection = $('.contract-inline-edit-section');
    const $inputs = $inlineSection.find('input, select');
    const $saveButtons = $('.contract-inline-save-btn');
    const $cancelButtons = $('.contract-inline-cancel-btn');

    $inputs.prop('disabled', !!isSaving);
    $saveButtons.prop('disabled', !!isSaving);
    $cancelButtons.prop('disabled', !!isSaving);

    const saveText = window.translations.job_modal_save;
    const processingText = window.translations.job_contract_processing;
    $saveButtons.text(isSaving ? processingText : saveText);
}

function saveInlineContractEdit(contract) {
    if (!contract || !contract.id) {
        return;
    }

    if (inlineContractSaveInProgress) {
        return;
    }

    const idBase = getContractInlineEditIdBase(contract);
    const $nameInput = $(`#${idBase}-name`);
    const $priceInput = $(`#${idBase}-price`);
    const $durationInput = $(`#${idBase}-duration`);

    if (!$nameInput.length || !$priceInput.length || !$durationInput.length) {
        showJobAlert(window.translations.job_error_update_failed, window.translations.job_error_error);
        return;
    }

    const newName = String($nameInput.val() || '').trim();
    const newPrice = parseInt($priceInput.val(), 10);
    const newDuration = parseInt($durationInput.val(), 10);
    const typeText = getContractTypeLabel(String(contract.type || '').toLowerCase());
    const currentTitle = getContractTitle(contract, typeText);
    const currentPrice = parseInt(contract.price, 10) || 0;
    const currentDuration = parseInt(contract.durationMonths, 10) || 0;

    if (!newName) {
        showJobAlert(window.translations.job_error_name_empty, window.translations.job_error_error);
        return;
    }

    if (!newPrice || newPrice <= 0) {
        showJobAlert(window.translations.job_error_invalid_price, window.translations.job_error_error);
        return;
    }

    if (!newDuration || newDuration <= 0) {
        showJobAlert(window.translations.job_error_select_duration, window.translations.job_error_error);
        return;
    }

    const shouldUpdateName = newName !== currentTitle;
    const shouldUpdateContract = newPrice !== currentPrice || newDuration !== currentDuration;
    const contractKey = getContractUniqueKey(contract);

    if (shouldUpdateName && newName.length > CONTRACT_NAME_MAX_LENGTH) {
        showJobAlert(`Le nom du contrat ne peut pas depasser ${CONTRACT_NAME_MAX_LENGTH} caracteres.`, window.translations.job_error_error);
        return;
    }

    if (!shouldUpdateName && !shouldUpdateContract) {
        inlineEditingContractKey = null;
        renderContracts();
        return;
    }

    const finishWithError = function (message) {
        setInlineContractEditSavingState(false);
        showJobAlert(message || (window.translations.job_error_update_failed), window.translations.job_error_error);
    };

    const applyLocalContractUpdates = function () {
        const target = contractsData.find(function (item) {
            return getContractUniqueKey(item) === contractKey;
        });
        if (!target) {
            return;
        }

        if (shouldUpdateName) {
            target.name = newName;
        }
        if (shouldUpdateContract) {
            target.price = newPrice;
            target.durationMonths = newDuration;
        }
    };

    const finishWithSuccess = function () {
        setInlineContractEditSavingState(false);
        applyLocalContractUpdates();
        inlineEditingContractKey = null;
        filterContracts();
        refreshContracts();
    };

    const updateContractValues = function () {
        if (!shouldUpdateContract) {
            finishWithSuccess();
            return;
        }

        $.post('http://next_housing/updateContract', JSON.stringify({
            contractId: contract.id,
            price: newPrice,
            duration: newDuration
        }), function (response) {
            if (response === 'ok') {
                finishWithSuccess();
            } else {
                const parsed = parseNuiResponse(response);
                const errorMessage = typeof parsed === 'string'
                    ? parsed
                    : (parsed && parsed.message) || (window.translations.job_error_update_failed);
                finishWithError(errorMessage);
            }
        }).fail(function () {
            finishWithError(window.translations.job_error_connection);
        });
    };

    setInlineContractEditSavingState(true);

    if (shouldUpdateName) {
        $.post('http://next_housing/updateContractName', JSON.stringify({
            contractId: contract.id,
            contractName: newName
        }), function (response) {
            const parsed = parseNuiResponse(response);
            if (parsed && parsed.success) {
                updateContractValues();
            } else {
                const errorMessage = (parsed && parsed.message) || (window.translations.job_error_update_failed);
                finishWithError(errorMessage);
            }
        }).fail(function () {
            finishWithError(window.translations.job_error_connection);
        });
    } else {
        updateContractValues();
    }
}

function createContractSheetActions(contract, contractType, contractStatus, isInlineEditing) {
    const actions = $('<div>').addClass('contract-sheet-actions');
    const contractKey = getContractUniqueKey(contract);

    const canEdit = contractType === 'rent';
    if (canEdit) {
        if (isInlineEditing) {
            const saveBtn = $('<button>')
                .attr('type', 'button')
                .addClass('action-btn')
                .addClass('save-btn')
                .addClass('contract-inline-save-btn')
                .text(window.translations.job_modal_save);

            saveBtn.on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                saveInlineContractEdit(contract);
            });
            actions.append(saveBtn);

            const cancelEditBtn = $('<button>')
                .attr('type', 'button')
                .addClass('action-btn')
                .addClass('cancel-edit-btn')
                .addClass('contract-inline-cancel-btn')
                .text(window.translations.job_modal_cancel_btn || window.translations.job_modal_cancel);

            cancelEditBtn.on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                if (inlineContractSaveInProgress) {
                    return;
                }
                inlineEditingContractKey = null;
                renderContracts();
            });
            actions.append(cancelEditBtn);
        } else {
            const editBtn = $('<button>')
                .attr('type', 'button')
                .addClass('action-btn')
                .addClass('edit-btn')
                .attr('data-translate-contract-edit', 'job_contract_edit')
                .text(window.translations.job_contract_edit);

            editBtn.on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                if (inlineContractSaveInProgress) {
                    return;
                }
                inlineEditingContractKey = contractKey;
                renderContracts();
            });
            actions.append(editBtn);
        }
    }

    const isPending = contractStatus === 'pending';
    const isActive = contractStatus === 'active';
    const isCompleted = contractStatus === 'completed';
    const canCancel = (contractType === 'rent' && (isPending || isActive)) || (contractType === 'sale' && isCompleted);

    if (canCancel && !isInlineEditing) {
        let buttonText = '';
        let confirmText = '';

        if (isPending) {
            buttonText = window.translations.job_contract_cancel;
            confirmText = window.translations.job_contract_cancel_pending_confirm;
        } else if (isActive && contractType === 'rent') {
            buttonText = window.translations.job_contract_terminate;
            confirmText = window.translations.job_contract_terminate_rent_confirm;
        } else {
            buttonText = window.translations.job_contract_terminate;
            confirmText = window.translations.job_contract_terminate_sale_confirm;
        }

        const cancelBtn = $('<button>')
            .attr('type', 'button')
            .addClass('action-btn')
            .addClass('danger-btn')
            .text(buttonText);

        cancelBtn.on('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            showJobConfirm(confirmText, window.translations.job_modal_confirmation, function (confirmed) {
                if (confirmed) {
                    cancelContract(contract.id, contract.houseId);
                }
            });
        });

        actions.append(cancelBtn);
    }

    if (actions.children().length === 2) {
        actions.addClass('pair-actions');
    }

    return actions;
}

function getContractTypeGroup(contract) {
    const type = String(contract && contract.type ? contract.type : '').toLowerCase();
    if (type === 'sale' || type === 'rent') {
        return type;
    }
    return 'other';
}

function getContractTypeLabel(type) {
    if (type === 'stats') {
        return window.translations.job_contract_stats;
    }
    if (type === 'sale') {
        return window.translations.job_contract_type_sale;
    }
    if (type === 'rent') {
        return window.translations.job_contract_type_rent;
    }
    if (type === 'unpaid') {
        return window.translations.job_tab_unpaid;
    }
    return window.translations.job_contract_type_other;
}

function getContractStatusText(status) {
    const key = String(status || '').toLowerCase();
    const statusTextByKey = {
        pending: window.translations.job_contract_status_pending,
        active: window.translations.job_contract_status_active,
        completed: window.translations.job_contract_status_completed,
        cancelled: window.translations.job_contract_status_cancelled,
        expired: window.translations.job_contract_status_expired
    };
    return statusTextByKey[key] || status || (window.translations.job_contract_status_pending);
}

function getContractTitle(contract, typeText) {
    const defaultTitle = getContractDefaultTitle(contract, typeText);
    return contract.name || defaultTitle;
}

function getContractDefaultTitle(contract, typeText) {
    const contractNumberText = window.translations.job_contract_number;
    return `${contractNumberText}${contract.id || 'N/A'} - ${typeText}`;
}

function getContractUniqueKey(contract) {
    if (!contract) {
        return '';
    }
    if (!contract.id) {
        return `contract-house-${contract.houseId || '0'}`;
    }
    return `contract-${contract.id}`;
}

function getContractHouse(contract) {
    if (!contract) {
        return null;
    }
    return housesData.find(function (house) {
        return house.id === contract.houseId;
    }) || null;
}
function cancelContract(contractId, houseId) {
    $.post('http://next_housing/cancelContract', JSON.stringify({
        contractId: contractId || null,
        houseId: houseId || null
    }), function (response) {
        if (response === 'ok') {
            refreshContracts();
        }
    });
}

function createContractInfoItem(label, value) {
    const item = $('<div>').addClass('contract-info-item');
    item.append($('<span>').addClass('contract-info-label').text(label));
    item.append($('<span>').addClass('contract-info-value').text(value));
    return item;
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR');
}





let selectedHouseForBuy = null;

function openBuyHouseModal(house) {
    if (!house) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_modal_error);
        return;
    }
    selectedHouseForBuy = house;
    showBuyHouseChoice();
}

function showBuyHouseChoice() {
    if (!selectedHouseForBuy) return;

    const price = selectedHouseForBuy.price || 0;
    const acquisitionTitle = window.translations.job_modal_property_acquisition;
    const houseLabel = (window.translations.job_house_number).replace(/\s*#\s*$/, '').trim();
    const rawHouseName = (selectedHouseForBuy.name || '').toString().trim();
    const isNumericIdName = rawHouseName !== '' && rawHouseName === String(selectedHouseForBuy.id || '');
    const fallbackHouseName = `${window.translations.job_house_number}${selectedHouseForBuy.id || ''}`;
    const houseDisplayName = (rawHouseName !== '' && !isNumericIdName)
        ? rawHouseName
        : fallbackHouseName;
    window.ModalManager.open({
        title: window.translations.job_house_buy,
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
                        <span class="agency-house-buy-summary-label">${window.translations.job_house_price}</span>
                        <span class="agency-house-buy-summary-value agency-house-buy-summary-price">${formatPrice(price)}</span>
                    </div>
                </div>
                <div class="agency-house-buy-actions">
                    <button class="pap-btn primary multimodal-action-btn agency-house-buy-btn" id="agency-buy-online-choice-btn">
                        <i class="ph ph-globe"></i>
                        <span>${window.translations.job_house_buy_online}</span>
                    </button>
                    <button class="pap-btn secondary multimodal-action-btn agency-house-buy-btn" id="agency-buy-on-site-choice-btn">
                        <i class="ph ph-map-pin"></i>
                        <span>${window.translations.job_house_buy_on_site}</span>
                    </button>
                </div>
            </div>
        `,
        buttons: [
            {
                text: window.translations.job_modal_cancel_btn,
                class: 'pap-btn secondary multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function ($modal) {
            $modal.find('#agency-buy-online-choice-btn').on('click', function () {
                showBuyHousePayment();
            });
            $modal.find('#agency-buy-on-site-choice-btn').on('click', function () {
                buyHouseOnSite(selectedHouseForBuy);
            });
        },
        onClose: function () {
            selectedHouseForBuy = null;
        }
    });
}

function showBuyHousePayment() {
    if (!selectedHouseForBuy) return;

    const price = selectedHouseForBuy.price || 0;
    const acquisitionTitle = window.translations.job_modal_property_acquisition;
    const houseLabel = (window.translations.job_house_number).replace(/\s*#\s*$/, '').trim();
    const rawHouseName = (selectedHouseForBuy.name || '').toString().trim();
    const isNumericIdName = rawHouseName !== '' && rawHouseName === String(selectedHouseForBuy.id || '');
    const fallbackHouseName = `${window.translations.job_house_number}${selectedHouseForBuy.id || ''}`;
    const houseDisplayName = (rawHouseName !== '' && !isNumericIdName)
        ? rawHouseName
        : fallbackHouseName;
    window.ModalManager.open({
        title: window.translations.job_house_buy,
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
                        <span class="agency-house-buy-summary-label">${window.translations.job_house_price}</span>
                        <span class="agency-house-buy-summary-value agency-house-buy-summary-price">${formatPrice(price)}</span>
                    </div>
                </div>
                <div class="agency-house-buy-actions">
                    <div class="agency-house-buy-section-label">${window.translations.job_buy_payment_method}</div>
                    <button class="pap-btn primary multimodal-action-btn agency-house-buy-btn" id="agency-buy-treasury-btn">
                        <i class="ph ph-bank"></i>
                        <span>${window.translations.job_buy_with_treasury}</span>
                    </button>
                    <button class="pap-btn secondary multimodal-action-btn agency-house-buy-btn" id="agency-buy-bank-btn">
                        <i class="ph ph-credit-card"></i>
                        <span>${window.translations.job_buy_with_bank}</span>
                    </button>
                    <button class="pap-btn secondary multimodal-action-btn agency-house-buy-btn" id="agency-buy-cash-btn">
                        <i class="ph ph-money-wavy"></i>
                        <span>${window.translations.job_buy_with_cash}</span>
                    </button>
                </div>
            </div>
        `,
        buttons: [
            {
                text: window.translations.job_modal_cancel_btn,
                class: 'pap-btn secondary multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function ($modal) {
            $modal.find('#agency-buy-treasury-btn').on('click', () => buyHouseOnline(selectedHouseForBuy, 'treasury'));
            $modal.find('#agency-buy-bank-btn').on('click', () => buyHouseOnline(selectedHouseForBuy, 'bank'));
            $modal.find('#agency-buy-cash-btn').on('click', () => buyHouseOnline(selectedHouseForBuy, 'cash'));
        },
        onClose: function () {
            selectedHouseForBuy = null;
        }
    });
}

function buyHouseOnline(house, paymentMethod) {
    if (!house) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_modal_error);
        return;
    }

    const price = house.price || 0;
    if (price <= 0) {
        showJobAlert(window.translations.job_error_invalid_price, window.translations.job_modal_error);
        return;
    }

    if (!paymentMethod || (paymentMethod !== 'treasury' && paymentMethod !== 'bank' && paymentMethod !== 'cash')) {
        paymentMethod = 'treasury';
    }

    let confirmMessage = '';
    if (paymentMethod === 'treasury') {
        confirmMessage = (window.translations.job_confirm_buy_house_treasury).replace('%s', formatPrice(price));
    } else if (paymentMethod === 'bank') {
        confirmMessage = (window.translations.job_confirm_buy_house_bank).replace('%s', formatPrice(price));
    } else if (paymentMethod === 'cash') {
        confirmMessage = (window.translations.job_confirm_buy_house_cash).replace('%s', formatPrice(price));
    }

    showJobConfirm(confirmMessage, window.translations.job_modal_confirmation, function (confirmed) {
        if (confirmed) {
            window.ModalManager.close();
            $.post('http://next_housing/buyHouseForAgency', JSON.stringify({
                houseId: house.id,
                paymentMethod: paymentMethod
            }), function (response) {
                if (response === 'ok') {
                    refreshHouses();
                    refreshTreasury();
                } else {
                    showJobAlert(window.translations.job_error_buy_house_failed, window.translations.job_modal_error);
                }
            }).fail(function () {
                showJobAlert(window.translations.job_error_buy_house_failed, window.translations.job_modal_error);
            });
        }
    });
}

function viewHouseOnMap(coords, houseId) {
    if (!coords || !coords.x || !coords.y) {
        showJobAlert(window.translations.job_notification_invalid_coords, window.translations.job_modal_error);
        return;
    }

    const resourceName = jobGetResourceName();

    fetch(`https://${resourceName}/viewOnMap`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            coords: coords,
            houseId: houseId
        })
    }).catch(function (error) {
        
        console.error('Erreur lors de la dÃ©finition du waypoint:', error);
    });
}

function buyHouseOnSite(house) {
    if (!house) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_modal_error);
        return;
    }

    if (!house.coords || !house.coords.x || !house.coords.y) {
        showJobAlert(window.translations.job_notification_invalid_coords, window.translations.job_modal_error);
        return;
    }

    window.ModalManager.close();

    $.post('http://next_housing/viewOnMap', JSON.stringify({
        coords: house.coords,
        houseId: house.id
    }), function (response) {
        if (response === 'ok') {
            const message = (window.translations.job_waypoint_set_buy).replace('%s', house.id);
            showJobAlert(message, window.translations.job_modal_info);

            $.post('http://next_housing/enableAgencyBuyOnSite', JSON.stringify({
                houseId: house.id
            }));
        }
    });
}





function openCreateContractModal(house) {
    if (!house || typeof house !== 'object') {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_error_error);
        return;
    }

    selectedHouseForContract = house;

    const locationLabel = window.translations.job_contract_location_label;
    const currentPriceLabel = window.translations.job_contract_current_price_label;
    const notDefined = window.translations.job_contract_not_defined;
    const houseNumber = window.translations.job_house_number;
    const houseDisplayName = (house && house.name && String(house.name).trim())
        ? String(house.name).trim()
        : `${houseNumber}${house.id}`;
    const naText = window.translations.job_contract_na;
    const monthOption = window.translations.job_contract_month_option;
    const currentPriceValue = formatPriceDisplayValue(house.price, notDefined);
    const currentPriceNumeric = Number(house.price);
    const initialContractPrice = Number.isFinite(currentPriceNumeric) ? Math.max(0, Math.floor(currentPriceNumeric)) : 0;

    const safeInfoTitle = escapeModalHtml(window.translations.job_contract_quick_info);
    const safeConditionsTitle = escapeModalHtml(window.translations.job_contract_conditions);
    const safeLocationLabel = escapeModalHtml(locationLabel);
    const safeCurrentPriceLabel = escapeModalHtml(currentPriceLabel);
    const safeZoneName = escapeModalHtml(house.zoneName || naText);
    const safeCurrentPriceValue = escapeModalHtml(currentPriceValue);
    const safeTypeLabel = escapeModalHtml(window.translations.job_contract_type_label);
    const safeSaleLabel = escapeModalHtml(window.translations.job_contract_type_sale);
    const safeRentLabel = escapeModalHtml(window.translations.job_contract_type_rent);
    const safePlayerIdLabel = escapeModalHtml(window.translations.job_contract_player_id_label);
    const safePriceInputLabel = escapeModalHtml(window.translations.job_contract_price_label_input);
    const safeDurationLabel = escapeModalHtml(window.translations.job_contract_duration_label);
    const safeMonthOption1 = escapeModalHtml(monthOption.replace('%s', '1'));
    const safeMonthOption3 = escapeModalHtml(monthOption.replace('%s', '3'));
    const safeMonthOption6 = escapeModalHtml(monthOption.replace('%s', '6'));
    const safeMonthOption12 = escapeModalHtml(monthOption.replace('%s', '12'));

    window.ModalManager.open({
        title: window.translations.job_contract_create,
        containerClass: 'agency-contract-modal',
        hint: houseDisplayName,
        mainBlockHeader: {
            title: window.translations.job_contract_conditions,
            target: '.agency-contract-create-modal'
        },
        footerClass: 'agency-contract-footer',
        bodyHTML: `
            <div class="agency-modal-main-block agency-contract-create-modal">
                <div class="agency-contract-info-title">${safeInfoTitle}</div>
                <div class="agency-contract-house-grid">
                    <div class="agency-contract-house-row">
                        <span class="agency-contract-house-label">${safeLocationLabel}</span>
                        <span class="agency-contract-house-value">${safeZoneName}</span>
                    </div>
                    <div class="agency-contract-house-row">
                        <span class="agency-contract-house-label">${safeCurrentPriceLabel}</span>
                        <span class="agency-contract-house-value">${safeCurrentPriceValue}</span>
                    </div>
                </div>

                <div class="agency-contract-conditions-title">${safeConditionsTitle}</div>
                <div class="agency-contract-fields">
                    <div class="agency-contract-form-row">
                        <div class="pap-form-group agency-contract-field">
                            <label class="pap-form-label">${safeTypeLabel}</label>
                            <select class="pap-form-select agency-contract-control" id="contract-type">
                                <option value="sale">${safeSaleLabel}</option>
                                <option value="rent">${safeRentLabel}</option>
                            </select>
                        </div>

                        <div class="pap-form-group agency-contract-field">
                            <label class="pap-form-label">${safePlayerIdLabel}</label>
                            <input type="number" min="1" class="pap-form-input agency-contract-control" id="contract-player-id" placeholder="Ex: 1">
                        </div>
                    </div>

                    <div class="pap-form-group agency-contract-field">
                        <label class="pap-form-label" id="contract-price-label">${safePriceInputLabel}</label>
                        <input type="number" min="1" class="pap-form-input agency-contract-control" id="contract-price" value="${initialContractPrice}">
                    </div>

                    <div class="pap-form-group agency-contract-field" id="contract-duration-group" style="display: none;">
                        <label class="pap-form-label">${safeDurationLabel}</label>
                        <select class="pap-form-select agency-contract-control" id="contract-duration">
                            <option value="1">${safeMonthOption1}</option>
                            <option value="3">${safeMonthOption3}</option>
                            <option value="6">${safeMonthOption6}</option>
                            <option value="12" selected>${safeMonthOption12}</option>
                        </select>
                    </div>
                </div>
            </div>
        `,
        buttons: [
            {
                text: `<i class="ph ph-paper-plane-tilt"></i><span>${window.translations.job_modal_create_contract}</span>`,
                class: 'pap-btn secondary agency-contract-btn multimodal-action-btn',
                onClick: function () {
                    createContract();
                }
            }
        ],
        onOpen: function ($modal) {
            const $type = $modal.find('#contract-type');
            const $durationGroup = $modal.find('#contract-duration-group');
            const $duration = $modal.find('#contract-duration');
            const $priceLabel = $modal.find('#contract-price-label');
            const rentLabel = formatCurrencyLabel(window.translations.job_contract_rent_price_label, 'Loyer mensuel');
            const saleBaseLabel = window.translations.job_contract_price_label_input;
            const saleLabel = formatCurrencyLabel(window.translations.job_contract_sale_price_label, saleBaseLabel);

            const syncCreateContractForm = function () {
                const isRent = $type.val() === 'rent';
                $durationGroup.toggle(isRent);
                $priceLabel.text(isRent ? rentLabel : saleLabel);

                if (isRent && (!$duration.val() || parseInt($duration.val(), 10) <= 0)) {
                    $duration.val('12');
                }

                if (isRent && window.refreshCustomDropdown) {
                    window.refreshCustomDropdown('contract-duration');
                }
            };

            $type.on('change', syncCreateContractForm);
            syncCreateContractForm();

            if (window.refreshCustomDropdown) {
                window.refreshCustomDropdown('contract-type');
                window.refreshCustomDropdown('contract-duration');
            }
        },
        onClose: function () {
            selectedHouseForContract = null;
        }
    });
}

function createContract() {
    const type = $('#contract-type').val();
    const playerId = parseInt($('#contract-player-id').val(), 10);
    const price = parseInt($('#contract-price').val(), 10);
    const duration = type === 'rent' ? parseInt($('#contract-duration').val(), 10) : null;

    if (!playerId || playerId <= 0) {
        showJobAlert(window.translations.job_error_invalid_player_id, window.translations.job_error_error);
        return;
    }

    if (!price || price <= 0) {
        showJobAlert(window.translations.job_error_invalid_price, window.translations.job_error_error);
        return;
    }

    if (type === 'rent' && (!duration || duration <= 0)) {
        showJobAlert(window.translations.job_error_select_duration, window.translations.job_error_error);
        return;
    }

    if (!selectedHouseForContract) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_error_error);
        return;
    }

    $.post('http://next_housing/createContract', JSON.stringify({
        houseId: selectedHouseForContract.id,
        type: type,
        playerId: playerId,
        price: price,
        duration: duration
    }), function (response) {
        if (response === 'ok') {
            window.ModalManager.close();
            refreshContracts();
            if ($('#job-tab-contracts').hasClass('active')) {
                switchTab('contracts');
            }
        }
    });
}

let selectedContractForEdit = null;

function openEditContractModal(contract) {
    selectedContractForEdit = contract;

    const house = housesData.find(function (h) {
        return h.id === contract.houseId;
    });

    if (!house) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_error_error);
        return;
    }

    const locationLabel = window.translations.job_contract_location_label;
    const currentPriceLabel = window.translations.job_contract_current_price_label;
    const notDefined = window.translations.job_contract_not_defined;
    const houseNumber = window.translations.job_house_number;
    const naText = window.translations.job_contract_na;
    const monthOption = window.translations.job_contract_month_option;

    window.ModalManager.open({
        title: window.translations.job_contract_edit,
        bodyHTML: `
            <div id="edit-contract-house-info" style="margin-bottom: 20px; text-align: center; background: var(--input); padding: 10px; border-radius: 8px;">
                <p><strong>${houseNumber}${house.id}</strong></p>
                <p>${locationLabel} ${house.zoneName || naText}</p>
                <p>${currentPriceLabel} ${formatPriceDisplayValue(house.price, notDefined)}</p>
            </div>
            
            <div class="pap-form-group">
                <label class="pap-form-label">${window.translations.job_contract_player_id_label}</label>
                <input type="number" class="pap-form-input" id="edit-contract-player-id" value="${contract.playerId || ''}" disabled style="opacity: 0.6; cursor: not-allowed;">
            </div>

            <div class="pap-form-group">
                <label class="pap-form-label">${window.translations.job_contract_price_label_input}</label>
                <input type="number" class="pap-form-input" id="edit-contract-price" value="${contract.price || 0}">
            </div>

            <div class="pap-form-group">
                <label class="pap-form-label">${window.translations.job_contract_duration_label}</label>
                <select class="pap-form-select" id="edit-contract-duration" data-custom-dropdown-disabled="true">
                    <option value="1" ${contract.durationMonths == 1 ? 'selected' : ''}>${monthOption.replace('%s', '1')}</option>
                    <option value="3" ${contract.durationMonths == 3 ? 'selected' : ''}>${monthOption.replace('%s', '3')}</option>
                    <option value="6" ${contract.durationMonths == 6 ? 'selected' : ''}>${monthOption.replace('%s', '6')}</option>
                    <option value="12" ${contract.durationMonths == 12 ? 'selected' : ''}>${monthOption.replace('%s', '12')}</option>
                </select>
            </div>
        `,
        buttons: [
            {
                text: window.translations.job_modal_save,
                class: 'pap-btn primary',
                onClick: function () {
                    updateContract();
                }
            },
            {
                text: window.translations.job_modal_cancel_btn,
                class: 'pap-btn secondary',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function () { },
        onClose: function () {
            selectedContractForEdit = null;
        }
    });
}



function updateContract() {
    if (!selectedContractForEdit) {
        showJobAlert(window.translations.job_error_no_house_selected, window.translations.job_error_error);
        return;
    }

    const price = parseInt($('#edit-contract-price').val());
    const duration = parseInt($('#edit-contract-duration').val());

    if (!price || price <= 0) {
        showJobAlert(window.translations.job_error_invalid_price, window.translations.job_error_error);
        return;
    }

    if (!duration || duration <= 0) {
        showJobAlert(window.translations.job_error_select_duration, window.translations.job_error_error);
        return;
    }

    $.post('http://next_housing/updateContract', JSON.stringify({
        contractId: selectedContractForEdit.id,
        price: price,
        duration: duration
    }), function (response) {
        if (response === 'ok') {
            window.ModalManager.close();
            refreshContracts();
            if ($('#job-tab-contracts').hasClass('active')) {
                switchTab('contracts');
            }
        } else {
            showJobAlert(response, window.translations.job_error_error);
        }
    });
}







function refreshUnpaid() {
    const unpaidLoading = $('#unpaid-loading');
    if (!hasRenderedUnpaid && unpaidLoading.length > 0) {
        unpaidLoading.removeClass('hidden');
    }
    const unpaidEmptyState = $('#unpaid-empty-state');
    if (unpaidEmptyState.length > 0) {
        unpaidEmptyState.addClass('hidden');
    }

    $.post('http://next_housing/getUnpaidRentals', JSON.stringify({}), function (response) {
        if (unpaidLoading.length > 0) {
            unpaidLoading.addClass('hidden');
        }
    });
}





function displayContractToPlayer(contract) {
    $('#contract-number-display').text(contract.id);
    $('#contract-agent-name').text(contract.agentName || (window.translations.job_contract_seller_label && window.translations.job_contract_seller_label.split(':')[0]));
    $('#contract-player-name').text(contract.playerName || (window.translations.job_contract_buyer_label && window.translations.job_contract_buyer_label.split(':')[0]));

    const houseNumber = window.translations.job_house_number;
    $('#contract-house-id').text(houseNumber + contract.houseId);
    const naText = window.translations.job_contract_na;
    $('#contract-house-location').text(contract.houseLocation || naText);

    const interiorPrefix = window.translations.job_contract_interior_prefix;
    $('#contract-house-interior').text(interiorPrefix + (contract.houseInterior || 1));

    $('#contract-house-garage').text(getGarageAvailabilityLabel(contract.hasGarage));

    if (contract.type === 'sale') {
        const saleType = window.translations.job_contract_type_sale_upper;
        const priceLabel = window.translations.job_contract_price_label;
        $('#contract-type-display').text(saleType);
        $('#contract-price-display').html('<strong>' + priceLabel + '</strong> <span>' + formatPrice(contract.price) + '</span>');
        $('#contract-duration-display').hide();
        $('#contract-monthly-display').hide();
    } else {
        const rentType = window.translations.job_contract_type_rent_upper;
        const monthlyRentLabel = window.translations.job_contract_monthly_rent_label;
        const durationLabel = window.translations.job_contract_duration_label_contract;
        const monthsText = window.translations.job_contract_duration_months;

        $('#contract-type-display').text(rentType);
        $('#contract-price-display').html('<strong>' + monthlyRentLabel + '</strong> <span>' + formatPrice(contract.price) + '</span>');
        $('#contract-duration-display').show().html('<strong>' + durationLabel + '</strong> <span>' + (contract.durationMonths || 0) + ' ' + monthsText + '</span>');
        $('#contract-monthly-display').show().html('<strong>' + monthlyRentLabel + '</strong> <span>' + formatPrice(contract.price) + '</span>');
    }

    initSignatureCanvas();

    hideSignatureError();

    $('#player-contract-interface').data('contract-id', contract.id);

    translateJobInterface();

    $('#player-contract-interface').removeClass('hidden');
}

function signContract() {
    if (!hasSignature()) {
        showSignatureError();
        return;
    }

    hideSignatureError();

    let contractId = $('#player-contract-interface').data('contract-id');
    if (!contractId) {
        showJobAlert(window.translations.job_error_contract_not_found, window.translations.job_error_error);
        return;
    }

    contractId = parseInt(contractId, 10);
    if (isNaN(contractId)) {
        showJobAlert(window.translations.job_error_invalid_contract_id, window.translations.job_error_error);
        return;
    }

    const $btn = $('#sign-contract-btn');
    const processingText = window.translations.job_contract_processing;
    $btn.prop('disabled', true).text(processingText);

    const timeout = setTimeout(function () {
        const acceptText = window.translations.job_contract_accept;
        $btn.prop('disabled', false).text(acceptText);
        showJobAlert(window.translations.job_error_timeout, window.translations.job_error_error);
    }, 10000);

    $.post('https://next_housing/signContract', JSON.stringify({
        contractId: contractId
    }), function (response) {
        clearTimeout(timeout);
        const result = typeof response === 'string' ? JSON.parse(response) : response;

        if (result.success) {
            const acceptText = window.translations.job_contract_accept;
            $btn.prop('disabled', false).text(acceptText);

            const successMsg = window.translations.job_notification_contract_signed || result.message;
            const keepJobFocus = closePlayerContractInterface();

            if (keepJobFocus) {
                showJobAlert(successMsg, window.translations.job_success);
            } else {
                $.post('https://next_housing/notify', JSON.stringify({
                    message: successMsg,
                    type: 'success',
                    duration: 5000
                }));
            }
        } else {
            const acceptText = window.translations.job_contract_accept;
            $btn.prop('disabled', false).text(acceptText);
            showJobAlert(result.message || (window.translations.job_error_sign_failed), window.translations.job_error_error);
        }
    }).fail(function (jqXHR, textStatus, errorThrown) {
        clearTimeout(timeout);
        const acceptText = window.translations.job_contract_accept;
        $btn.prop('disabled', false).text(acceptText);
        closePlayerContractInterface();
        showJobAlert(window.translations.job_error_connection, window.translations.job_error_error);
    });
}

function declineContractOnClose() {
    let contractId = $('#player-contract-interface').data('contract-id');
    if (!contractId) {
        closePlayerContractInterface();
        return;
    }

    contractId = parseInt(contractId, 10);
    if (isNaN(contractId)) {
        closePlayerContractInterface();
        return;
    }

    closePlayerContractInterface();

    $.post('https://next_housing/declineContract', JSON.stringify({
        contractId: contractId
    }), function (response) {
    }).fail(function () {
    });
}

function declineContract() {
    let contractId = $('#player-contract-interface').data('contract-id');
    if (!contractId) {
        showJobAlert(window.translations.job_error_contract_not_found, window.translations.job_error_error);
        return;
    }

    contractId = parseInt(contractId, 10);
    if (isNaN(contractId)) {
        showJobAlert(window.translations.job_error_invalid_contract_id, window.translations.job_error_error);
        return;
    }

    const $btn = $('#decline-contract-btn');
    const processingText = window.translations.job_contract_processing;
    $btn.prop('disabled', true).text(processingText);

    const timeout = setTimeout(function () {
        const declineText = window.translations.job_contract_decline;
        $btn.prop('disabled', false).text(declineText);
        showJobAlert(window.translations.job_error_timeout, window.translations.job_error_error);
    }, 10000);

    $.post('https://next_housing/declineContract', JSON.stringify({
        contractId: contractId
    }), function (response) {
        clearTimeout(timeout);
        const result = typeof response === 'string' ? JSON.parse(response) : response;

        if (result.success) {
            const declineText = window.translations.job_contract_decline;
            $btn.prop('disabled', false).text(declineText);

            closePlayerContractInterface();
        } else {
            const declineText = window.translations.job_contract_decline;
            $btn.prop('disabled', false).text(declineText);
            showJobAlert(result.message || (window.translations.job_error_decline_failed), window.translations.job_error_error);
        }
    }).fail(function () {
        clearTimeout(timeout);
        const declineText = window.translations.job_contract_decline;
        $btn.prop('disabled', false).text(declineText);
        closePlayerContractInterface();
        showJobAlert(window.translations.job_error_connection, window.translations.job_error_error);
    });
}

function closePlayerContractInterface(forcedKeepJobFocus, skipNuiCallback) {
    const keepJobFocus = typeof forcedKeepJobFocus === 'boolean'
        ? forcedKeepJobFocus
        : !$('#job-interface').hasClass('hidden');
    $('#player-contract-interface').addClass('hidden');
    if (!skipNuiCallback) {
        $.post('https://next_housing/closeContractInterface', JSON.stringify({
            keepJobFocus: keepJobFocus
        }));
    }
    return keepJobFocus;
}





function refreshTreasury() {
    if (!hasRenderedTreasury) {
        $('#treasury-loading').removeClass('hidden');
    }

    $.post('https://next_housing/getTreasury', JSON.stringify({}), function (response) {
    }).fail(function () {
        $('#treasury-loading').addClass('hidden');
    });

    checkTreasuryWithdrawAccess();
}

function checkTreasuryWithdrawAccess() {
    $.post('https://next_housing/getTreasuryWithdrawGradeInfo', JSON.stringify({}), function (response) {
        try {
            const data = typeof response === 'string' ? JSON.parse(response) : response;
            const $overlay = $('#treasury-withdraw-overlay');
            const $card = $('.treasury-withdraw-card');
            const $input = $('#treasury-withdraw-amount');
            const $btn = $('#treasury-withdraw-btn');

            if (data && data.hasAccess === false) {
                $overlay.removeClass('hidden');
                $card.addClass('disabled');
                $input.prop('disabled', true);
                $btn.prop('disabled', true);
            } else {
                $overlay.addClass('hidden');
                $card.removeClass('disabled');
                $input.prop('disabled', false);
                $btn.prop('disabled', false);
            }
        } catch (e) {
            console.error('Error checking treasury withdraw access:', e);
        }
    }).fail(function () {
        $('#treasury-withdraw-overlay').addClass('hidden');
        $('.treasury-withdraw-card').removeClass('disabled');
        $('#treasury-withdraw-amount').prop('disabled', false);
        $('#treasury-withdraw-btn').prop('disabled', false);
    });
}

function withdrawTreasury() {
    const amount = parseInt($('#treasury-withdraw-amount').val());

    if (!amount || amount <= 0) {
        return;
    }

    const $btn = $('#treasury-withdraw-btn');
    const processingText = window.translations.job_treasury_processing;
    $btn.prop('disabled', true).html('<span class="btn-icon">&#9203;</span><span class="btn-text">' + processingText + '</span>');

    $.post('http://next_housing/withdrawTreasury', JSON.stringify({
        amount: amount
    }), function (response) {
    }).fail(function () {
        const $btn = $('#treasury-withdraw-btn');
        const withdrawText = window.translations.job_treasury_withdraw_btn;
        $btn.prop('disabled', false).html('<span class="btn-icon">&#10003;</span><span class="btn-text">' + withdrawText + '</span>');
    });
}






let signatureCanvas = null;
let signatureContext = null;
let isDrawing = false;
let lastX = 0;
let lastY = 0;

function initSignatureCanvas() {
    const canvas = document.getElementById('player-signature-canvas');
    if (!canvas) return;

    signatureCanvas = canvas;


    canvas.width = 200;
    canvas.height = 60;

    signatureContext = canvas.getContext('2d');
    signatureContext.strokeStyle = '#2c2c2c';
    signatureContext.lineWidth = 2;
    signatureContext.lineCap = 'round';
    signatureContext.lineJoin = 'round';

    clearSignature();

    canvas.removeEventListener('mousedown', startDrawing);
    canvas.removeEventListener('mousemove', draw);
    canvas.removeEventListener('mouseup', stopDrawing);
    canvas.removeEventListener('mouseout', stopDrawing);
    canvas.removeEventListener('touchstart', handleTouchStart);
    canvas.removeEventListener('touchmove', handleTouchMove);
    canvas.removeEventListener('touchend', stopDrawing);

    canvas.addEventListener('mousedown', startDrawing);
    canvas.addEventListener('mousemove', draw);
    canvas.addEventListener('mouseup', stopDrawing);
    canvas.addEventListener('mouseout', stopDrawing);

    canvas.addEventListener('touchstart', handleTouchStart, { passive: false });
    canvas.addEventListener('touchmove', handleTouchMove, { passive: false });
    canvas.addEventListener('touchend', stopDrawing);
}

function startDrawing(e) {
    isDrawing = true;
    const rect = signatureCanvas.getBoundingClientRect();
    const scaleX = signatureCanvas.width / rect.width;
    const scaleY = signatureCanvas.height / rect.height;
    lastX = (e.clientX - rect.left) * scaleX;
    lastY = (e.clientY - rect.top) * scaleY;

    signatureContext.beginPath();
    signatureContext.arc(lastX, lastY, 1.5, 0, 2 * Math.PI);
    signatureContext.fill();

    showClearIcon();
    hideSignatureError();
}

function draw(e) {
    if (!isDrawing) return;

    e.preventDefault();
    const rect = signatureCanvas.getBoundingClientRect();
    const scaleX = signatureCanvas.width / rect.width;
    const scaleY = signatureCanvas.height / rect.height;
    const currentX = (e.clientX - rect.left) * scaleX;
    const currentY = (e.clientY - rect.top) * scaleY;

    signatureContext.beginPath();
    signatureContext.moveTo(lastX, lastY);
    signatureContext.lineTo(currentX, currentY);
    signatureContext.stroke();

    lastX = currentX;
    lastY = currentY;

    showClearIcon();
    hideSignatureError();
}

function stopDrawing() {
    isDrawing = false;
}

function handleTouchStart(e) {
    e.preventDefault();
    const touch = e.touches[0];
    const rect = signatureCanvas.getBoundingClientRect();
    const scaleX = signatureCanvas.width / rect.width;
    const scaleY = signatureCanvas.height / rect.height;
    isDrawing = true;
    lastX = (touch.clientX - rect.left) * scaleX;
    lastY = (touch.clientY - rect.top) * scaleY;

    signatureContext.beginPath();
    signatureContext.arc(lastX, lastY, 1.5, 0, 2 * Math.PI);
    signatureContext.fill();

    showClearIcon();
    hideSignatureError();
}

function handleTouchMove(e) {
    if (!isDrawing) return;
    e.preventDefault();
    const touch = e.touches[0];
    const rect = signatureCanvas.getBoundingClientRect();
    const scaleX = signatureCanvas.width / rect.width;
    const scaleY = signatureCanvas.height / rect.height;
    const currentX = (touch.clientX - rect.left) * scaleX;
    const currentY = (touch.clientY - rect.top) * scaleY;

    signatureContext.beginPath();
    signatureContext.moveTo(lastX, lastY);
    signatureContext.lineTo(currentX, currentY);
    signatureContext.stroke();

    lastX = currentX;
    lastY = currentY;

    showClearIcon();
    hideSignatureError();
}

function clearSignature() {
    if (!signatureContext || !signatureCanvas) return;
    signatureContext.clearRect(0, 0, signatureCanvas.width, signatureCanvas.height);
    hideClearIcon();
    hideSignatureError();
}

function showClearIcon() {
    const clearIcon = document.getElementById('clear-signature-icon');
    if (clearIcon) {
        clearIcon.classList.add('visible');
    }
}

function hideClearIcon() {
    const clearIcon = document.getElementById('clear-signature-icon');
    if (clearIcon) {
        clearIcon.classList.remove('visible');
    }
}

function hasSignature() {
    if (!signatureContext || !signatureCanvas) return false;
    const imageData = signatureContext.getImageData(0, 0, signatureCanvas.width, signatureCanvas.height);
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
        if (data[i + 3] !== 0) {
            return true;
        }
    }
    return false;
}

function showSignatureError() {
    const $errorMsg = $('#signature-error-message');
    if ($errorMsg) {
        $errorMsg.addClass('visible');
        setTimeout(function () {
            hideSignatureError();
        }, 2000);
    }
}

function hideSignatureError() {
    const $errorMsg = $('#signature-error-message');
    if ($errorMsg) {
        $errorMsg.removeClass('visible');
    }
}
