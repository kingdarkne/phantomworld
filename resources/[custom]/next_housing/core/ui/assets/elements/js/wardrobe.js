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
let currentOutfits = [];

function normalizeOutfits(outfits) {
    if (Array.isArray(outfits)) return outfits;
    if (outfits && typeof outfits === 'object') return Object.values(outfits);
    return [];
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.translations) {
        window.translations = data.translations;
        translateWardrobe();
    }

    if (data.type === 'openWardrobe') {
        currentOutfits = normalizeOutfits(data.outfits);
        OpenWardrobeMenu();
    } else if (data.type === 'refreshWardrobe') {
        currentOutfits = normalizeOutfits(data.outfits);
        translateWardrobe();
        renderOutfits();
        renderManageList();
    } else if (data.type === 'languageChanged') {
        translateWardrobe();
        if ($("#wardrobe-container").is(":visible")) {
            renderOutfits();
            renderManageList();
        }
    }
});

function translateWardrobe() {
    const translations = window.translations || {};
    $("#wardrobe-container [data-translate]").each(function () {
        const key = $(this).attr('data-translate');
        if (translations[key]) {
            $(this).text(translations[key]);
        }
    });

    $("#wardrobe-container [data-translate-placeholder]").each(function () {
        const key = $(this).attr('data-translate-placeholder');
        if (translations[key]) {
            $(this).attr('placeholder', translations[key]);
        }
    });
}

function OpenWardrobeMenu() {
    translateWardrobe();
    $("#wardrobe-container").addClass('show');
    renderOutfits();
    renderManageList();
    switchWardrobeTab('outfits');
}

function CloseWardrobe() {
    $("#wardrobe-container").removeClass('show');
    $.post(`https://next_housing/closeWardrobe`, JSON.stringify({}));
}

function switchWardrobeTab(tabId) {
    $(".wardrobe-nav-item").removeClass('active');
    $(`.wardrobe-nav-item[data-wardrobe-tab="${tabId}"]`).addClass('active');

    $(".wardrobe-tab-panel").removeClass('active');
    $(`#wardrobe-tab-${tabId}`).addClass('active');
}

function getActiveWardrobeTab() {
    const tab = $(".wardrobe-nav-item.active").data('wardrobe-tab');
    return tab || 'outfits';
}

$(document).on('click', '.wardrobe-nav-item', function () {
    const tabId = $(this).data('wardrobe-tab');
    switchWardrobeTab(tabId);
});

$(document).on('click', '#wardrobe-refresh-btn', function () {
    const activeTab = getActiveWardrobeTab();
    $.post(`https://next_housing/refreshWardrobe`, JSON.stringify({}));
    switchWardrobeTab(activeTab);
});

$(document).on('click', '#wardrobe-outfits-list .outfit-card', function (e) {
    if ($(e.target).closest('.wardrobe-card-actions').length) return;
    const $card = $(this);
    const id = $card.data('outfitId');
    const name = $card.data('outfitName');
    if (id == null) return;
    ApplyOutfit(id, name);
});

$(document).on('click', '#wardrobe-manage-list .wardrobe-icon-btn', function (e) {
    e.preventDefault();
    const $btn = $(this);
    if ($btn.hasClass('is-disabled')) return;
    const action = $btn.data('action');
    const id = $btn.data('outfitId');
    const name = $btn.data('outfitName');
    if (!action || id == null) return;

    if (action === 'update') {
        UpdateOutfit(id, name);
    } else if (action === 'rename') {
        OpenRenameOutfit(id, name);
    } else if (action === 'delete') {
        DeleteOutfit(id, name);
    }
});

function renderOutfits() {
    const translations = window.translations || {};
    const list = $("#wardrobe-outfits-list");
    list.empty();

    if (!currentOutfits || currentOutfits.length === 0) {
        $("#wardrobe-outfits-empty").show();
        updateWardrobeCount();
        return;
    }

    $("#wardrobe-outfits-empty").hide();
    updateWardrobeCount();

    const sortedOutfits = sortOutfits(currentOutfits);
    sortedOutfits.forEach((outfit) => {
        const outfitName = outfit.outfitname || outfit.name || translations['wardrobe_no_name'];
        const outfitId = outfit.outfitId || outfit.outfitid || outfit.id || 0;
        const card = $(`
            <div class="outfit-card">
                <i class="ph ph-t-shirt"></i>
                <div class="outfit-info">
                    <h3></h3>
                </div>
                <div class="wardrobe-card-actions">
                    <i class="ph ph-caret-right" style="opacity: 0.3; font-size: 14px;"></i>
                </div>
            </div>
        `);
        card.data('outfitId', outfitId);
        card.data('outfitName', outfitName);
        card.find('h3').text(outfitName);
        list.append(card);
    });
}

