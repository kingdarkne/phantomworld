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
let papTranslations = {};
let papMyProperties = [];
let papListings = [];
let papMyListings = [];
let papContracts = [];
let papCurrentTab = 'my-properties';
let papCurrentListingsView = 'merged';
let papCurrentManagementView = 'offers';
let papListingsTypeFilter = 'all';
let papListingsSortFilter = 'recent';
let papListingsSearch = '';
let papMyPropertiesNeedsRefresh = false;
const PAP_HEAVY_LIST_IMAGE_DATA_URL_LENGTH = 150000;
let papPropertyDetailsCache = new Map();
let papSelectedProperty = null;
let papSelectedPropertyInfo = null;
let papCurrentContract = null;
let papContractOpenedWithMenuVisible = false;
let papPendingSignRequest = null;
let papModalOpen = false;
let papHousePreviewPlaceholdersEnabled = true;
let papHousePreviewPlaceholdersLoaded = false;
const PAP_SCROLL_CONTAINERS_SELECTOR = '#pap-tab-my-properties .houses-list-container, #pap-tab-listings #pap-listings-unified, #pap-tab-contracts #pap-management-unified';
const papScrollVisibilityTimers = new WeakMap();
const papLastScrollTop = new WeakMap();
const PAP_DEFAULT_COMMAND = 'classifieds';

if (typeof window.currencySymbol === 'undefined') {
    window.currencySymbol = '$';
}

function papLoadCurrencySymbol() {
    try {
        let resourceName = 'next_housing';
        try {
            if (typeof GetParentResourceName === 'function') {
                const current = GetParentResourceName();
                if (current && current !== '') {
                    resourceName = current;
                }
            }
        } catch (_) {
        }

        $.post(`https://${resourceName}/getCurrencySymbol`, JSON.stringify({}), function (resp) {
            try {
                const data = (typeof resp === 'string') ? JSON.parse(resp) : (resp || {});
                if (data && data.symbol && data.symbol !== '') {
                    window.currencySymbol = data.symbol;
                }
            } catch (e) {
            }
        }).fail(function () {
        });
    } catch (e) {
    }
}

function papEnsureCurrencySymbol() {
    if (!window.currencySymbol || window.currencySymbol === '') {
        if (typeof loadCurrencySymbol === 'function') {
            loadCurrencySymbol();
        } else {
            papLoadCurrencySymbol();
        }
        return '$';
    }
    return window.currencySymbol;
}

function papNormalizeCommandHint(command, fallbackCommand) {
    const fallback = String(fallbackCommand || '').trim().replace(/^\/+/, '') || 'command';
    const normalized = String(command || '').trim().replace(/^\/+/, '');
    return '/' + (normalized || fallback);
}

function papUpdateCommandHint(rawCommand) {
    const hint = document.getElementById('pap-command-hint');
    if (!hint) {
        return;
    }
    hint.textContent = papNormalizeCommandHint(rawCommand, PAP_DEFAULT_COMMAND);
}

function papClearContainerScrolling(element) {
    if (!element) {
        return;
    }

    const existingTimer = papScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
        papScrollVisibilityTimers.delete(element);
    }

    $(element).removeClass('is-scrolling');
}

function papMarkContainerScrolling(element) {
    if (!element) {
        return;
    }

    const maxScrollTop = Math.max(0, (element.scrollHeight || 0) - (element.clientHeight || 0));
    const scrollTop = Math.max(0, Math.min(element.scrollTop || 0, maxScrollTop));
    const previousTop = papLastScrollTop.has(element) ? papLastScrollTop.get(element) : null;
    papLastScrollTop.set(element, scrollTop);

    if (maxScrollTop <= 0) {
        papClearContainerScrolling(element);
        return;
    }

    const atEdge = scrollTop <= 0 || scrollTop >= (maxScrollTop - 1);
    if (previousTop !== null && atEdge && Math.abs(scrollTop - previousTop) < 0.5) {
        papClearContainerScrolling(element);
        return;
    }

    const $element = $(element);
    $element.addClass('is-scrolling');

    const existingTimer = papScrollVisibilityTimers.get(element);
    if (existingTimer) {
        clearTimeout(existingTimer);
    }

    const hideTimer = setTimeout(function () {
        $element.removeClass('is-scrolling');
        papScrollVisibilityTimers.delete(element);
    }, 220);

    papScrollVisibilityTimers.set(element, hideTimer);
}