function renderManageList() {
    const translations = window.translations || {};
    const list = $("#wardrobe-manage-list");
    list.empty();

    if (!currentOutfits || currentOutfits.length === 0) {
        const emptyMsg = translations['wardrobe_no_outfit_saved'];
        list.html(`<div class="wardrobe-empty-state"><p>${emptyMsg}</p></div>`);
        updateWardrobeCount();
        return;
    }

    updateWardrobeCount();
    const sortedOutfits = sortOutfits(currentOutfits);
    sortedOutfits.forEach((outfit) => {
        const outfitName = outfit.outfitname || outfit.name || translations['wardrobe_no_name'];
        const outfitId = outfit.outfitId || outfit.outfitid || outfit.id || 0;

        const isTemp = !!outfit.__temp;
        const updateTitle = translations['wardrobe_update_btn'];
        const renameTitle = translations['wardrobe_rename_btn'];
        const deleteTitle = translations['wardrobe_delete_btn'];
        const tempTitle = translations['wardrobe_syncing'];

        const actionsHtml = isTemp
            ? `
                <div class="wardrobe-card-actions">
                    <button class="wardrobe-icon-btn is-disabled" title="${tempTitle}" disabled>
                        <i class="ph ph-clock"></i>
                        <span class="btn-text">${tempTitle}</span>
                    </button>
                </div>
            `
            : `
                <div class="wardrobe-card-actions">
                    <button class="wardrobe-icon-btn rename" data-action="rename" title="${renameTitle}">
                        <i class="ph ph-pencil-simple"></i>
                        <span class="btn-text">${renameTitle}</span>
                    </button>
                    <button class="wardrobe-icon-btn update" data-action="update" title="${updateTitle}">
                        <i class="ph ph-arrows-clockwise"></i>
                        <span class="btn-text">${updateTitle}</span>
                    </button>
                    <button class="wardrobe-icon-btn delete" data-action="delete" title="${deleteTitle}">
                        <i class="ph ph-trash"></i>
                    </button>
                </div>
            `;

        const card = $(`
            <div class="outfit-card">
                <i class="ph ph-user"></i>
                <div class="outfit-info">
                    <h3></h3>
                </div>
                ${actionsHtml}
            </div>
        `);
        card.data('outfitId', outfitId);
        card.data('outfitName', outfitName);
        card.find('h3').text(outfitName);
        if (!isTemp) {
            card.find('.wardrobe-icon-btn').data('outfitId', outfitId).data('outfitName', outfitName);
        }
        list.append(card);
    });
}

function ApplyOutfit(id, name) {
    $.post(`https://next_housing/applyOutfit`, JSON.stringify({
        id: id,
        name: name
    }));
    CloseWardrobe();
}

function SaveWardrobeOutfit() {
    const name = $("#wardrobe-new-name").val().trim();
    if (!name) return;

    $.post(`https://next_housing/saveOutfit`, JSON.stringify({
        name: name
    }));

    $("#wardrobe-new-name").val("");
    addTempOutfit(name);
    renderOutfits();
    renderManageList();
    switchWardrobeTab('outfits');
    setTimeout(() => {
        $.post(`https://next_housing/refreshWardrobe`, JSON.stringify({}));
    }, 350);
}

function UpdateOutfit(id, name) {
    $.post(`https://next_housing/updateOutfit`, JSON.stringify({
        id: id,
        name: name
    }));
    CloseWardrobe();
}

function DeleteOutfit(id, name) {
    const translations = window.translations || {};
    const title = translations['wardrobe_delete_title'] || translations['job_modal_confirmation'];
    const body = translations['wardrobe_delete_confirm'] || translations['wardrobe_delete_click_to_delete'];
    const confirmText = translations['wardrobe_delete_btn'];

    if (window.ModalManager) {
        window.ModalManager.open({
            title: title,
            containerClass: 'multimodal-message-modal',
            autoCancelButton: true,
            bodyHTML: `
                <div class="pap-prompt-label" style="text-align: center; margin-bottom: 12px;">
                    ${escapeHtml(body)}
                </div>
            `,
            buttons: [
                {
                    text: confirmText,
                    class: 'pap-btn primary multimodal-action-btn',
                    onClick: function () {
                        window.ModalManager.close();
                        DeleteOutfitConfirmed(id, name);
                    }
                }
            ]
        });
        return;
    }

    if (!confirm(body)) return;
    DeleteOutfitConfirmed(id, name);
}

function DeleteOutfitConfirmed(id, name) {
    $.post(`https://next_housing/deleteOutfit`, JSON.stringify({
        id: id,
        name: name
    }));

    currentOutfits = currentOutfits.filter(o => {
        const oid = o.outfitId || o.outfitid || o.id;
        return oid != id;
    });
    renderOutfits();
    renderManageList();
}

function OpenRenameOutfit(id, currentName) {
    const translations = window.translations || {};
    const title = translations['wardrobe_rename_title'] || translations['wardrobe_rename_btn'];
    const placeholder = translations['wardrobe_rename_placeholder'];
    const confirmText = translations['wardrobe_rename_confirm'];
    const cancelText = translations['job_modal_cancel_btn'];
    const safeValue = escapeHtml(currentName);

    if (!window.ModalManager) {
        const newName = prompt(title, currentName || '');
        if (!newName) return;
        RenameOutfit(id, currentName, newName.trim());
        return;
    }

    window.ModalManager.open({
        title: title,
        bodyHTML: `
            <div class="pap-prompt-label" style="text-align: center; margin-bottom: 12px;">
                ${translations['wardrobe_input_name_desc']}
            </div>
            <input type="text" id="wardrobe-rename-input" class="pap-form-input" value="${safeValue}" placeholder="${escapeHtml(placeholder)}" maxlength="20">
        `,
        buttons: [
            {
                text: confirmText,
                class: 'pap-btn primary',
                onClick: function () {
                    const $input = $('#wardrobe-rename-input');
                    const newName = ($input.val() || '').trim();
                    if (!newName || newName === currentName) {
                        window.ModalManager.close();
                        return;
                    }
                    RenameOutfit(id, currentName, newName);
                    window.ModalManager.close();
                }
            },
            {
                text: cancelText,
                class: 'pap-btn secondary',
                onClick: function () {
                    window.ModalManager.close();
                }
            }
        ],
        onOpen: function (body) {
            const $input = body.find('#wardrobe-rename-input');
            $input.focus();
            $input.select();
        }
    });
}

function RenameOutfit(id, oldName, newName) {
    if (!newName) return;
    const idStr = String(id);
    currentOutfits = (currentOutfits || []).map(o => {
        if (!o) return o;
        const oid = o.outfitId || o.outfitid || o.id;
        if (String(oid) !== idStr) return o;
        const updated = { ...o };
        if ('outfitname' in updated) updated.outfitname = newName;
        if ('name' in updated) updated.name = newName;
        if (!('outfitname' in updated) && !('name' in updated)) updated.outfitname = newName;
        return updated;
    });
    renderOutfits();
    renderManageList();
    $.post(`https://next_housing/renameOutfit`, JSON.stringify({
        id: id,
        name: oldName,
        newName: newName
    }));
    setTimeout(() => {
        $.post(`https://next_housing/refreshWardrobe`, JSON.stringify({}));
    }, 700);
}

function addTempOutfit(name) {
    const normalized = name.toLowerCase();
    const exists = (currentOutfits || []).some(o => {
        const n = (o.outfitname || o.name || '').toString().toLowerCase();
        return n === normalized;
    });
    if (exists) return;

    const tempOutfit = {
        outfitname: name,
        outfitId: `temp-${Date.now()}`,
        __temp: true
    };

    currentOutfits = [tempOutfit, ...(currentOutfits || [])];
}

function sortOutfits(outfits) {
    const list = Array.isArray(outfits) ? [...outfits] : [];
    const temps = list.filter(o => o && o.__temp);
    const rest = list.filter(o => !(o && o.__temp));
    return [...temps, ...rest.reverse()];
}

function updateWardrobeCount() {
    const count = Array.isArray(currentOutfits) ? currentOutfits.length : 0;
    const translations = window.translations || {};
    const label = translations.wardrobe_outfits_label;
    $("#wardrobe-outfit-count").text(`${count} ${label}`);
}

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.keyCode === 27) {
        if (!$("#wardrobe-container").is(":visible")) {
            return;
        }

        const lightboxVisible = $('#image-lightbox').length && !$('#image-lightbox').hasClass('hidden');
        if (lightboxVisible) {
            e.preventDefault();
            e.stopPropagation();
            return;
        }

        if (window.ModalManager && window.ModalManager.isOpen) {
            e.preventDefault();
            e.stopPropagation();
            window.ModalManager.close();
            setTimeout(() => {
                $.post('https://next_housing/focus', JSON.stringify({ focus: true }));
            }, 10);
            return;
        }

        e.preventDefault();
        e.stopPropagation();
        CloseWardrobe();
    }
}, true);