function papShouldBlockEdgeWheel(element, deltaY) {
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

function papBindScrollVisibility() {
    $(PAP_SCROLL_CONTAINERS_SELECTOR).each(function () {
        if (this.dataset.scrollVisibilityBound === '1') return;
        this.dataset.scrollVisibilityBound = '1';
        this.classList.add('nh-scroll-managed');
        this.classList.add('pap-scroll');

        const element = this;
        papLastScrollTop.set(element, element.scrollTop || 0);
        element.addEventListener('scroll', function () {
            papMarkContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('mouseleave', function () {
            papClearContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('touchend', function () {
            papClearContainerScrolling(element);
        }, { passive: true });
        element.addEventListener('wheel', function (event) {
            const deltaY = typeof event.deltaY === 'number' ? event.deltaY : 0;
            if (papShouldBlockEdgeWheel(element, deltaY)) {
                papClearContainerScrolling(element);
                event.preventDefault();
                event.stopPropagation();
                return;
            }
            papMarkContainerScrolling(element);
        }, { passive: false });
    });
}





function papT(key) {
    return papTranslations[key] || key;
}

function papTf(key, ...args) {
    let text = papT(key);
    if (!args.length) return text;
    args.forEach(arg => {
        text = text.replace(/%[sd]/, arg);
    });
    return text;
}

function papGetGarageAvailabilityLabel(hasGarage) {
    if (window.nhGaragesEnabled === false) {
        return papT('pap_property_unavailable');
    }

    return hasGarage ? papT('pap_property_yes') : papT('pap_property_no');
}

function papNormalizeArray(data) {
    if (Array.isArray(data)) {
        return data;
    }

    if (!data || typeof data !== 'object') {
        return [];
    }

    const keys = Object.keys(data);
    if (keys.length === 0) {
        return [];
    }

    const numericKeys = keys.every(function (key) {
        return /^\d+$/.test(key);
    });

    if (numericKeys) {
        keys.sort(function (a, b) {
            return Number(a) - Number(b);
        });
    }

    return keys.map(function (key) {
        return data[key];
    });
}

function papQueueDataRefresh() {
    setTimeout(function () {
        $.post('https://next_housing/papRefreshData', JSON.stringify({}));
    }, 500);
}

function papRefreshVisiblePapView() {
    if (papCurrentTab === 'contracts') {
        if (papCurrentManagementView === 'offers') {
            const offers = papNormalizeArray(papContracts).filter(function (contract) {
                return contract && (contract.status === 'offer_pending' || contract.status === 'accepted');
            });

            if (offers.length === 0) {
                papToggleManagementView('contracts');
                return;
            }
        }

        papRenderContracts();
        return;
    }

    if (papCurrentTab === 'listings') {
        papToggleListingsView();
        return;
    }

    if (papCurrentTab === 'my-properties') {
        papRenderMyProperties();
    }
}

function papApplyAcceptedOfferLocally(offerId) {
    const numericOfferId = parseInt(offerId, 10);
    if (!Number.isFinite(numericOfferId) || numericOfferId <= 0) {
        return;
    }

    let acceptedHouseId = null;

    papContracts = papNormalizeArray(papContracts).map(function (contract) {
        if (parseInt(contract && contract.id, 10) === numericOfferId) {
            acceptedHouseId = parseInt(contract.houseId, 10) || contract.houseId || null;
            return {
                ...contract,
                status: 'accepted',
                canSign: false
            };
        }
        return contract;
    });

    papMyListings = papNormalizeArray(papMyListings).map(function (listing) {
        if (parseInt(listing && listing.id, 10) === numericOfferId) {
            if (acceptedHouseId === null && listing.houseId != null) {
                acceptedHouseId = parseInt(listing.houseId, 10) || listing.houseId;
            }

            return {
                ...listing,
                status: 'transaction',
                hasTransaction: true,
                hasPendingOffer: false,
                pendingOffers: 0
            };
        }
        return listing;
    });

    if (acceptedHouseId !== null) {
        const acceptedHouseIdNum = parseInt(acceptedHouseId, 10);
        papMyProperties = papNormalizeArray(papMyProperties).map(function (property) {
            const propertyIdNum = parseInt(property && property.id, 10);
            if (propertyIdNum === acceptedHouseIdNum) {
                return {
                    ...property,
                    hasListing: false,
                    hasTransaction: true
                };
            }
            return property;
        });
    }

    papRefreshVisiblePapView();
}

function papApplyOfferRevertedLocally(offerId) {
    const numericOfferId = parseInt(offerId, 10);
    if (!Number.isFinite(numericOfferId) || numericOfferId <= 0) {
        return;
    }

    let revertedHouseId = null;

    papContracts = papNormalizeArray(papContracts).filter(function (contract) {
        const isTarget = parseInt(contract && contract.id, 10) === numericOfferId;
        if (isTarget) {
            revertedHouseId = parseInt(contract.houseId, 10) || contract.houseId || null;
        }
        return !isTarget;
    });

    papMyListings = papNormalizeArray(papMyListings).map(function (listing) {
        if (parseInt(listing && listing.id, 10) === numericOfferId) {
            if (revertedHouseId === null && listing.houseId != null) {
                revertedHouseId = parseInt(listing.houseId, 10) || listing.houseId;
            }

            return {
                ...listing,
                status: 'active',
                hasTransaction: false,
                hasPendingOffer: false,
                pendingOffers: 0,
                buyerName: null,
                offerAmount: null
            };
        }
        return listing;
    });

    if (revertedHouseId !== null) {
        const revertedHouseIdNum = parseInt(revertedHouseId, 10);
        papMyProperties = papNormalizeArray(papMyProperties).map(function (property) {
            const propertyIdNum = parseInt(property && property.id, 10);
            if (propertyIdNum === revertedHouseIdNum) {
                return {
                    ...property,
                    hasListing: true,
                    hasTransaction: false
                };
            }
            return property;
        });
    }

    papRefreshVisiblePapView();
}

function papApplyListingDeletedLocally(listingId) {
    const numericListingId = parseInt(listingId, 10);
    if (!Number.isFinite(numericListingId) || numericListingId <= 0) {
        return;
    }

    let deletedHouseId = null;

    papMyListings = papNormalizeArray(papMyListings).filter(function (listing) {
        const isTarget = parseInt(listing && listing.id, 10) === numericListingId;
        if (isTarget) {
            deletedHouseId = parseInt(listing.houseId, 10) || listing.houseId || null;
        }
        return !isTarget;
    });

    papListings = papNormalizeArray(papListings).filter(function (listing) {
        return parseInt(listing && listing.id, 10) !== numericListingId;
    });

    if (deletedHouseId !== null) {
        const deletedHouseIdNum = parseInt(deletedHouseId, 10);
        papMyProperties = papNormalizeArray(papMyProperties).map(function (property) {
            const propertyIdNum = parseInt(property && property.id, 10);
            if (propertyIdNum === deletedHouseIdNum) {
                return {
                    ...property,
                    hasListing: false,
                    hasTransaction: false
                };
            }
            return property;
        });
    }

    papRefreshVisiblePapView();
}

function papApplyContractTerminatedLocally(contractId) {
    const numericContractId = parseInt(contractId, 10);
    if (!Number.isFinite(numericContractId) || numericContractId <= 0) {
        return;
    }

    papContracts = papNormalizeArray(papContracts).map(function (contract) {
        if (parseInt(contract && contract.id, 10) === numericContractId) {
            return {
                ...contract,
                status: 'terminated',
                canSign: false
            };
        }
        return contract;
    });

    papRefreshVisiblePapView();
}

function papApplyContractCompletedLocally(contractId) {
    const numericContractId = parseInt(contractId, 10);
    if (!Number.isFinite(numericContractId) || numericContractId <= 0) {
        return;
    }

    papContracts = papNormalizeArray(papContracts).map(function (contract) {
        if (parseInt(contract && contract.id, 10) === numericContractId) {
            return {
                ...contract,
                status: 'completed',
                canSign: false
            };
        }
        return contract;
    });

    papRefreshVisiblePapView();
}

function papEscapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function papEscapeJsString(text) {
    return String(text || '')
        .replace(/\\/g, '\\\\')
        .replace(/'/g, "\\'")
        .replace(/\r/g, '\\r')
        .replace(/\n/g, '\\n');
}

function papMergePropertyData(baseProperty, detailedProperty) {
    if (!baseProperty) {
        return detailedProperty || null;
    }

    if (!detailedProperty) {
        return baseProperty;
    }

    return {
        ...baseProperty,
        ...detailedProperty,
        images: Array.isArray(detailedProperty.images) ? detailedProperty.images : (baseProperty.images || []),
        listImage: detailedProperty.listImage || baseProperty.listImage || null,
    };
}

function papFetchPropertyDetails(propertyId, forceRefresh = false) {
    const numericPropertyId = parseInt(propertyId, 10);
    if (!Number.isFinite(numericPropertyId) || numericPropertyId <= 0) {
        return Promise.resolve(null);
    }

    const cacheKey = String(numericPropertyId);
    if (!forceRefresh && papPropertyDetailsCache.has(cacheKey)) {
        return Promise.resolve(papPropertyDetailsCache.get(cacheKey));
    }

    return new Promise(function (resolve) {
        $.post('https://next_housing/papGetPropertyDetails', JSON.stringify({
            propertyId: numericPropertyId
        }), function (resp) {
            let payload = resp;

            try {
                if (typeof resp === 'string') {
                    payload = JSON.parse(resp);
                }
            } catch (_) {
            }

            const property = payload && payload.success === true && payload.property
                ? payload.property
                : null;

            if (property) {
                papPropertyDetailsCache.set(cacheKey, property);
            }

            resolve(property);
        }).fail(function () {
            resolve(null);
        });
    });
}

let papChatModuleLoading = false;
let papChatModuleReadyCallbacks = [];

function papEnsureChatModule(onReady) {
    if (typeof window.papChatOpenChatImpl === 'function') {
        if (typeof onReady === 'function') onReady();
        return;
    }

    if (typeof onReady === 'function') {
        papChatModuleReadyCallbacks.push(onReady);
    }

    if (papChatModuleLoading) {
        return;
    }

    papChatModuleLoading = true;

    const script = document.createElement('script');
    script.src = 'assets/elements/js/chat.js?v=nh_20260228_v4';
    script.async = false;

    script.onload = function () {
        papChatModuleLoading = false;
        const callbacks = papChatModuleReadyCallbacks.slice();
        papChatModuleReadyCallbacks = [];
        callbacks.forEach(function (cb) {
            try {
                cb();
            } catch (e) {
            }
        });
    };

    script.onerror = function () {
        papChatModuleLoading = false;
        papChatModuleReadyCallbacks = [];
        console.error('[PAP] Failed to load chat.js');
    };

    document.head.appendChild(script);
}

function papOpenChat() {
    const args = arguments;
    const impl = window.papChatOpenChatImpl;
    if (typeof impl === 'function') {
        return impl.apply(window, args);
    }

    papEnsureChatModule(function () {
        const loadedImpl = window.papChatOpenChatImpl;
        if (typeof loadedImpl === 'function') {
            loadedImpl.apply(window, args);
        } else {
            console.error('[PAP] Chat module loaded but papChatOpenChatImpl is missing.');
        }
    });
}

function papHandleNewMessage(data) {
    const impl = window.papChatHandleNewMessageImpl;
    if (typeof impl === 'function') {
        impl(data);
        return;
    }

    papEnsureChatModule(function () {
        const loadedImpl = window.papChatHandleNewMessageImpl;
        if (typeof loadedImpl === 'function') {
            loadedImpl(data);
        }
    });
}

function papFormatPrice(price) {
    const symbol = papEnsureCurrencySymbol() || '$';
    const numeric = typeof price === 'number' ? price : parseFloat(price) || 0;
    return new Intl.NumberFormat('fr-FR').format(numeric) + ' ' + symbol;
}

function papFormatListingDate(createdAt) {
    if (!createdAt) return '-';
    const date = new Date(createdAt);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toLocaleDateString('fr-FR');
}

function papGetPropertyType(interior) {
    const interiorNum = parseInt(interior) || 1;
    if ([1, 3].includes(interiorNum)) return papT('pap_type_studio');
    if ([6, 7].includes(interiorNum)) return papT('pap_type_house');
    if (interiorNum >= 11 && interiorNum <= 46) return papT('pap_type_office');
    if (interiorNum >= 2 && interiorNum <= 70) return papT('pap_type_apartment');
    return papT('pap_type_unknown');
}

const PAP_PLACEHOLDER_ICON_CLASS = 'ph ph-house-line';







function papParseHousePreviewSetting(value, fallback) {
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

function papApplyHousePreviewPlaceholdersSetting(enabled, loaded) {
    papHousePreviewPlaceholdersEnabled = papParseHousePreviewSetting(enabled, papHousePreviewPlaceholdersEnabled);
    papHousePreviewPlaceholdersLoaded = loaded === true;

    if (typeof window.nhSetHousePreviewPlaceholdersSetting === 'function') {
        window.nhSetHousePreviewPlaceholdersSetting(papHousePreviewPlaceholdersEnabled, papHousePreviewPlaceholdersLoaded);
    }
}

function papGetInteriorPreviewImage(interior) {
    if (typeof getHouseInteriorPreviewImage === 'function') {
        const previewImage = getHouseInteriorPreviewImage({ interior: interior });
        if (typeof previewImage === 'string' && previewImage !== '') {
            return previewImage;
        }
    }

    const interiorNum = parseInt(interior, 10);
    if (!Number.isFinite(interiorNum) || interiorNum <= 0) {
        return null;
    }

    return `./images/${interiorNum}.jpg`;
}

function papGetImageHtml(images, interior, options) {
    const eagerLoad = !!(options && options.eagerLoad);
    const loadingMode = eagerLoad ? 'eager' : 'lazy';
    const fetchPriority = eagerLoad ? 'high' : 'low';
    const hasImage = Array.isArray(images) && images.length > 0 && images[0];

    if (hasImage) {
        const imageSrc = images[0].replace(/"/g, '&quot;');
        return `<img src="${imageSrc}" alt="Property" loading="${loadingMode}" decoding="async" fetchpriority="${fetchPriority}" onerror="papShowImagePlaceholder(this, '${PAP_PLACEHOLDER_ICON_CLASS}')">`;
    }

    if (papHousePreviewPlaceholdersEnabled === true) {
        const previewSrcRaw = papGetInteriorPreviewImage(interior);
        if (previewSrcRaw) {
            const previewSrc = String(previewSrcRaw).replace(/"/g, '&quot;');
            return `<img src="${previewSrc}" alt="Property preview" loading="${loadingMode}" decoding="async" fetchpriority="${fetchPriority}" onerror="papShowImagePlaceholder(this, '${PAP_PLACEHOLDER_ICON_CLASS}')">`;
        }
    }

    return `<div class="house-image-placeholder"><i class="${PAP_PLACEHOLDER_ICON_CLASS}" aria-hidden="true"></i></div>`;
}

window.papShowImagePlaceholder = function (imgElement, placeholderIconClass) {
    if (!imgElement?.parentElement) return;

    const parent = imgElement.parentElement;
    if (parent.querySelector('.pap-image-placeholder')) return;

    imgElement.style.display = 'none';

    const placeholder = document.createElement('div');
    placeholder.className = 'pap-image-placeholder';
    const icon = document.createElement('i');
    icon.className = (typeof placeholderIconClass === 'string' && placeholderIconClass.trim() !== '')
        ? placeholderIconClass.trim()
        : PAP_PLACEHOLDER_ICON_CLASS;
    icon.setAttribute('aria-hidden', 'true');
    placeholder.appendChild(icon);
    parent.appendChild(placeholder);
};

function papGetGpsIconHtml(coords) {
    if (!coords || !coords.x || !coords.y) {
        return '';
    }
    const coordsEscaped = JSON.stringify(coords).replace(/"/g, '&quot;');
    return `<button class="gps-icon-btn" onclick="event.stopPropagation(); papViewOnMap(${coordsEscaped})" title="${papT('pap_show_on_map')}">
        <i class="ph ph-map-pin"></i>
    </button>`;
}





function showPapInterface(data) {
    papLoadCurrencySymbol();
    papBindScrollVisibility();
    papUpdateCommandHint(data && data.papCommand);

    if (data && data.housePreviewPlaceholdersEnabledLoaded === true) {
        papApplyHousePreviewPlaceholdersSetting(data.housePreviewPlaceholdersEnabled, true);
    } else {
        papApplyHousePreviewPlaceholdersSetting(data && data.housePreviewPlaceholdersEnabled, false);
    }

    papTranslations = data.translations || {};
    papMyProperties = papNormalizeArray(data.myProperties);
    papListings = papNormalizeArray(data.listings);
    papMyListings = papNormalizeArray(data.myListings);
    papContracts = papNormalizeArray(data.contracts);
    papPropertyDetailsCache.clear();

    const papInterface = document.getElementById('pap-interface');
    if (papInterface) {
        papInterface.classList.remove('hidden');
        papApplyStaticTexts();

        
        let tabToRestore = 'my-properties';
        try {
            const storedTab = getFromLocalStorage('next_housing_pap_activeTab');
            if (storedTab && ['my-properties', 'listings', 'contracts'].includes(storedTab)) {
                tabToRestore = storedTab;
            }
        } catch (e) { }

        papSwitchTab(tabToRestore);
    }
}

function hidePapInterface() {
    const papInterface = document.getElementById('pap-interface');
    if (papInterface) {
        papInterface.classList.add('hidden');
    }
    papPropertyDetailsCache.clear();
    try {
        papCloseAllModals();
    } catch (e) {
        console.error("Error closing modals:", e);
    }
    $.post('https://next_housing/closePapInterface', JSON.stringify({}));
}

function papUpdateTitle() {
    if (typeof window.applyBrandTitle === 'function') {
        const currentTitle = window.nhExtendedState && window.nhExtendedState.title
            ? window.nhExtendedState.title
            : 'Next Housing';
        window.applyBrandTitle(currentTitle);
        return;
    }

    const title = document.getElementById('pap-title');
    if (title) {
        title.innerHTML = 'NEXT<span class="square-dot"></span>HOUSING';
    }
}

function papApplyStaticTexts() {
    papUpdateTitle();

    const tabMy = document.querySelector('.pap-tab-btn[data-tab="my-properties"]');
    const tabListings = document.querySelector('.pap-tab-btn[data-tab="listings"]');
    const tabContracts = document.querySelector('.pap-tab-btn[data-tab="contracts"]');
    if (tabMy) tabMy.textContent = papT('pap_tab_my_properties');
    if (tabListings) tabListings.textContent = papT('pap_tab_listings');
    if (tabContracts) tabContracts.textContent = papT('pap_tab_contracts');

    
    document.querySelectorAll('#pap-interface [data-translate]').forEach(el => {
        const key = el.getAttribute('data-translate');
        if (key && key !== '') {
            el.textContent = papT(key);
        }
    });

    document.querySelectorAll('h3[data-translate="pap_tab_my_properties"]').forEach(el => {
        el.textContent = papT('pap_tab_my_properties');
    });

    const refreshBtn = document.querySelector('.pap-refresh-btn');
    if (refreshBtn) {
        refreshBtn.innerHTML = `<i class="ph ph-arrows-clockwise"></i>`;
        refreshBtn.title = papT('pap_refresh');
    }


    const myListingsSectionTitle = document.getElementById('pap-my-listings-section-title');
    const listingsSectionTitle = document.getElementById('pap-listings-section-title');
    const listingsMainTitle = document.getElementById('pap-listings-main-title');
    if (myListingsSectionTitle) myListingsSectionTitle.textContent = papT('pap_tab_my_listings');
    if (listingsSectionTitle) listingsSectionTitle.textContent = papT('pap_tab_listings');
    if (listingsMainTitle) listingsMainTitle.textContent = papT('pap_tab_listings');


    const typeSelect = document.getElementById('pap-filter-type');
    if (typeSelect && typeSelect.options) {
        const optAll = typeSelect.querySelector('option[value="all"]');
        const optSale = typeSelect.querySelector('option[value="sale"]');
        const optRent = typeSelect.querySelector('option[value="rent"]');
        if (optAll) optAll.textContent = papT('pap_filter_all');
        if (optSale) optSale.textContent = papT('pap_filter_sale');
        if (optRent) optRent.textContent = papT('pap_filter_rent');
        typeSelect.value = papListingsTypeFilter;
    }


    const sortSelect = document.getElementById('pap-filter-sort');
    if (sortSelect && sortSelect.options) {
        const optRecent = sortSelect.querySelector('option[value="recent"]');
        const optLow = sortSelect.querySelector('option[value="price-low"]');
        const optHigh = sortSelect.querySelector('option[value="price-high"]');
        if (optRecent) optRecent.textContent = papT('pap_filter_recent');
        if (optLow) optLow.textContent = papT('pap_filter_price_low');
        if (optHigh) optHigh.textContent = papT('pap_filter_price_high');
        sortSelect.value = papListingsSortFilter;
    }


    const myPropsLoading = document.querySelector('#pap-my-properties-loading p');
    if (myPropsLoading) myPropsLoading.textContent = papT('pap_loading');
    const myPropsEmpty = document.querySelector('#pap-my-properties-empty p');
    if (myPropsEmpty) myPropsEmpty.innerHTML = papT('pap_no_properties_hint') || papT('pap_no_properties');
    const listingsSearch = document.getElementById('pap-listings-search-input');
    if (listingsSearch) {
        const searchPlaceholder = papTranslations.pap_search_listings
            || (window.translations && window.translations.pap_search_listings)
            || papTranslations.job_search_houses_placeholder
            || (window.translations && window.translations.job_search_houses_placeholder)
            || 'Search listings...';
        listingsSearch.placeholder = searchPlaceholder;
    }

    const listingsLoading = document.querySelector('#pap-listings-loading p');
    if (listingsLoading) listingsLoading.textContent = papT('pap_loading');
    const listingsEmpty = document.querySelector('#pap-listings-empty p');
    if (listingsEmpty) listingsEmpty.textContent = papT('pap_no_listings');

    const myListingsLoading = document.querySelector('#pap-my-listings-loading p');
    if (myListingsLoading) myListingsLoading.textContent = papT('pap_loading');
    const myListingsEmpty = document.querySelector('#pap-my-listings-empty p');
    if (myListingsEmpty) myListingsEmpty.innerHTML = papT('pap_no_my_listings_hint') || papT('pap_no_my_listings');


    const toggleOffers = document.querySelector('#pap-management-toggle .pap-toggle-btn[data-view="offers"]');
    const toggleContracts = document.querySelector('#pap-management-toggle .pap-toggle-btn[data-view="contracts"]');
    if (toggleOffers) toggleOffers.textContent = papT('pap_tab_offers');
    if (toggleContracts) toggleContracts.textContent = papT('pap_tab_contracts_only');

    const offersLoading = document.querySelector('#pap-offers-loading p');
    if (offersLoading) offersLoading.textContent = papT('pap_loading_offers');
    const offersEmpty = document.querySelector('#pap-offers-empty p');
    if (offersEmpty) offersEmpty.textContent = papT('pap_no_offers');

    const contractsLoading = document.querySelector('#pap-contracts-loading p');
    if (contractsLoading) contractsLoading.textContent = papT('pap_loading_contracts');
    const contractsEmpty = document.querySelector('#pap-contracts-empty p');
    if (contractsEmpty) contractsEmpty.textContent = papT('pap_no_contracts');

    const createModalTitle = document.querySelector('#pap-create-listing-modal h3');
    if (createModalTitle) createModalTitle.textContent = papT('pap_modal_create_listing');
    const infoLabelProperty = document.querySelector('#pap-listing-property-name')?.closest('.pap-info-row')?.querySelector('.pap-info-label');
    if (infoLabelProperty) infoLabelProperty.textContent = papT('pap_listing_property_label');
    const infoLabelLocation = document.querySelector('#pap-listing-property-location')?.closest('.pap-info-row')?.querySelector('.pap-info-label');
    if (infoLabelLocation) infoLabelLocation.textContent = papT('pap_listing_location_label');
    const infoLabelEstimate = document.querySelector('#pap-listing-property-price')?.closest('.pap-info-row')?.querySelector('.pap-info-label');
    if (infoLabelEstimate) infoLabelEstimate.textContent = papT('pap_listing_estimated_price_label');

    const listingTypeLabel = document.querySelector('#pap-listing-type')?.closest('.pap-form-group')?.querySelector('.pap-form-label');
    if (listingTypeLabel) listingTypeLabel.textContent = papT('pap_listing_type_label');
    const listingTypeSelect = document.getElementById('pap-listing-type');
    if (listingTypeSelect && listingTypeSelect.options) {
        const optSale = listingTypeSelect.querySelector('option[value="sale"]');
        const optRent = listingTypeSelect.querySelector('option[value="rent"]');
        if (optSale) optSale.textContent = papT('pap_listing_type_sale');
        if (optRent) optRent.textContent = papT('pap_listing_type_rent');
    }

    const listingPriceLabel = document.getElementById('pap-listing-price-label');
    if (listingPriceLabel) listingPriceLabel.textContent = papT('pap_listing_price_label');
    const listingPriceInput = document.getElementById('pap-listing-price');
    if (listingPriceInput) listingPriceInput.placeholder = papT('pap_listing_price_label');

    const rentDurationGroup = document.getElementById('pap-rent-duration-group');
    if (rentDurationGroup) {
        const rentDurationLabel = rentDurationGroup.querySelector('.pap-form-label');
        if (rentDurationLabel) rentDurationLabel.textContent = papT('pap_listing_duration_label');
        const rentDurationSelect = document.getElementById('pap-rent-duration');
        if (rentDurationSelect && rentDurationSelect.options) {
            const placeholderOpt = rentDurationSelect.querySelector('option[value=""]');
            if (placeholderOpt) placeholderOpt.textContent = papT('pap_rent_duration_placeholder');
            ['1', '3', '6', '12'].forEach(val => {
                const opt = rentDurationSelect.querySelector(`option[value="${val}"]`);
                if (opt) opt.textContent = `${val} ${papT('pap_months')}`;
            });
        }
    }

    const listingDescriptionLabel = document.querySelector('#pap-listing-description')?.closest('.pap-form-group')?.querySelector('.pap-form-label');
    if (listingDescriptionLabel) listingDescriptionLabel.textContent = papT('pap_listing_description_label');
    const listingDescription = document.getElementById('pap-listing-description');
    if (listingDescription) listingDescription.placeholder = papT('pap_listing_description_placeholder');

    if (typeof window.refreshCustomDropdown === 'function') {
        window.refreshCustomDropdown('pap-filter-type');
        window.refreshCustomDropdown('pap-filter-sort');
        window.refreshCustomDropdown('pap-listing-type');
        window.refreshCustomDropdown('pap-rent-duration');
    }





}





function papSwitchTab(tab) {
    papCurrentTab = tab;

    
    saveToLocalStorage('next_housing_pap_activeTab', tab);


    document.querySelectorAll('.pap-tab-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tab) {
            btn.classList.add('active');
        }
    });


    document.querySelectorAll('.pap-tab-panel').forEach(panel => {
        panel.classList.remove('active');
    });


    const activePanel = document.getElementById(`pap-tab-${tab}`);
    if (activePanel) {
        activePanel.classList.add('active');
    }

    const listingsTopControls = document.getElementById('pap-listings-toolbar-controls-top');
    if (listingsTopControls) {
        if (tab === 'listings') {
            listingsTopControls.classList.remove('hidden');
        } else {
            listingsTopControls.classList.add('hidden');
        }
    }


    switch (tab) {
        case 'my-properties':
            if (papMyPropertiesNeedsRefresh) {
                papMyPropertiesNeedsRefresh = false;
                $.post('https://next_housing/papRefreshData', JSON.stringify({}));
            }
            papRenderMyProperties();
            break;
        case 'listings':

            papToggleListingsView();
            break;
        case 'contracts':

            papToggleManagementView(papCurrentManagementView, true);
            break;
    }
}


function papGetPublicListings() {
    if (!Array.isArray(papListings) || papListings.length === 0) return [];
    if (!Array.isArray(papMyListings) || papMyListings.length === 0) return papListings;

    const myListingIds = new Set(papMyListings.map(listing => listing.id));
    return papListings.filter(listing => !myListingIds.has(listing.id));
}

function papToggleListingsView() {
    papCurrentListingsView = 'merged';

    const viewAll = document.getElementById('pap-public-listings-section');
    const viewMine = document.getElementById('pap-my-listings-section');
    const hasMyListings = Array.isArray(papMyListings) && papMyListings.length > 0;
    const publicListings = papGetPublicListings();

    if (viewMine) {
        if (hasMyListings) {
            viewMine.classList.remove('hidden');
        } else {
            viewMine.classList.add('hidden');
        }
    }

    if (viewAll) {
        viewAll.classList.remove('hidden');
    }

    papRenderMyListings(false);
    papRenderListings(publicListings);
}


function papToggleManagementView(view, autoSwitch) {
    if (autoSwitch) {
        // Keep management focused on live flows (offers + active contracts).
        view = 'contracts';
    }

    papCurrentManagementView = view;

    const viewOffers = document.getElementById('pap-management-view-offers');
    const viewContracts = document.getElementById('pap-management-view-contracts');

    if (viewOffers) viewOffers.classList.add('hidden');
    if (viewContracts) viewContracts.classList.add('hidden');

    if (viewOffers) viewOffers.classList.remove('hidden');
    if (viewContracts) viewContracts.classList.remove('hidden');
    papRenderOffers();
    papRenderActiveContracts();
}





function papHandleListingsSearch(value) {
    papListingsSearch = (value || '').toString();
    if (papCurrentTab === 'listings') {
        papToggleListingsView();
    }
}

window.papHandleListingsSearch = papHandleListingsSearch;

function papGetListingsSearchQuery() {
    return (papListingsSearch || '').trim().toLowerCase();
}

function papGetFilteredListings(listings) {
    if (!Array.isArray(listings) || listings.length === 0) {
        return [];
    }

    const searchQuery = papGetListingsSearchQuery();

    return listings.filter(function (listing) {
        if (papListingsTypeFilter !== 'all' && listing.type !== papListingsTypeFilter) {
            return false;
        }

        if (!searchQuery) {
            return true;
        }

        const houseName = (listing.houseName || '').toString().toLowerCase();
        const sellerName = (listing.sellerName || '').toString().toLowerCase();
        const listingId = String(listing.id || '').toLowerCase();
        const houseId = String(listing.houseId || '').toLowerCase();
        const zoneName = (listing.zoneName || '').toString().toLowerCase();
        const propertyType = (papGetPropertyType(listing.interior) || '').toString().toLowerCase();
        const description = (listing.description || '').toString().toLowerCase();

        return houseName.includes(searchQuery)
            || sellerName.includes(searchQuery)
            || listingId.includes(searchQuery)
            || houseId.includes(searchQuery)
            || zoneName.includes(searchQuery)
            || propertyType.includes(searchQuery)
            || description.includes(searchQuery);
    });
}

function papGetListingSortTimestamp(listing) {
    const timestamp = new Date(listing && (listing.createdAt || listing.updatedAt || listing.date)).getTime();
    if (Number.isFinite(timestamp)) {
        return timestamp;
    }

    const numericId = parseInt(listing && listing.id, 10);
    return Number.isFinite(numericId) ? numericId : 0;
}

function papGetSortedListings(listings) {
    const sortedListings = Array.isArray(listings) ? [...listings] : [];

    sortedListings.sort(function (a, b) {
        if (papListingsSortFilter === 'price-low') {
            return (parseFloat(a && a.price) || 0) - (parseFloat(b && b.price) || 0);
        }

        if (papListingsSortFilter === 'price-high') {
            return (parseFloat(b && b.price) || 0) - (parseFloat(a && a.price) || 0);
        }

        return papGetListingSortTimestamp(b) - papGetListingSortTimestamp(a);
    });

    return sortedListings;
}

function papFilterListings() {
    const typeSelect = document.getElementById('pap-filter-type');
    papListingsTypeFilter = typeSelect ? typeSelect.value : 'all';

    if (papCurrentTab === 'listings') {
        papToggleListingsView();
    }
}

function papSortListings() {
    const sortSelect = document.getElementById('pap-filter-sort');
    papListingsSortFilter = sortSelect ? sortSelect.value : 'recent';

    if (papCurrentTab === 'listings') {
        papToggleListingsView();
    }
}

window.papFilterListings = papFilterListings;
window.papSortListings = papSortListings;

function papGetMyPropertyCardImageSource(property) {
    if (property && property.listImage) {
        return String(property.listImage);
    }

    if (papHousePreviewPlaceholdersLoaded === true && papHousePreviewPlaceholdersEnabled === true) {
        return papGetInteriorPreviewImage(property && property.interior);
    }

    return null;
}

function papGetAgencyLikePropertyStatusText(property) {
    if (property.isRented) {
        return papT('pap_badge_rented');
    }

    if (property.hasTransaction) {
        return papT('pap_badge_transaction');
    }

    if (property.hasListing) {
        return papT('pap_listing_status_active');
    }

    return window.translations.job_house_available;
}

function papCreateAgencyLikePropertyActions(property) {
    const actions = $('<div>').addClass('house-actions');

    if (property.isRented) {
        actions.append(createHouseActionButton(
            papT('pap_view_contracts'),
            'ph ph-signature',
            '',
            function (e) {
                e.stopPropagation();
                papGoToContracts();
            }
        ));
        return actions;
    }

    if (property.hasTransaction) {
        actions.append(createHouseActionNotice(papT('pap_badge_transaction')));
        return actions;
    }

    if (property.hasListing) {
        actions.append(createHouseActionButton(
            papT('pap_view_listing'),
            'ph ph-eye',
            '',
            function (e) {
                e.stopPropagation();
                papViewMyListing(property.id);
            }
        ));
        return actions;
    }

    actions.append(createHouseActionButton(
        papT('pap_create_listing'),
        'ph ph-plus',
        '',
        function (e) {
            e.stopPropagation();
            papOpenCreateListingModal(property.id);
        }
    ));

    return actions;
}

function papConvertPropertyToAgencyLikeHouse(property) {
    const cardImage = papGetMyPropertyCardImageSource(property);

    return {
        id: property.id,
        name: property.name,
        interior: property.interior,
        price: property.price,
        zoneName: property.zoneName,
        hasGarage: property.hasGarage,
        coords: property.coords,
        images: cardImage ? [cardImage] : [],
        ownerIdentifier: '',
        belongsToAgency: false,
        canBuy: false,
        hasPapContract: false
    };
}

function papCreateMyPropertyCard(property) {
    const card = createHouseCard(papConvertPropertyToAgencyLikeHouse(property));
    const statusBadge = card.find('.house-status').first();

    card.addClass('clickable');
    card.removeClass('available sold pap-contract');

    if (property.isRented || property.hasTransaction) {
        card.addClass('pap-contract');
    } else if (property.hasListing) {
        card.addClass('available');
    }

    statusBadge.text(papGetAgencyLikePropertyStatusText(property));
    card.find('.house-actions').remove();
    card.append(papCreateAgencyLikePropertyActions(property));

    card.off('click').on('click', function (e) {
        if (!$(e.target).closest('button, .gps-icon-btn').length) {
            papOpenPropertyDetails(property.id);
        }
    });

    return card;
}

function papRenderMyProperties() {
    const container = $('#pap-my-properties-list');
    const loading = $('#pap-my-properties-loading');
    const empty = $('#pap-my-properties-empty');
    const propertiesInRenderOrder = [...papMyProperties].reverse();

    if (container.length === 0) return;

    container.empty();
    loading.addClass('hidden');

    if (propertiesInRenderOrder.length === 0) {
        empty.removeClass('hidden');
        return;
    }

    empty.addClass('hidden');

    propertiesInRenderOrder.forEach(function (property) {
        container.append(papCreateMyPropertyCard(property));
    });
}





function papGetListingDescriptionBlock(description) {
    const rawDescription = description == null ? '' : String(description).trim();
    const hasDescription = rawDescription.length > 0;
    const descriptionText = papEscapeHtml(hasDescription ? rawDescription : papT('job_contract_not_defined'));
    const placeholderClass = hasDescription ? '' : ' pap-listing-description-placeholder';

    return `
        <div class="pap-listing-description-block">
            <span class="pap-listing-description-label">${papT('pap_listing_description_label')}</span>
            <p class="pap-listing-description-text${placeholderClass}" title="${descriptionText}">${descriptionText}</p>
        </div>
    `;
}

function papRenderListings(listingsToRender) {
    const container = document.getElementById('pap-listings-list');
    const loading = document.getElementById('pap-listings-loading');
    const empty = document.getElementById('pap-listings-empty');
    const searchInput = document.getElementById('pap-listings-search-input');
    const listings = papGetSortedListings(papGetFilteredListings(Array.isArray(listingsToRender) ? listingsToRender : papListings));

    if (!container) return;

    if (searchInput && searchInput.value !== papListingsSearch) {
        searchInput.value = papListingsSearch;
    }

    if (loading) loading.classList.add('hidden');

    if (listings.length === 0) {
        container.innerHTML = '';
        if (empty) empty.classList.remove('hidden');
        return;
    }

    if (empty) empty.classList.add('hidden');

    let html = '';
    listings.forEach(listing => {
        const imageHtml = papGetImageHtml(listing.images, listing.interior);

        const typeLabel = listing.type === 'sale' ? papT('pap_listing_type_sale') : papT('pap_listing_type_rent');
        const badgeClass = listing.type === 'sale' ? 'sale' : 'rent';

        const typeBadge = `<div class="house-status ${badgeClass}">${typeLabel}</div>`;

        const gpsIconHtml = papGetGpsIconHtml(listing.coords);
        const houseName = papEscapeHtml(listing.houseName || papT('pap_property_number') + listing.houseId);
        const sellerName = papEscapeHtml(listing.sellerName || papT('pap_contract_seller'));
        const zoneName = papEscapeHtml(listing.zoneName || papT('pap_unknown_zone'));
        const propertyType = papEscapeHtml(papGetPropertyType(listing.interior));
        const sellerNameSafe = papEscapeJsString(listing.sellerName || papT('pap_contract_seller'));
        const sellerIdSafe = papEscapeJsString(listing.sellerId || '');
        const descriptionBlockHtml = papGetListingDescriptionBlock(listing.description);

        html += `
            <div class="house-card clickable" data-id="${listing.id}" onclick="papOpenListingDetails(${listing.id})">
                <div class="house-header-image">
                    ${imageHtml}
                    <div class="house-image-overlay">
                        <div class="house-image-overlay-top">
                            <div class="house-title-container">
                                ${gpsIconHtml}
                                <h4 class="house-id" title="${houseName}">${houseName}</h4>
                            </div>
                            ${typeBadge}
                        </div>
                        <div class="house-info">
                            <div class="house-info-grid">
                                <div class="house-info-item">
                                    <span class="house-info-label">Type</span>
                                    <span class="house-info-value">${propertyType}</span>
                                </div>
                                <div class="house-info-item">
                                    <span class="house-info-label">Ville</span>
                                    <span class="house-info-value" title="${zoneName}" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${zoneName}</span>
                                </div>
                                <div class="house-info-item">
                                    <span class="house-info-label">${papT('pap_property_price')}</span>
                                    <span class="house-info-value">${papFormatPrice(listing.price)}${listing.type === 'rent' ? '/mo' : ''}</span>
                                </div>
                                <div class="house-info-item">
                                    <span class="house-info-label">Vendeur</span>
                                    <span class="house-info-value" title="${sellerName}" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${sellerName}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="house-actions" onclick="event.stopPropagation()">
                    ${descriptionBlockHtml}
                    <button class="action-btn" style="width: 100%; justify-content: center;" onclick="papContactSeller('${sellerIdSafe}', ${listing.id}, '${sellerNameSafe}', ${listing.price})">
                        <i class="ph ph-envelope-simple"></i> ${papT('pap_contact_seller')}
                    </button>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}

function papRenderMyListings(showEmpty = true) {
    const container = document.getElementById('pap-my-listings-list');
    const loading = document.getElementById('pap-my-listings-loading');
    const empty = document.getElementById('pap-my-listings-empty');

    if (!container) return;

    if (loading) loading.classList.add('hidden');

    if (papMyListings.length === 0) {
        container.innerHTML = '';
        if (empty) {
            if (showEmpty) {
                empty.classList.remove('hidden');
            } else {
                empty.classList.add('hidden');
            }
        }
        return;
    }

    if (empty) empty.classList.add('hidden');

    let html = '';
    papMyListings.forEach(listing => {
        const imageHtml = papGetImageHtml(listing.images, listing.interior);

        const typeLabel = listing.type === 'sale' ? papT('pap_listing_type_sale') : papT('pap_listing_type_rent');
        const badgeStyle = listing.type === 'sale'
            ? 'background: rgba(68, 255, 68, 0.1); color: #44ff44; border-color: #44ff44;'
            : 'background: rgba(0, 191, 255, 0.1); color: #00bfff; border-color: #00bfff;';

        let typeBadge = `<div class="house-status" style="${badgeStyle}">${typeLabel}</div>`;

        const hasTransaction = listing.hasTransaction || listing.status === 'transaction';
        const houseName = papEscapeHtml(listing.houseName || papT('pap_property_number') + listing.houseId);
        const zoneName = papEscapeHtml(listing.zoneName || papT('pap_unknown_zone'));
        const propertyType = papEscapeHtml(papGetPropertyType(listing.interior));
        const garageLabel = papEscapeHtml(papGetGarageAvailabilityLabel(listing.hasGarage));

        if (hasTransaction) {
            typeBadge += `<div class="house-status" style="background: rgba(255, 165, 0, 0.2); color: orange; border-color: orange; margin-left: 5px;">${papT('pap_badge_transaction')}</div>`;
        } else if (listing.pendingOffers > 0) {
            typeBadge += `<div class="house-status" style="background: rgba(255, 255, 255, 0.2); color: white; border-color: white; margin-left: 5px;">${papTf('pap_pending_offers', listing.pendingOffers)}</div>`;
        }


        let actionsHtml = '';
        if (hasTransaction) {
            actionsHtml = `
                <button class="action-btn" onclick="papGoToContracts()"><i class="ph ph-signature"></i> <span>${papT('pap_view_contracts')}</span></button>
            `;
        } else {
            actionsHtml = `
                <button class="action-btn" style="border-color: rgba(255, 68, 68, 0.3); color: #ff4444;" title="${papT('pap_delete_listing')}" onclick="papDeleteListing(${listing.id})"><i class="ph ph-trash"></i> <span>${papT('pap_delete_listing')}</span></button>
            `;
        }

        const gpsIconHtml = papGetGpsIconHtml(listing.coords);

        const descriptionBlockHtml = papGetListingDescriptionBlock(listing.description);

        html += `
            <div class="house-card clickable ${hasTransaction ? 'pap-listing-locked' : ''}" data-id="${listing.id}">
                <div class="house-header-image">
                    ${imageHtml}
                    <div class="house-image-overlay">
                        <div class="house-image-overlay-top">
                             <div class="house-title-container">
                                ${gpsIconHtml}
                                <h4 class="house-id" title="${houseName}">${houseName}</h4>
                            </div>
                           <div style="display: flex;">
                             ${typeBadge}
                           </div>
                        </div>
                        <div class="house-info">
                            <div class="house-info-grid">
                                <div class="house-info-item">
                                    <span class="house-info-label">Type</span>
                                    <span class="house-info-value">${propertyType}</span>
                                </div>
                                <div class="house-info-item">
                                    <span class="house-info-label">Ville</span>
                                    <span class="house-info-value" title="${zoneName}" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${zoneName}</span>
                                </div>
                                <div class="house-info-item">
                                    <span class="house-info-label">${papT('pap_property_price')}</span>
                                    <span class="house-info-value">${papFormatPrice(listing.price)}${listing.type === 'rent' ? '/mo' : ''}</span>
                                </div>
                                 <div class="house-info-item">
                                    <span class="house-info-label">Date</span>
                                    <span class="house-info-value">${papFormatListingDate(listing.createdAt)}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="house-actions" onclick="event.stopPropagation()">
                    ${descriptionBlockHtml}
                    ${actionsHtml}
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}


function papGoToContracts() {
    papSwitchTab('contracts');
}

function papConvertPropertyToHouseData(property) {
    const propertyImages = Array.isArray(property.images) && property.images.length > 0
        ? property.images
        : (property.listImage ? [property.listImage] : []);

    return {
        id: property.id,
        name: property.name,
        interior: property.interior,
        price: property.price,
        ownerIdentifier: property.ownerIdentifier,
        ownerName: property.ownerName,
        zoneName: property.zoneName,
        hasGarage: property.hasGarage,
        hcoords: property.coords,
        images: propertyImages,
        belongsToAgency: false,
        canRent: false,
        canBuy: false,
        isPapProperty: true,
        canManageMedia: true,
        isReadOnly: false,
        isRented: property.isRented,
        hasTransaction: property.hasTransaction,
        hasListing: property.hasListing,
        renterName: property.renterName
    };
}


function papOpenPropertyDetails(propertyId) {
    const property = papMyProperties.find(p => p.id === propertyId);
    if (!property) return;

    if (window.translations) {
        window.translations = { ...window.translations, ...papTranslations };
    } else {
        window.translations = { ...papTranslations };
    }

    papFetchPropertyDetails(propertyId).then(function (detailedProperty) {
        const resolvedProperty = papMergePropertyData(property, detailedProperty);
        if (!resolvedProperty) {
            return;
        }

        const houseData = papConvertPropertyToHouseData(resolvedProperty);

        if (typeof showHouseDetails === 'function') {
            showHouseDetails(houseData);
        } else if (typeof window.showHouseDetails === 'function') {
            window.showHouseDetails(houseData);
        } else {
            console.error('[PaP] showHouseDetails non disponible');
            papShowAlert(papT('pap_error_invalid_data'));
        }
    });
}


function papOpenListingDetails(listingId) {
    const listing = papListings.find(l => l.id === listingId);
    if (!listing) return;


    if (window.translations) {
        window.translations = { ...window.translations, ...papTranslations };
    } else {
        window.translations = { ...papTranslations };
    }


    const houseData = {
        id: listing.houseId,
        name: listing.houseName,
        interior: listing.interior,
        price: listing.price,
        ownerIdentifier: listing.sellerId,
        ownerName: listing.sellerName,
        zoneName: listing.zoneName,
        hasGarage: listing.hasGarage,
        hcoords: listing.coords,
        images: listing.images || [],
        belongsToAgency: false,
        canRent: false,
        canBuy: false,
        isPapProperty: true,
        isPapListing: true,
        listingType: listing.type,
        listingDescription: listing.description,
        canManageMedia: false,
        isReadOnly: true
    };


    if (typeof showHouseDetails === 'function') {
        showHouseDetails(houseData);
    } else if (typeof window.showHouseDetails === 'function') {
        window.showHouseDetails(houseData);
    } else {
        console.error('[PaP] showHouseDetails non disponible');
        papShowAlert(papT('pap_error_invalid_data'));
    }
}


function papRenderOffers() {
    const container = document.getElementById('pap-offers-list');
    const loading = document.getElementById('pap-offers-loading');
    const empty = document.getElementById('pap-offers-empty');

    if (!container) return;

    if (loading) loading.classList.add('hidden');


    let offers = papContracts.filter(c => c.status === 'offer_pending' || c.status === 'accepted');

    if (offers.length === 0) {
        container.innerHTML = '';
        if (empty) empty.classList.remove('hidden');
        return;
    }

    if (empty) empty.classList.add('hidden');

    let html = '';
    offers.forEach(contract => {
        html += papRenderContractCard(contract);
    });

    container.innerHTML = html;
}


function papRenderActiveContracts() {
    const container = document.getElementById('pap-contracts-list');
    const loading = document.getElementById('pap-contracts-loading');
    const empty = document.getElementById('pap-contracts-empty');

    if (!container) return;
    if (loading) loading.classList.add('hidden');

    const contracts = papContracts.filter(function (contract) {
        if (!contract) return false;
        if (contract.status === 'completed') return true;
        return contract.status === 'terminated' && contract.type === 'rent';
    });

    if (contracts.length === 0) {
        container.innerHTML = '';
        if (empty) empty.classList.remove('hidden');
        return;
    }

    if (empty) empty.classList.add('hidden');

    let html = '';
    contracts.forEach(function (contract) {
        html += papRenderContractCard(contract);
    });
    container.innerHTML = html;
}


function papRenderContractCard(contract) {
    const isSeller = contract.isSeller;
    const canSign = contract.canSign;
    const isAccepted = contract.status === 'accepted';
    const isCompleted = contract.status === 'completed';
    const isTerminated = contract.status === 'terminated';
    const isCancelled = contract.status === 'cancelled';
    const typeLabel = contract.type === 'sale' ? papT('pap_listing_type_sale') : papT('pap_listing_type_rent');
    const buyerNameEscaped = papEscapeJsString(contract.buyerName || papT('pap_contract_buyer'));
    const sellerNameEscaped = papEscapeJsString(contract.sellerName || papT('pap_contract_seller'));
    const houseName = papEscapeHtml(contract.houseName || papT('pap_property_number') + contract.houseId);
    const otherPartyName = papEscapeHtml(
        (isSeller ? contract.buyerName : contract.sellerName) ||
        (isSeller ? papT('pap_contract_buyer') : papT('pap_contract_seller'))
    );
    const signedForLabel = (function () {
        if (contract.type === 'sale') {
            return papT('pap_contract_type_sale_done');
        }
        if (isTerminated) {
            return papT('pap_contract_badge_terminated');
        }
        if (isCancelled) {
            return papT('pap_contract_badge_cancelled');
        }
        return papT('pap_contract_type_rent_active');
    })();


    let statusBadge = '';
    if (isCancelled) {
        statusBadge = `<span class="pap-badge cancelled">${papT('pap_contract_badge_cancelled')}</span>`;
    } else if (isTerminated) {
        statusBadge = `<span class="pap-badge terminated">${papT('pap_contract_badge_terminated')}</span>`;
    } else if (isCompleted) {
        statusBadge = `<span class="pap-badge completed">${contract.type === 'sale' ? papT('pap_contract_badge_completed_sale') : papT('pap_contract_badge_completed_rent')}</span>`;
    } else if (isAccepted) {
        statusBadge = `<span class="pap-badge accepted">${papT('pap_contract_badge_waiting_signature')}</span>`;
    } else {
        statusBadge = `<span class="pap-badge pending">${papT('pap_contract_pending')}</span>`;
    }


    let actionsHtml = '';

    if (isCancelled) {
        actionsHtml = `<span class="pap-terminated-text">${papT('pap_contract_badge_cancelled')}</span>`;
    } else if (isTerminated) {
        actionsHtml = `<span class="pap-terminated-text">${papT('pap_contract_badge_terminated')}</span>`;
    } else if (isCompleted) {
        if (contract.type === 'rent') {
            actionsHtml = `
                <button class="pap-btn secondary" onclick="papTerminateContract(${contract.id}, 'pap')">${papT('pap_action_terminate')}</button>
                <button class="pap-btn secondary" onclick="papViewOnMap(${JSON.stringify(contract.coords).replace(/"/g, '&quot;')})">
                    <i class="ph ph-map-pin"></i> ${papT('pap_show_on_map')}
                </button>
            `;
        } else {
            actionsHtml = `
                <button class="pap-btn secondary" onclick="papViewOnMap(${JSON.stringify(contract.coords).replace(/"/g, '&quot;')})">
                    <i class="ph ph-map-pin"></i> ${papT('pap_show_on_map')}
                </button>
            `;
        }
    } else if (isSeller) {
        if (isAccepted) {
            actionsHtml = `
                <button class="pap-btn-chat" onclick="papOpenChat(${contract.id}, ${isSeller}, '${buyerNameEscaped}', '${sellerNameEscaped}')">
                    <span>${papT('pap_action_chat')}</span>
                </button>
                <span class="pap-waiting-text">${papT('pap_waiting_signature')}...</span>
            `;
        } else {
            actionsHtml = `
                <button class="pap-btn-chat" onclick="papOpenChat(${contract.id}, ${isSeller}, '${buyerNameEscaped}', '${sellerNameEscaped}')">
                    <span>${papT('pap_action_chat')}</span>
                </button>
                <button class="pap-btn secondary" onclick="papAcceptOffer(${contract.id})">${papT('pap_contract_accept')}</button>
                <button class="pap-btn secondary" onclick="papDeclineOffer(${contract.id})">${papT('pap_contract_decline')}</button>
            `;
        }
    } else {
        if (canSign) {
            actionsHtml = `
                <button class="pap-btn-chat" onclick="papOpenChat(${contract.id}, ${isSeller}, '${buyerNameEscaped}', '${sellerNameEscaped}')">
                    <span>${papT('pap_action_chat')}</span>
                </button>
                <button class="pap-btn secondary pap-btn-sign" onclick="papOpenContractToSign(${contract.id})">${papT('pap_action_sign_contract')}</button>
                <button class="pap-btn secondary" onclick="papDeclineContractAsBuyer(${contract.id})">${papT('pap_contract_decline')}</button>
            `;
        } else {
            actionsHtml = `
                <button class="pap-btn-chat" onclick="papOpenChat(${contract.id}, ${isSeller}, '${buyerNameEscaped}', '${sellerNameEscaped}')">
                    <span>${papT('pap_action_chat')}</span>
                </button>
                <button class="pap-btn secondary" onclick="papCancelOffer(${contract.id})">${papT('pap_action_cancel_offer')}</button>
            `;
        }
    }


    let cardClass = 'pap-contract-card';
    if (isCancelled) cardClass += ' pap-contract-cancelled';
    else if (isTerminated) cardClass += ' pap-contract-terminated';
    else if (isCompleted) cardClass += ' pap-contract-completed';
    else if (isAccepted) cardClass += ' pap-contract-accepted';

    return `
        <div class="${cardClass}" data-id="${contract.id}">
            <div class="pap-contract-header">
                <h4>${houseName}</h4>
                <div class="pap-contract-badges">
                    ${statusBadge}
                </div>
            </div>
            <div class="pap-contract-info">
                ${(isCompleted || isTerminated || isCancelled) ? `
                <div class="pap-info-item">
                    <span class="pap-info-label">${papT('pap_contract_signed_for')}</span>
                    <span class="pap-info-value">${signedForLabel}</span>
                </div>
                ` : ''}
                <div class="pap-info-item">
                    <span class="pap-info-label">
                        ${(isCompleted || isTerminated || isCancelled) ?
            (contract.type === 'sale' ? (isSeller ? papT('pap_contract_bought_by') : papT('pap_contract_sold_by')) : (isSeller ? papT('pap_contract_tenant') : papT('pap_contract_landlord'))) :
            ((isSeller ? papT('pap_contract_buyer') : papT('pap_contract_seller')) + ' :')}
                    </span>
                    <span class="pap-info-value">${otherPartyName}</span>
                </div>
                <div class="pap-info-item">
                    <span class="pap-info-label">
                        ${(isCompleted || isTerminated || isCancelled) ?
            (contract.type === 'sale' ? papT('pap_contract_price_sale_done') : papT('pap_contract_rent_inclusive')) :
            (papT('pap_contract_price') + ' :')}
                    </span>
                    <span class="pap-info-value">${papFormatPrice(contract.amount)}</span>
                </div>
            </div>
            <div class="pap-contract-actions">
                ${actionsHtml}
            </div>
        </div>
    `;
}


function papRenderContracts() {
    if (papCurrentManagementView === 'offers') {
        papRenderOffers();
    } else {
        papRenderActiveContracts();
    }
}


function papOpenContractToSign(offerId) {
    const numericOfferId = parseInt(offerId, 10);
    const contract = papContracts.find(function (c) {
        return parseInt(c && c.id, 10) === numericOfferId;
    });
    if (!contract) {
        papShowAlert(papT('pap_error_contract_not_found'));
        return;
    }


    $.post('https://next_housing/papGetContractData', JSON.stringify({
        offerId: numericOfferId
    }), function (response) {
        let result = response;
        if (typeof response === 'string') {
            try {
                result = JSON.parse(response);
            } catch (_) {
            }
        }

        if (result && result.success === false) {
            papShowAlert(result.message || papT('pap_error_contract_not_found'));
        }
    }).fail(function () {
        papShowAlert(papT('update_error'));
    });
}


function papDeclineContractAsBuyer(offerId) {
    papShowConfirm(papT('pap_confirm_decline_contract_buyer'), function () {
        papApplyOfferRevertedLocally(offerId);
        $.post('https://next_housing/papDeclineContractAsBuyer', JSON.stringify({
            offerId: offerId
        }));
        papQueueDataRefresh();
    });
}

function papCancelOffer(offerId) {
    papShowConfirm(papT('pap_confirm_cancel_offer'), function () {
        papApplyOfferRevertedLocally(offerId);
        $.post('https://next_housing/papCancelOffer', JSON.stringify({
            offerId: offerId
        }));
        papQueueDataRefresh();
    });
}

function papTerminateContract(contractId, contractType) {
    papShowConfirm(papT('pap_confirm_terminate_contract'), function () {
        papApplyContractTerminatedLocally(contractId);
        $.post('https://next_housing/papTerminateContract', JSON.stringify({
            contractId: contractId,
            contractType: contractType || 'pap'
        }));
        papQueueDataRefresh();
    });
}

function papOpenCreateListingModal(propertyId) {
    papApplyStaticTexts();
    papSelectedProperty = papMyProperties.find(p => p.id === propertyId);
    if (!papSelectedProperty) return;
    const listingHouseName = papSelectedProperty.name || `${papT('pap_property_number')}${papSelectedProperty.id}`;

    window.ModalManager.open({
        title: papT('pap_modal_create_listing'),
        hint: listingHouseName,
        containerClass: 'pap-form-modal',
        footerClass: 'pap-form-modal-footer',
        bodyHTML: `
            <div class="agency-modal-main-block pap-form-main-block">
            <div class="section-header pap-main-block-header">
                <h3>${papT('pap_modal_create_listing')}</h3>
            </div>
            <div class="pap-form-group">
                <label class="pap-form-label">${papT('pap_listing_type_label')}</label>
                <select class="pap-form-select pap-form-control" id="pap-listing-type">
                    <option value="sale">${papT('pap_listing_type_sale')}</option>
                    <option value="rent">${papT('pap_listing_type_rent')}</option>
                </select>
            </div>

            <div class="pap-form-group">
                <label class="pap-form-label" id="pap-listing-price-label">${papT('pap_listing_price_label')}</label>
                <input type="number" class="pap-form-input pap-form-control" id="pap-listing-price" value="${papSelectedProperty.price || ''}" placeholder="Prix en $">
            </div>

            <div class="pap-form-group" id="pap-rent-duration-group" style="display: none;">
                <label class="pap-form-label">${papT('pap_listing_duration_label')}</label>
                <select class="pap-form-select pap-form-control" id="pap-rent-duration">
                    <option value="" disabled>${papT('pap_rent_duration_placeholder')}</option>
                    <option value="1">1 ${papT('pap_months')}</option>
                    <option value="3">3 ${papT('pap_months')}</option>
                    <option value="6">6 ${papT('pap_months')}</option>
                    <option value="12" selected>12 ${papT('pap_months')}</option>
                </select>
            </div>

            <div class="pap-form-group">
                <label class="pap-form-label">${papT('pap_listing_description_label')}</label>
                <textarea class="pap-form-textarea pap-form-control" id="pap-listing-description" placeholder="${papT('pap_listing_description_placeholder')}"></textarea>
            </div>
            </div>
        `,
        buttons: [
            {
                text: papT('pap_listing_create_btn'),
                class: 'pap-btn secondary multimodal-action-btn',
                onClick: function () {
                    papSubmitCreateListing();
                }
            }
        ],
        onOpen: function ($modal) {
            const $duration = $modal.find('#pap-rent-duration');
            if (!$duration.val()) {
                $duration.val('12');
            }

            $modal.find('#pap-listing-type').on('change', function () {
                const type = $(this).val();
                const $durationGroup = $modal.find('#pap-rent-duration-group');
                const $priceLabel = $modal.find('#pap-listing-price-label');

                if (type === 'rent') {
                    $durationGroup.show();
                    $priceLabel.text(papT('pap_listing_rent_price_label'));
                    if (!$duration.val()) {
                        $duration.val('12');
                    }
                } else {
                    $durationGroup.hide();
                    $priceLabel.text(papT('pap_listing_price_label'));
                }
            });
            $.post('https://next_housing/papModalOpened', JSON.stringify({}));
        },
        onClose: function () {
            papSelectedProperty = null;
            $.post('https://next_housing/papModalClosed', JSON.stringify({}));
        }
    });
}

function papCloseCreateListingModal() {
    window.ModalManager.close();
}



function papSubmitCreateListing() {
    if (!papSelectedProperty) return;

    const $modal = $('#dynamic-global-modal');
    const type = $modal.find('#pap-listing-type').val();
    const price = parseInt($modal.find('#pap-listing-price').val());
    const duration = type === 'rent' ? parseInt($modal.find('#pap-rent-duration').val()) : null;
    const description = $modal.find('#pap-listing-description').val();

    if (!price || price <= 0) {
        papShowAlert(papT('pap_error_invalid_price'));
        return;
    }

    if (type === 'rent' && (!duration || duration <= 0)) {
        papShowAlert(papT('pap_error_select_duration'));
        return;
    }

    $.post('https://next_housing/papCreateListing', JSON.stringify({
        houseId: papSelectedProperty.id,
        type: type,
        price: price,
        duration: duration,
        description: description
    }));

    window.ModalManager.close();
    papQueueDataRefresh();
}


let papCurrentOfferSellerId = null;
let papCurrentOfferSellerName = null;

function papOpenMakeOfferModal(listingId, listingPrice, sellerId, sellerName) {
    const listing = papListings.find(l => l.id === listingId);
    if (!listing) return;

    papCurrentOfferSellerId = sellerId || listing.sellerId;
    papCurrentOfferSellerName = sellerName || listing.sellerName || papT('pap_contract_seller');
    const offerHouseName = listing.houseName || `${papT('pap_property_number')}${listing.houseId || ''}`;

    window.ModalManager.open({
        title: papT('pap_modal_make_offer'),
        hint: offerHouseName,
        containerClass: 'pap-form-modal',
        footerClass: 'pap-form-modal-footer',
        bodyHTML: `
            <div class="agency-modal-main-block pap-form-main-block">
            <div class="section-header pap-main-block-header">
                <h3>${papT('pap_modal_make_offer')}</h3>
            </div>
            <input type="hidden" id="pap-offer-listing-id" value="${listingId}">
            <div class="pap-form-group">
                <label class="pap-form-label">${papT('pap_offer_amount_label')}</label>
                <input type="number" class="pap-form-input pap-form-control" id="pap-offer-amount" value="${listingPrice}" placeholder="${papT('pap_offer_amount_placeholder')}">
            </div>

            <div class="pap-form-group">
                <label class="pap-form-label">${papT('pap_offer_message_label')}</label>
                <textarea class="pap-form-textarea pap-form-control" id="pap-offer-message" placeholder="${papT('pap_offer_message_placeholder')}"></textarea>
            </div>
            </div>
        `,
        buttons: [
            {
                text: papT('pap_offer_send_btn'),
                class: 'pap-btn secondary multimodal-action-btn',
                onClick: function () {
                    papSubmitOffer();
                }
            }
        ],
        onOpen: function ($modal) {
            $.post('https://next_housing/papModalOpened', JSON.stringify({}));
        },
        onClose: function () {
            $.post('https://next_housing/papModalClosed', JSON.stringify({}));
        }
    });
}

function papCloseMakeOfferModal() {
    window.ModalManager.close();
}

function papSubmitOffer() {
    const $modal = $('#dynamic-global-modal');
    const listingId = parseInt($modal.find('#pap-offer-listing-id').val());
    const amount = parseInt($modal.find('#pap-offer-amount').val());
    const message = $modal.find('#pap-offer-message').val();

    if (!amount || amount <= 0) {
        papShowAlert(papT('pap_error_invalid_price'));
        return;
    }

    $.post('https://next_housing/papMakeOffer', JSON.stringify({
        listingId: listingId,
        amount: amount,
        message: message
    }));

    window.ModalManager.close();

    papSwitchTab('contracts');
    papToggleManagementView('offers', false);
    papQueueDataRefresh();
}

function papCloseAllModals() {
    papCloseCreateListingModal();
    papCloseMakeOfferModal();
    papCloseContractModal();

    papModalOpen = false;
    if (window.ModalManager && window.ModalManager.isOpen) {
        window.ModalManager.close();
    }
}





function papViewOnMap(coords) {
    $.post('https://next_housing/papViewOnMap', JSON.stringify({ coords: coords }));
}

function papContactSeller(sellerId, listingId, sellerName, listingPrice) {

    papOpenMakeOfferModal(listingId, listingPrice, sellerId, sellerName);
}

function papViewMyListing(houseId) {
    papSwitchTab('listings');

    const mySection = document.getElementById('pap-my-listings-section');
    if (mySection && !mySection.classList.contains('hidden')) {
        mySection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

function papDeleteListing(listingId) {
    papShowConfirm(papT('pap_confirm_delete_listing'), function () {
        papApplyListingDeletedLocally(listingId);
        $.post('https://next_housing/papDeleteListing', JSON.stringify({ listingId: listingId }));
        papQueueDataRefresh();
    });
}

function papAcceptOffer(offerId) {
    papShowConfirm(papT('pap_confirm_accept_offer'), function () {
        papApplyAcceptedOfferLocally(offerId);
        $.post('https://next_housing/papAcceptOffer', JSON.stringify({ offerId: offerId }));
        papQueueDataRefresh();
    });
}

function papDeclineOffer(offerId) {
    papShowConfirm(papT('pap_confirm_decline_offer'), function () {
        papApplyOfferRevertedLocally(offerId);
        $.post('https://next_housing/papDeclineOffer', JSON.stringify({ offerId: offerId }));
        papQueueDataRefresh();
    });
}

function papRefreshCurrentTab() {
    switch (papCurrentTab) {
        case 'my-properties':
            $.post('https://next_housing/papRefreshData', JSON.stringify({}));
            break;
        case 'listings':

            $.post('https://next_housing/papRefreshListings', JSON.stringify({}));
            $.post('https://next_housing/papRefreshMyListings', JSON.stringify({}));
            break;
        case 'contracts':

            $.post('https://next_housing/papRefreshContracts', JSON.stringify({}));
            break;
    }
}





function showPapContract(data) {
    papCurrentContract = data.contract;
    papTranslations = { ...papTranslations, ...data.translations };
    const papInterface = document.getElementById('pap-interface');
    papContractOpenedWithMenuVisible = !!(papInterface && !papInterface.classList.contains('hidden'));

    const notDefined = papT('job_contract_not_defined');
    const propertyNumber = papT('pap_property_number');
    const unknownZone = papT('pap_unknown_zone');
    const saleText = papT('job_contract_type_sale_upper');
    const rentText = papT('job_contract_type_rent_upper');
    const perMonth = papT('pap_price_per_month');
    const monthsText = papT('pap_months');

    const isRent = papCurrentContract.type === 'rent';

    $('#pap-contract-number').text(papCurrentContract.id);
    $('#pap-contract-seller-name').text(papCurrentContract.sellerName || notDefined);
    $('#pap-contract-buyer-name').text(papCurrentContract.buyerName || notDefined);
    $('#pap-contract-property-name').text(papCurrentContract.houseName || propertyNumber + papCurrentContract.houseId);
    $('#pap-contract-property-location').text(papCurrentContract.houseLocation || unknownZone);
    $('#pap-contract-property-interior').text(papCurrentContract.houseInterior);
    $('#pap-contract-property-garage').text(papGetGarageAvailabilityLabel(papCurrentContract.hasGarage));
    $('#pap-contract-type').text(isRent ? rentText : saleText);
    $('#pap-contract-price').text(papFormatPrice(papCurrentContract.price));

    if (isRent) {
        $('#pap-contract-duration-row').show();
        $('#pap-contract-duration').text((papCurrentContract.durationMonths || 1) + ' ' + monthsText);
        $('#pap-contract-rent-price-row').show();
        $('#pap-contract-monthly-rent').text(papFormatPrice(papCurrentContract.price) + perMonth);
    } else {
        $('#pap-contract-duration-row').hide();
        $('#pap-contract-rent-price-row').hide();
    }

    papHideSignatureError();

    $('#pap-contract-interface').data('contract-id', papCurrentContract.id);
    $('#pap-contract-interface').removeClass('hidden');

    setTimeout(function () {
        papInitSignatureCanvas();
    }, 100);
}

function papCloseContractModal() {
    $('#pap-contract-interface').addClass('hidden');
    papCurrentContract = null;

    if (papContractOpenedWithMenuVisible) {
        const papInterface = document.getElementById('pap-interface');
        if (papInterface && papInterface.classList.contains('hidden')) {
            papInterface.classList.remove('hidden');
        }
    }
    papContractOpenedWithMenuVisible = false;

    $.post('https://next_housing/closePapContractInterface', JSON.stringify({}));
}

let papSignatureCanvas = null;
let papSignatureCtx = null;
let papIsDrawing = false;
let papLastX = 0;
let papLastY = 0;

function papInitSignatureCanvas() {
    papSignatureCanvas = document.getElementById('pap-signature-canvas');
    if (!papSignatureCanvas) return;

    papSignatureCanvas.width = 200;
    papSignatureCanvas.height = 60;

    papSignatureCtx = papSignatureCanvas.getContext('2d');
    if (!papSignatureCtx) return;

    papSignatureCtx.strokeStyle = '#2c2c2c';
    papSignatureCtx.lineWidth = 2;
    papSignatureCtx.lineCap = 'round';
    papSignatureCtx.lineJoin = 'round';

    papSignatureCanvas.removeEventListener('mousedown', papStartDrawing);
    papSignatureCanvas.removeEventListener('mousemove', papDraw);
    papSignatureCanvas.removeEventListener('mouseup', papStopDrawing);
    papSignatureCanvas.removeEventListener('mouseout', papStopDrawing);
    papSignatureCanvas.removeEventListener('touchstart', papStartDrawingTouch);
    papSignatureCanvas.removeEventListener('touchmove', papDrawTouch);
    papSignatureCanvas.removeEventListener('touchend', papStopDrawing);

    papClearSignature();
    papSignatureCanvas.addEventListener('mousedown', papStartDrawing);
    papSignatureCanvas.addEventListener('mousemove', papDraw);
    papSignatureCanvas.addEventListener('mouseup', papStopDrawing);
    papSignatureCanvas.addEventListener('mouseout', papStopDrawing);

    papSignatureCanvas.addEventListener('touchstart', papStartDrawingTouch, { passive: false });
    papSignatureCanvas.addEventListener('touchmove', papDrawTouch, { passive: false });
    papSignatureCanvas.addEventListener('touchend', papStopDrawing);
}

function papGetScaledSignatureCoords(clientX, clientY) {
    const rect = papSignatureCanvas.getBoundingClientRect();
    const scaleX = papSignatureCanvas.width / rect.width;
    const scaleY = papSignatureCanvas.height / rect.height;
    return {
        x: (clientX - rect.left) * scaleX,
        y: (clientY - rect.top) * scaleY
    };
}

function papStartDrawing(e) {
    if (!papSignatureCanvas || !papSignatureCtx) return;

    papIsDrawing = true;
    const point = papGetScaledSignatureCoords(e.clientX, e.clientY);
    papLastX = point.x;
    papLastY = point.y;

    papSignatureCtx.beginPath();
    papSignatureCtx.arc(papLastX, papLastY, 1.5, 0, 2 * Math.PI);
    papSignatureCtx.fill();

    papShowClearButton();
    papHideSignatureError();
}

function papStartDrawingTouch(e) {
    if (!papSignatureCanvas || !papSignatureCtx) return;

    e.preventDefault();
    papIsDrawing = true;
    const touch = e.touches[0];
    const point = papGetScaledSignatureCoords(touch.clientX, touch.clientY);
    papLastX = point.x;
    papLastY = point.y;

    papSignatureCtx.beginPath();
    papSignatureCtx.arc(papLastX, papLastY, 1.5, 0, 2 * Math.PI);
    papSignatureCtx.fill();

    papShowClearButton();
    papHideSignatureError();
}

function papDraw(e) {
    if (!papIsDrawing) return;
    e.preventDefault();

    const point = papGetScaledSignatureCoords(e.clientX, e.clientY);
    papSignatureCtx.beginPath();
    papSignatureCtx.moveTo(papLastX, papLastY);
    papSignatureCtx.lineTo(point.x, point.y);
    papSignatureCtx.stroke();

    papLastX = point.x;
    papLastY = point.y;

    papShowClearButton();
    papHideSignatureError();
}

function papDrawTouch(e) {
    if (!papIsDrawing) return;
    e.preventDefault();
    const touch = e.touches[0];
    const point = papGetScaledSignatureCoords(touch.clientX, touch.clientY);

    papSignatureCtx.beginPath();
    papSignatureCtx.moveTo(papLastX, papLastY);
    papSignatureCtx.lineTo(point.x, point.y);
    papSignatureCtx.stroke();

    papLastX = point.x;
    papLastY = point.y;

    papShowClearButton();
    papHideSignatureError();
}

function papStopDrawing() {
    papIsDrawing = false;
}

function papShowClearButton() {
    const clearBtn = document.querySelector('#pap-contract-interface .signature-clear-btn');
    if (clearBtn) {
        clearBtn.classList.add('visible');
    }
}

function papHideClearButton() {
    const clearBtn = document.querySelector('#pap-contract-interface .signature-clear-btn');
    if (clearBtn) {
        clearBtn.classList.remove('visible');
    }
}

function papClearSignature() {
    if (!papSignatureCtx || !papSignatureCanvas) return;

    papSignatureCtx.clearRect(0, 0, papSignatureCanvas.width, papSignatureCanvas.height);
    papHideClearButton();
    papHideSignatureError();
}

function papHasSignature() {
    if (!papSignatureCtx || !papSignatureCanvas) return false;

    const imageData = papSignatureCtx.getImageData(0, 0, papSignatureCanvas.width, papSignatureCanvas.height);
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
        if (data[i + 3] !== 0) {
            return true;
        }
    }
    return false;
}

function papShowSignatureError() {
    const $error = $('#pap-signature-error');
    if ($error.length) {
        $error.addClass('visible');
        setTimeout(function () {
            papHideSignatureError();
        }, 2000);
    }
}

function papHideSignatureError() {
    const $error = $('#pap-signature-error');
    if ($error.length) {
        $error.removeClass('visible');
    }
}

function papHandleContractSignedSuccess(contractId, message) {
    const numericContractId = parseInt(contractId, 10);

    papCloseContractModal();

    if (Number.isFinite(numericContractId) && numericContractId > 0) {
        papApplyContractCompletedLocally(numericContractId);
    }

    papQueueDataRefresh();
    papShowAlert(message || papT('pap_success_contract_signed'));
    papSwitchTab('contracts');
    papToggleManagementView('contracts', false);
}

function papSignContract() {
    if (!papHasSignature()) {
        papShowSignatureError();
        return;
    }

    papHideSignatureError();

    if (!papCurrentContract) return;

    const contractId = parseInt(
        (papCurrentContract && papCurrentContract.id) || $('#pap-contract-interface').data('contract-id'),
        10
    );

    if (!Number.isFinite(contractId) || contractId <= 0) {
        papShowAlert(papT('pap_error_contract_not_found'));
        return;
    }

    const requestToken = `${Date.now()}_${Math.random()}`;
    papPendingSignRequest = {
        token: requestToken,
        contractId: contractId
    };

    $.post('https://next_housing/papSignContract', JSON.stringify({
        contractId: contractId
    }), function (response) {
        if (!papPendingSignRequest || papPendingSignRequest.token !== requestToken) {
            return;
        }

        let result = response;

        if (typeof response === 'string') {
            try {
                result = JSON.parse(response);
            } catch (_) {
            }
        }

        const isSuccess = !!(
            (result && typeof result === 'object' && result.success === true) ||
            (result && typeof result === 'object' && result.status === 'success') ||
            (result && typeof result === 'object' && result.ok === true) ||
            result === true ||
            result === 1 ||
            result === 'ok' ||
            result === 'true' ||
            (Array.isArray(result) && (result[0] === true || result[0] === 1 || result[0] === 'ok' || result[0] === 'true'))
        );

        if (isSuccess) {
            papPendingSignRequest = null;
            const successMessage = (result && result.message) || (Array.isArray(result) && result[1]) || papT('pap_success_contract_signed');
            papHandleContractSignedSuccess(contractId, successMessage);
        } else {
            papPendingSignRequest = null;
            const message = (result && (result.message || result.error)) || papT('pap_error_payment_failed');
            papShowAlert(message);
        }
    }).fail(function () {
        if (!papPendingSignRequest || papPendingSignRequest.token !== requestToken) {
            return;
        }
        papPendingSignRequest = null;
        papShowAlert(papT('pap_error_payment_failed'));
    });
}

function papDeclineContract() {
    if (!papCurrentContract) return;

    papShowConfirm(papT('pap_confirm_decline_contract_buyer'), function () {
        const contractId = papCurrentContract.id;
        papApplyOfferRevertedLocally(contractId);
        $.post('https://next_housing/papDeclineContract', JSON.stringify({
            contractId: contractId
        }), function (response) {
            papCloseContractModal();
        });
        papQueueDataRefresh();
    });
}





function papShowAlert(message) {
    const safeMessage = papEscapeHtml(message || '');
    window.ModalManager.open({
        title: papT('pap_modal_info_title'),
        containerClass: 'multimodal-message-modal',
        autoCancelButton: true,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${safeMessage}
            </div>
        `,
        buttons: [
            {
                text: papT('pap_modal_ok'),
                class: 'pap-btn primary multimodal-action-btn',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ]
    });
}

function papCloseAlert() {
    window.ModalManager.close();
}

let papConfirmCallback = null;

function papShowConfirm(message, callback) {
    const contractEl = document.getElementById('pap-contract-interface');
    const contractWasVisible = !!(contractEl && !contractEl.classList.contains('hidden') && papCurrentContract);
    let confirmed = false;
    const safeMessage = papEscapeHtml(message || '');

    if (contractWasVisible) {
        contractEl.classList.add('hidden');
    }

    window.ModalManager.open({
        title: papT('pap_modal_confirm_title'),
        containerClass: 'multimodal-message-modal',
        autoCancelButton: true,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center;">
                ${safeMessage}
            </div>
        `,
        buttons: [
            {
                text: papT('pap_modal_confirm'),
                class: 'pap-btn primary multimodal-action-btn',
                onClick: function () {
                    confirmed = true;
                    if (callback) callback();
                    window.ModalManager.close();
                }
            }
        ],
        onClose: function () {
            if (contractWasVisible && !confirmed && papCurrentContract && contractEl) {
                contractEl.classList.remove('hidden');
            }
        }
    });
}

function papConfirmYes() {
    
    
    window.ModalManager.close();
}

function papConfirmNo() {
    window.ModalManager.close();
}


let papPromptCallback = null;

function papShowPrompt(message, defaultValue, callback) {
    papPromptCallback = callback;
    const modal = document.getElementById('pap-prompt-modal');
    if (modal) {
        document.getElementById('pap-prompt-message').textContent = message;
        document.getElementById('pap-prompt-input').value = defaultValue || '';
        modal.classList.remove('hidden');
        document.getElementById('pap-prompt-input').focus();
    } else {

        const result = prompt(message, defaultValue);
        if (result !== null) {
            callback(result);
        }
    }
}

function papPromptConfirm() {
    const modal = document.getElementById('pap-prompt-modal');
    const input = document.getElementById('pap-prompt-input');
    if (modal) {
        modal.classList.add('hidden');
    }
    if (papPromptCallback && input) {
        papPromptCallback(input.value);
        papPromptCallback = null;
    }
}

function papPromptCancel() {
    const modal = document.getElementById('pap-prompt-modal');
    if (modal) {
        modal.classList.add('hidden');
    }
    papPromptCallback = null;
}





window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data || typeof data !== 'object') {
        return;
    }

    switch (data.type) {
        case 'showPapInterface':
            showPapInterface(data);
            break;
        case 'papCommandChanged':
            papUpdateCommandHint(data && data.papCommand);
            break;
        case 'hidePapInterface':
            hidePapInterface();
            break;
        case 'updatePapMyProperties':
            papMyProperties = papNormalizeArray(data.myProperties);
            papPropertyDetailsCache.clear();
            if (papCurrentTab === 'my-properties') {
                papRenderMyProperties();
            }

            if (window.ModalManager && window.ModalManager.isOpen) {
                const $modal = $('#dynamic-global-modal');
                if ($modal.length && !$modal.hasClass('hidden')) {
                    const houseData = $modal.data('house');
                    if (houseData && houseData.isPapProperty) {

                        const updatedProperty = papMyProperties.find(function (p) {
                            return p.id === houseData.id;
                        });
                        if (updatedProperty) {
                            papFetchPropertyDetails(updatedProperty.id, true).then(function (detailedProperty) {
                                const resolvedProperty = papMergePropertyData(updatedProperty, detailedProperty);
                                if (!resolvedProperty) {
                                    return;
                                }

                                const updatedHouseData = papConvertPropertyToHouseData(resolvedProperty);
                                showHouseDetails(updatedHouseData);
                            });
                        }
                    }
                }
            }
            break;
        case 'updatePapListings':
            papListings = papNormalizeArray(data.listings);
            if (papCurrentTab === 'listings') {
                papToggleListingsView();
            }
            break;
        case 'updatePapMyListings':
            papMyListings = papNormalizeArray(data.myListings);
            if (papCurrentTab === 'listings') {
                papToggleListingsView();
            }
            break;
        case 'updatePapContracts':
            papContracts = papNormalizeArray(data.contracts);
            if (papCurrentTab === 'contracts') {

                if (papCurrentManagementView === 'offers') {
                    let offers = papContracts.filter(c => c.status === 'offer_pending' || c.status === 'accepted');
                    if (offers.length === 0) {
                        papToggleManagementView('contracts');
                        return;
                    }
                }
                papRenderContracts();
            }
            break;
        case 'showPapContract':
            showPapContract(data);
            break;
        case 'closePapContractInterface':
            if (papPendingSignRequest && papPendingSignRequest.contractId) {
                const pendingContractId = papPendingSignRequest.contractId;
                papPendingSignRequest = null;
                papHandleContractSignedSuccess(pendingContractId, papT('pap_success_contract_signed'));
            } else {
                papCloseContractModal();
            }
            break;
        case 'papContractSigned':

            $.post('https://next_housing/papRefreshData', JSON.stringify({}));
            break;
        case 'papLanguageChanged':
            papTranslations = data.translations || {};

            papApplyStaticTexts();
            papSwitchTab(papCurrentTab);
            break;
        case 'papHousePreviewPlaceholdersSettingChanged':
            papApplyHousePreviewPlaceholdersSetting(data && data.enabled, true);
            if (papCurrentTab === 'my-properties') {
                papRenderMyProperties();
            } else if (papCurrentTab === 'listings') {
                papToggleListingsView();
            }
            break;
        case 'papNewMessage':
            papHandleNewMessage(data);
            break;
        case 'papOfferCreated':

            setTimeout(function () {
                papSwitchTab('contracts');

                setTimeout(function () {
                    papOpenChat(data.offerId, false, data.buyerName, data.sellerName);
                }, 500);
            }, 300);
            break;
        case 'papHousesUpdated':
            if (papCurrentTab === 'my-properties') {
                papMyPropertiesNeedsRefresh = true;
                break;
            }

            papRefreshCurrentTab();
            break;
    }
});









$(document).on('keydown.papInterface', function (event) {
    if (event.key === 'Escape') {
        const papInterface = document.getElementById('pap-interface');
        if (!papInterface || papInterface.classList.contains('hidden')) return;

        
        const lightbox = document.getElementById('image-lightbox');
        if (lightbox && !lightbox.classList.contains('hidden')) {
            event.preventDefault();
            event.stopPropagation();
            if (typeof event.stopImmediatePropagation === 'function') {
                event.stopImmediatePropagation();
            }
            return;
        }

        if (window.ModalManager && window.ModalManager.isOpen) {
            event.preventDefault();
            event.stopPropagation();
            if (typeof event.stopImmediatePropagation === 'function') {
                event.stopImmediatePropagation();
            }
            return;
        }

        const houseDetails = document.getElementById('house-details-modal');
        if (houseDetails && !houseDetails.classList.contains('hidden')) {
            
            return;
        }

        const papContract = document.getElementById('pap-contract-interface');
        if (papContract && !papContract.classList.contains('hidden')) {
            papCloseContractModal();
            event.preventDefault();
            event.stopPropagation();
            if (typeof event.stopImmediatePropagation === 'function') {
                event.stopImmediatePropagation();
            }
            return;
        }

        if (papModalOpen) {
            papCloseAllModals();
            event.preventDefault();
            event.stopPropagation();
            if (typeof event.stopImmediatePropagation === 'function') {
                event.stopImmediatePropagation();
            }
        } else {
            
            
            
            $.post('https://next_housing/closePapInterface', JSON.stringify({}));
            hidePapInterface();
            event.preventDefault();
            event.stopPropagation();
            if (typeof event.stopImmediatePropagation === 'function') {
                event.stopImmediatePropagation();
            }
        }
    }
});
