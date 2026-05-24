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
let currencySymbol = '$';
let manageHouseSearchQuery = '';

window.formatPrice = function (price) {
    if (typeof price === 'undefined' || price === null) return '0 ' + currencySymbol;
    const formatted = new Intl.NumberFormat('fr-FR', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(price);
    return formatted + ' ' + currencySymbol;
};

function loadCurrencySymbol() {
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
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            if (data && data.symbol) {
                currencySymbol = data.symbol;
                window.currencySymbol = currencySymbol;
                $('#currency-symbol').val(currencySymbol);

                updatePapListingFeeLabel();
                updateManagePriceLabel();
                updateCreatePriceLabel();
            } else {
                currencySymbol = '$';
                window.currencySymbol = currencySymbol;
                $('#currency-symbol').val(currencySymbol);
                updatePapListingFeeLabel();
                updateManagePriceLabel();
                updateCreatePriceLabel();
            }
        } catch (_) {
            currencySymbol = '$';
            window.currencySymbol = currencySymbol;
            $('#currency-symbol').val(currencySymbol);
            updatePapListingFeeLabel();
            updateManagePriceLabel();
            updateCreatePriceLabel();
        }
    });
}

function loadAllHousesData(callback) {
    if (typeof allHousesData !== 'undefined' && allHousesData.length > 0) {
        if (callback) callback(allHousesData);
        return;
    }

    $.post('https://next_housing/getAllHouses', JSON.stringify({}), function (resp) {
        try {
            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
            allHousesData = Array.isArray(data) ? data : [];
        } catch (e) {
            allHousesData = [];
        }
        if (callback) callback(allHousesData);
    }).fail(function () {
        allHousesData = [];
        if (callback) callback(allHousesData);
    });
}

function getManageHouseSearchPlaceholder() {
    return getTranslation('job_search_houses_placeholder');
}

function getManageHouseSearchResults() {
    if (typeof allHousesData === 'undefined' || !Array.isArray(allHousesData)) {
        return [];
    }

    const query = String(manageHouseSearchQuery || '').trim().toLowerCase();
    if (!query) {
        return allHousesData;
    }

    return allHousesData.filter(function (house) {
        const normalizedHouse = (typeof window.normalizeManageHouseRecord === 'function')
            ? window.normalizeManageHouseRecord(house)
            : house;
        const ownerName = normalizedHouse.oname || '';
        const ownerIdentifier = normalizedHouse.oidentifier || '';
        const houseName = normalizedHouse.name || '';
        const houseId = normalizedHouse.id != null ? String(normalizedHouse.id) : '';
        const houseType = (typeof getHouseType === 'function')
            ? getHouseType(normalizedHouse.interior)
            : getHouseTypeFromInterior(normalizedHouse.interior);

        return [
            houseName,
            houseId,
            ownerName,
            ownerIdentifier,
            houseType
        ].some(function (value) {
            return String(value || '').toLowerCase().includes(query);
        });
    });
}

function updateManageHousesEmptyState(hasSearchQuery) {
    const emptyState = $('#manage-houses-empty');
    const title = emptyState.find('h2').first();
    const message = emptyState.find('p').first();

    if (!emptyState.length || !title.length || !message.length) {
        return;
    }

    if (hasSearchQuery) {
        title.text(getTranslation('no_results_found'));
        message.text(getTranslation('job_empty_search'));
        return;
    }

    title.text(getTranslation('no_properties_created_title'));
    message.text(
        String(
            getTranslation('no_properties_created_message')
        ).replace(/%s/g, getTranslation('create'))
    );
}

function updatePapListingFeeLabel() {
    const label = $('#pap-listing-fee-label');
    if (!label.length) return;

    const baseText = (translations && translations.pap_listing_fee_label)
        ? translations.pap_listing_fee_label.replace(/\s*\(.*\)\s*$/, '')
        : label.text().replace(/\s*\(.*\)\s*$/, '');


    label.text(`${baseText} (${currencySymbol})`);
}

function updateManagePriceLabel() {
    const priceLabel = $('#tab-edit .info-label').eq(3);
    if (!priceLabel.length) return;

    const baseText = (translations && translations.price) ? translations.price : priceLabel.text().replace(/\s*\(.*\)\s*$/, '');
    priceLabel.text(`${baseText} (${currencySymbol})`);
}

function updateCreatePriceLabel() {
    const label = $('#money2 label[for="money"]');
    if (label.length) {
        const requiredSpan = label.find('span').first().prop('outerHTML') || '';
        const baseLabel = (translations && translations.house_price)
            ? translations.house_price.replace(/\s*\(.*\)\s*$/, '')
            : label.clone().children().remove().end().text().trim().replace(/\s*\(.*\)\s*$/, '');
        
        label.html(`${baseLabel} ${requiredSpan}`.trim());

    }

    const input = $('#money');
    if (input.length) {
        let placeholder = (translations && translations.enter_price)
            ? translations.enter_price
            : (input.attr('placeholder') || '');

        
        placeholder = placeholder.replace(/\$/g, currencySymbol);


        
        if (!placeholder.includes(currencySymbol)) {

            placeholder = `${placeholder.trim()} ${currencySymbol}`.trim();
        }

        input.attr('placeholder', placeholder);
    }
}




function showManageLoadingState() {
    $("#manage-loading-state").show();
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

    const loadingText = (translations && translations.loading_houses);
    $("#manage-loading-text").text(loadingText);
}

function showManageEmptyState() {
    $("#manage-loading-state").hide();

    loadAllHousesData(function () {
        displayEmptyStateMessage();
    });
}

function displayEmptyStateMessage() {
    $("#empty-state").show();
    $("#house-info-state").hide();
    $("#delete-btn").hide();
    $("#toggle-lock-btn").hide();
    $("#interior-change-section").hide();
    $("#show-more-options-container").hide();
    $("#coords-sections-container").hide();
    $("#entrance-coords-section").hide();
    $("#garage-coords-section").hide();
    $(".create-form").addClass("no-scroll");

    const hasNoProperties = typeof allHousesData !== 'undefined' && allHousesData.length === 0;

    if (hasNoProperties) {
        const createTabName = (translations && translations.create);
        const title = (translations && translations.no_properties_created_title);
        const messageTemplate = (translations && translations.no_properties_created_message);
        const translatedMessage = messageTemplate.replace(/%s/g, createTabName);

        $("#empty-state-title").text(title);
        $("#empty-state-message").text(translatedMessage);
    } else {
        $("#empty-state-title").text((translations && translations.no_house_nearby));
        $("#empty-state-message").text((translations && translations.no_house_message));
    }
}

function showManageInfoState() {
    $("#manage-loading-state").hide();
    $("#empty-state").hide();
    $("#house-info-state").show();
    $("#delete-btn").css('display', 'inline-flex');
    $("#toggle-lock-btn").show();
    $("#interior-change-section").show();
    $("#show-more-options-container").show();
    $("#coords-sections-container").hide();
    $("#entrance-coords-section").css('display', 'flex');
    $("#garage-coords-section").css('display', 'flex');
    $(".create-form").removeClass("no-scroll");

    if (typeof window.nhApplyGarageEnabledState === 'function') {
        window.nhApplyGarageEnabledState(window.nhGaragesEnabled === true, { syncToggle: false });
    }
}






function translateInterface() {
    if (!translations || Object.keys(translations).length === 0) return;

    $("[data-translate]").each(function () {
        const key = $(this).attr('data-translate');
        if (translations && translations[key]) {
            const translationText = translations[key];
            if (translationText.includes('<') || translationText.includes('&lt;')) {
                $(this).html(translationText);
            } else {
                $(this).text(translationText);
            }
        }
    });

    $("#main-title .title-text").text(translations.title);
    $(".tab-btn[data-tab='edit']").not("[data-translate]").text(translations.manage);
    $(".tab-btn[data-tab='create']").not("[data-translate]").text(translations.create);
    $(".tab-btn[data-tab='settings']").not("[data-translate]").text(translations.settings_tab || translations.settings);
    $("#manage-basic-info-title").text(translations.basic_info);
    $("#manage-status-price-title").text(translations.status_price);
    $("#manage-house-search-input").attr('placeholder', getManageHouseSearchPlaceholder());
    if (typeof listModeActive !== 'undefined' && listModeActive) {
        $("#list-mode-btn-text").text(getTranslation('normal_mode'));
    } else {
        $("#list-mode-btn-text").text(getTranslation('list_mode'));
    }

    if (typeof listModeActive !== 'undefined' && listModeActive && typeof allHousesData !== 'undefined' && allHousesData.length > 0) {
        renderManageHousesList();
    }

    $(".info-label").each(function (index) {
        if (index === 0) $(this).text(translations.house_id);
        else if (index === 1) $(this).text(translations.builder);
        else if (index === 2) $(this).text(translations.owner);
        else if (index === 3) $(this).text(translations.price);
        else if (index === 4) $(this).text(translations.status);
        else if (index === 5) $(this).text(translations.interior);
    });
    updateManagePriceLabel();

    $("#manage-change-property-title").text(translations.change_property);
    $("#visit-interior-btn .btn-text").text(translations.visit);
    $("#visit-interior-btn-create .btn-text").text(translations.visit);
    $("#toggle-lock-btn .btn-text").text(translations.toggle_lock);
    $(".action-btn.tertiary .btn-text").text(translations.close);
    $("#create-house-finish-text").text(translations.create_house);
    $("#shells-save-btn .btn-text").text(translations.create_shell);
    $("#shells-save-edit-btn .btn-text").text(translations.save);
    $("#create-house-reset-text").text(translations.reset_form);
    $(".action-btn.secondary .btn-text").not("#toggle-lock-btn .btn-text").text(translations.reset_form);
    $("#delete-btn .btn-text").text(translations.delete_property);
    $("#validate-interior-btn .btn-text").text(translations.validate_interior);

    $("[data-translate='assign_to_player']").text(translations.assign_to_player);
    $("[data-translate='give_builder_keys']").text(translations.give_builder_keys);
    $("[data-translate='player_id_field']").html((translations.player_id_field) + " <span style=\"color: #ff4444;\">*</span>");
    $("[data-translate='house_price']").html((translations.house_price) + " <span style=\"color: #ff4444;\">*</span>");
    $("[data-placeholder='enter_server_id']").attr('placeholder', translations.enter_server_id);
    $("[data-placeholder='enter_price']").attr('placeholder', translations.enter_price);
    $("[data-translate='player_assignment']").text(translations.player_assignment);
    $("[data-translate='pricing']").html((translations.pricing) + " <span style=\"color: #ff4444;\">*</span>");
    $("#section-interior h4").text(translations.interior_style);
    updateCreatePriceLabel();

    $("#section-settings-languages .card-header h4").text(translations.language_selection);
    $("#language-help").text(translations.choose_language_message);
    $("#section-settings-languages label[for='language-select']").text(translations.language_selection);
    $("#save-language-btn .btn-text").text(translations.save_language);

    $("#section-settings-markers .config-card:first-child .card-header h4").text(translations.interaction_icons);
    $("#section-settings-markers .config-card:first-child .card-content p").text(translations.interaction_icons_help);
    $("#section-settings-markers label[for='sprites-enabled']").text(translations.hide_interaction_icons);
    $("#section-settings-markers .config-card:nth-child(2) .card-header h4").text(translations.map_blips);
    $("#section-settings-markers .config-card:nth-child(2) .card-content p").text(translations.map_blips_help);
    $("#section-settings-markers label[for='blips-enabled']").text(translations.hide_blips);
    $("#section-settings-markers .config-card:first-child .card-content p").text(translations.interaction_icons_help);
    $("#section-settings-markers label[for='sprites-enabled']").text(translations.hide_interaction_icons);
    $("#section-settings-markers .config-card:nth-child(2) .card-content p").text(translations.map_blips_help);
    $("#section-settings-markers label[for='blips-enabled']").text(translations.hide_blips);
    $("#section-settings-markers .config-card:nth-child(3) .card-header h4").text(translations.sprite_height_offset);
    $("#section-settings-markers .config-card:nth-child(3) .card-content p").text(translations.sprite_height_offset_help);
    $("#section-settings-markers .config-card:nth-child(4) .card-header h4").text(translations.entrance_display_distance_label);
    $("#section-settings-markers .config-card:nth-child(4) .card-content p").text(translations.entrance_display_distance_hint);
    $("#save-markers-btn .btn-text").text(translations.save);

    $("#section-settings-stash .config-card:first-child .card-header h4").text(translations.stash_enable_title || translations.stash_enabled);
    $("#section-settings-stash label[for='stash-enabled']").text(translations.stash_enabled);
    $("#section-settings-stash .config-card:first-child .form-hint").text(translations.stash_enabled_help);
    $("#section-settings-stash .config-card:nth-child(2) .card-header h4").text(translations.stash_system_label);
    $("#section-settings-stash .config-card:nth-child(2) label[for='stash-system']").text(translations.stash_system_label);
    $("#section-settings-stash .config-card:nth-child(2) .form-hint").text(translations.stash_system_hint);
    $("#stash-system option[value='auto']").text(translations.stash_system_auto);
    $("#stash-custom-coords-label").text(translations.stash_custom_coords_enabled_label);
    $("#stash-custom-coords-help").text(translations.stash_custom_coords_enabled_help);
    $("#stash-global-coords-title").text(translations.stash_global_coords_title);
    $("#stash-global-coords-help").text(translations.stash_global_coords_help);
    $("#save-stash-btn .btn-text").text(translations.save_stash_settings || translations.save);
    $("#wardrobe-custom-coords-label").text(translations.wardrobe_custom_coords_enabled_label);
    $("#wardrobe-custom-coords-help").text(translations.wardrobe_custom_coords_enabled_help);
    $("#wardrobe-global-coords-title").text(translations.wardrobe_global_coords_title);
    $("#wardrobe-global-coords-help").text(translations.wardrobe_global_coords_help);

    $("#section-settings-beta .card-header h4").text(translations.beta_settings_title);
    $("#section-settings-beta .card-content > .muted-text").text(translations.beta_settings_description);
    $("#section-settings-beta label[for='custom-shells-enabled']").text(translations.enable_custom_shells);
    $("#section-settings-beta .form-group .form-hint").text(translations.enable_custom_shells_hint);
    $("#save-beta-btn .btn-text").text(translations.save_beta_settings);

    $("#section-settings-burglary .card-header h4").text(translations.burglary_enabled_title);
    $("#section-settings-burglary label[for='burglary-enabled']").text(translations.burglary_enabled);
    $("#section-settings-burglary .form-group .form-hint").text(translations.burglary_enabled_help);
    $("#save-burglary-btn .btn-text").text(translations.save_burglary_settings);
    $("#section-coordinates .coords-cards .config-card:first h4").html((translations.house_location) + " <span style=\"color: #ff4444;\">*</span>");
    $("#section-coordinates .coords-cards .config-card:last h4").text(translations.garage_location);
    $("#entrance-location-title").text(translations.entrance_location);
    $("#garage-location-title").text(translations.garage_location_manage);
    $("#show-more-options-text").text(translations.show_more_options);
    $("#close-more-options-text").text(translations.close_more_options);
    $("#reset-changes-text").text(getTranslation('reset_changes'));
    $("#save-changes-text").text(getTranslation('save_changes'));
    $(".coords-btn .btn-text").not("#reset-house-market-text").text(translations.get_current_position);
    $("#edit-owner-modal-title").text(translations.edit_owner);
    $("#edit-owner-label").text(translations.new_owner_identifier);
    $("#new-owner-identifier").attr('placeholder', translations.enter_identifier);
    $("#edit-owner-cancel-text").text(translations.cancel);
    $("#edit-owner-confirm-text").text(translations.confirm);

    $("#edit-price-modal-title").text(translations.edit_price);
    $("#edit-price-label").text(translations.new_price);
    $("#new-price").attr('placeholder', translations.enter_price);
    $("#edit-price-cancel-text").text(translations.cancel);
    $("#edit-price-confirm-text").text(translations.confirm);

    $("#real-estate-market-title").text(translations.real_estate_market);
    $("#reset-house-market-text").text(translations.reset_house_market);
    $("#reset-market-confirm-title").text(translations.confirm);
    $("#reset-market-confirm-btn").text(translations.confirm);
    $("#reset-market-cancel-btn").text(translations.cancel);

    $("#confirm h2").text(translations.confirm_deletion);
    $("#confirm p").text(translations.cannot_be_undone);
    $("#confirm .button:first").text(translations.yes_delete);
    $("#confirm .button:last").text(translations.cancel);
    $("#delete-btn").attr('title', translations.delete_house);


    translateGarageInterface();

    if (typeof window.nhApplyGarageEnabledState === 'function') {
        window.nhApplyGarageEnabledState(window.nhGaragesEnabled === true, { syncToggle: false });
    }
}






window.renderShells = function renderShells() {
    const container = $('#shells-grid');
    if (!container.length) return;

    container.empty();

    if (!currentShells || currentShells.length === 0) {
        const empty = $('<p/>', {
            text: translations.no_custom_shells,
            class: 'muted-text'
        });
        container.append(empty);
        return;
    }

    currentShells.forEach(shell => {
        const interiorId = shell.interior;
        const shellId = shell.id;

        const card = $('<div/>', {
            class: 'shell-card'
        });

        const title = $('<div/>', {
            class: 'shell-card-title',
            text: shell.name || ('Shell #' + shell.id)
        });

        let displayType = 'MLO';
        if (shell.model && shell.model.trim()) {
            displayType = 'OBJECT';
        } else if (shell.ipl && shell.ipl.trim()) {
            displayType = 'IPL';
        }

        const subtitle = $('<div/>', {
            class: 'shell-card-subtitle',
            text: `Type: ${displayType} | ID: ${interiorId}`
        });

        const actions = $('<div/>', {
            class: 'shell-card-actions'
        });

        const hasBaseCoords = shell.baseCoords && shell.baseCoords.x && shell.baseCoords.y && shell.baseCoords.z;
        const hasEntry = shell.entry && shell.entry.x && shell.entry.y && shell.entry.z;

        const teleportBtn = $('<button/>', {
            class: 'shell-card-action-btn teleport',
            type: 'button',
            html: '<span>Teleport</span>',
            click: (e) => {
                e.stopPropagation();
                let teleportCoords;
                if (hasBaseCoords) {
                    teleportCoords = {
                        x: shell.baseCoords.x,
                        y: shell.baseCoords.y,
                        z: shell.baseCoords.z
                    };
                } else if (hasEntry) {
                    teleportCoords = {
                        x: shell.entry.x,
                        y: shell.entry.y,
                        z: shell.entry.z
                    };
                } else {
                    teleportCoords = {
                        x: 0.0,
                        y: 0.0,
                        z: 2001.0
                    };
                }
                $.post('https://next_housing/teleportToShell', JSON.stringify({
                    interiorId: interiorId,
                    x: teleportCoords.x,
                    y: teleportCoords.y,
                    z: teleportCoords.z
                }));
            }
        });
        actions.append(teleportBtn);

        const editBtn = $('<button/>', {
            class: 'shell-card-action-btn',
            type: 'button',
            html: '<span>Edit</span>',
            click: (e) => {
                e.stopPropagation();
                selectedShellInterior = interiorId;
                $('.shell-card').removeClass('selected');
                card.addClass('selected');
                openShellEdit(shell);
            }
        });

        const deleteBtn = $('<button/>', {
            class: 'shell-card-action-btn delete',
            type: 'button',
            html: '<span>Delete</span>',
            click: (e) => {
                e.stopPropagation();
                if (confirm(translations.delete_shell_confirm)) {
                    $.post('https://next_housing/deleteShell', JSON.stringify({
                        shellId: shell.id
                    }), function (resp) {
                        try {
                            const data = typeof resp === 'string' ? JSON.parse(resp) : resp;
                            if (data && data.success) {
                                if (data.shells) {
                                    currentShells = data.shells || [];
                                    renderShells();
                                }
                            } else {
                                alert(data && data.message ? data.message : (translations.delete_shell_error));
                            }
                        } catch (err) {
                            alert(translations.delete_shell_error);
                        }
                    });
                }
            }
        });

        actions.append(editBtn);
        actions.append(deleteBtn);

        card.append(title);
        card.append(subtitle);
        card.append(actions);
        container.append(card);
    });

    const selects = ['#interior-select', '#interior-change'];
    selects.forEach(selector => {
        const sel = $(selector);
        if (!sel.length) return;

        sel.find('optgroup[data-shells="1"]').remove();

        if (!currentShells || currentShells.length === 0) return;

        const group = $('<optgroup/>', {
            label: translations.custom_shells_group,
            'data-shells': '1'
        });

        currentShells.forEach(shell => {
            const interiorId = shell.interior;
            if (!interiorId) return;
            const opt = $('<option/>', {
                value: interiorId,
                text: shell.name || (`Shell #${shell.id}`)
            });
            group.append(opt);
        });

        sel.append(group);
    });
}






function getInteriorImageUrl(interiorVal) {
    const interior = String(interiorVal);
    const interiorNum = parseInt(interiorVal, 10);

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
        return `./images/${apartmentName}.jpg`;
    }
    else if (interiorNum >= 11 && interiorNum <= 46) {
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
        return `./images/${officeStyle}.jpg`;
    }
    else {
        return `./images/${interior}.jpg`;
    }
}

function loadPreviewImage(imageurl) {
    $("#preview-container").show();
    const imgElement = $('#preview-image')[0];
    if (imgElement) {
        imgElement.src = '';
        setTimeout(function () {
            imgElement.src = imageurl;
        }, 0);
    } else {
        $('#preview-image').attr('src', imageurl);
    }
    $('#preview-image').show();
}

function getInteriorName(interiorId) {
    const interiorNames = {
        "1": "Studio 1", "2": "Basic Apartment 1", "3": "Studio 2", "4": "Basic Apartment 2", "5": "Basic Apartment 3",
        "6": "House 1", "7": "House 2",
        "11": "Executive Rich (Maze Bank Tower)", "12": "Executive Cool (Maze Bank Tower)", "13": "Executive Contrast (Maze Bank Tower)",
        "14": "Old Spice Warm (Maze Bank Tower)", "15": "Old Spice Classical (Maze Bank Tower)", "16": "Old Spice Vintage (Maze Bank Tower)",
        "17": "Power Broker Ice (Maze Bank Tower)", "18": "Power Broker Conservative (Maze Bank Tower)", "19": "Power Broker Polished (Maze Bank Tower)",
        "20": "Executive Rich (Arcaduis)", "21": "Executive Cool (Arcaduis)", "22": "Executive Contrast (Arcaduis)",
        "23": "Old Spice Warm (Arcaduis)", "24": "Old Spice Classical (Arcaduis)", "25": "Old Spice Vintage (Arcaduis)",
        "26": "Power Broker Ice (Arcaduis)", "27": "Power Broker Conservative (Arcaduis)", "28": "Power Broker Polished (Arcaduis)",
        "29": "Executive Rich (Lom Bank)", "30": "Executive Cool (Lom Bank)", "31": "Executive Contrast (Lom Bank)",
        "32": "Old Spice Warm (Lom Bank)", "33": "Old Spice Classical (Lom Bank)", "34": "Old Spice Vintage (Lom Bank)",
        "35": "Power Broker Ice (Lom Bank)", "36": "Power Broker Conservative (Lom Bank)", "37": "Power Broker Polished (Lom Bank)",
        "38": "Executive Rich (Maze Bank West)", "39": "Executive Cool (Maze Bank West)", "40": "Executive Contrast (Maze Bank West)",
        "41": "Old Spice Warm (Maze Bank West)", "42": "Old Spice Classical (Maze Bank West)", "43": "Old Spice Vintage (Maze Bank West)",
        "44": "Power Broker Ice (Maze Bank West)", "45": "Power Broker Conservative (Maze Bank West)", "46": "Power Broker Polished (Maze Bank West)",
        "47": "Modern 1 Apartment (View 1)", "48": "Modern 2 Apartment (View 2)", "49": "Modern 3 Apartment (View 3)",
        "50": "Mody 1 Apartment (View 1)", "51": "Mody 2 Apartment (View 2)", "52": "Mody 3 Apartment (View 3)",
        "53": "Vibrant 1 Apartment (View 1)", "54": "Vibrant 2 Apartment (View 2)", "55": "Vibrant 3 Apartment (View 3)",
        "56": "Sharp 1 Apartment (View 1)", "57": "Sharp 2 Apartment (View 2)", "58": "Sharp 3 Apartment (View 3)",
        "59": "Monochrome 1 Apartment (View 1)", "60": "Monochrome 2 Apartment (View 2)", "61": "Monochrome 3 Apartment (View 3)",
        "62": "Seductive 1 Apartment (View 1)", "63": "Seductive 2 Apartment (View 2)", "64": "Seductive 3 Apartment (View 3)",
        "65": "Regal 1 Apartment (View 1)", "66": "Regal 2 Apartment (View 2)", "67": "Regal 3 Apartment (View 3)",
        "68": "Aqua 1 Apartment (View 1)", "69": "Aqua 2 Apartment (View 2)", "70": "Aqua 3 Apartment (View 3)"
    };
    return interiorNames[interiorId] || `Interior ${interiorId}`;
}

function getInteriorPreviewCoords(interiorId) {
    const previewCoords = {
        "1": { x: 151.621979, y: -1005.362610, z: -99.014648, h: 317.480316 },
        "3": { x: 344.149445, y: -998.030762, z: -99.199951, h: 124.724411 },
        "6": { x: 337.397797, y: 433.292297, z: 149.368530, h: 130.393707 },
        "7": { x: 372.632965, y: 414.764832, z: 145.695190, h: 187.086609 },
        "2": { x: -263.630768, y: -954.039551, z: 75.819092, h: 323.149597 },
        "4": { x: -18.975822, y: -589.200012, z: 79.424927, h: 345.826782 },
        "5": { x: -32.887909, y: -581.512085, z: 88.709106, h: 59.527554 },
        "47": { x: -786.883545, y: 326.399994, z: 217.037354, h: 351.496063 },
        "48": { x: -786.923096, y: 326.597809, z: 187.297485, h: 345.826782 },
        "49": { x: -773.789001, y: 329.789001, z: 196.076172, h: 161.574799 },
        "50": { x: -785.749451, y: 326.624176, z: 217.037354, h: 340.157471 },
        "51": { x: -785.657166, y: 326.043945, z: 187.297485, h: 357.165344 },
        "52": { x: -775.147278, y: 331.463745, z: 196.076172, h: 172.913391 },
        "53": { x: -787.463745, y: 323.301086, z: 217.037354, h: 348.661407 },
        "54": { x: -787.529663, y: 323.063751, z: 187.297485, h: 345.826782 },
        "55": { x: -773.367004, y: 333.982422, z: 196.076172, h: 161.574799 },
        "56": { x: -787.951660, y: 323.103302, z: 217.037354, h: 337.322845 },
        "57": { x: -787.397827, y: 324.131866, z: 187.297485, h: 348.661407 },
        "58": { x: -772.997803, y: 334.668121, z: 196.076172, h: 161.574799 },
        "59": { x: -787.503296, y: 324.329681, z: 217.037354, h: 345.826782 },
        "60": { x: -787.437378, y: 324.989014, z: 187.297485, h: 357.165344 },
        "61": { x: -773.485718, y: 332.452759, z: 196.076172, h: 164.409454 },
        "62": { x: -787.239563, y: 323.525269, z: 217.037354, h: 345.826782 },
        "63": { x: -787.687927, y: 323.380219, z: 187.297485, h: 345.826782 },
        "64": { x: -772.813171, y: 334.272522, z: 196.076172, h: 150.236221 },
        "65": { x: -787.780212, y: 321.811005, z: 217.037354, h: 342.992126 },
        "66": { x: -787.925293, y: 323.525269, z: 187.297485, h: 334.488190 },
        "67": { x: -773.525269, y: 334.589020, z: 196.076172, h: 164.409454 },
        "68": { x: -788.281311, y: 323.393402, z: 217.037354, h: 340.157471 },
        "69": { x: -787.661560, y: 322.918701, z: 187.297485, h: 342.992126 },
        "70": { x: -773.221985, y: 335.076935, z: 196.076172, h: 158.740158 }
    };
    return previewCoords[String(interiorId)];
}






function animateMoreOptionsSection(shouldOpen, options) {
    const opts = options || {};
    const duration = typeof opts.duration === "number" ? opts.duration : 260;
    const container = $("#coords-sections-container");
    const buttonContainer = $("#show-more-options-container");
    const formView = $("#manage-form-view");

    container.stop(true, true);
    buttonContainer.stop(true, true);

    if (shouldOpen) {
        let targetHeight = 0;
        if (container[0]) {
            container.css({ display: "block", visibility: "hidden", height: "auto", overflow: "hidden" });
            targetHeight = container[0].scrollHeight;
        }
        container
            .css({ display: "block", visibility: "", overflow: "hidden", height: 0, opacity: 0 })
            .animate({ height: targetHeight, opacity: 1 }, duration, "swing", function () {
                $(this).css({ height: "", overflow: "", opacity: "" });
                if (opts.scrollToBottom && formView.length) {
                    formView.stop(true).animate({ scrollTop: formView[0].scrollHeight }, 280);
                }
            });
        buttonContainer.fadeOut(160);
        return;
    }

    if (!container.is(":visible")) {
        buttonContainer.fadeIn(160);
        return;
    }

    const currentHeight = container.outerHeight();
    container
        .css({ overflow: "hidden", height: currentHeight, opacity: 1 })
        .animate({ height: 0, opacity: 0 }, duration, "swing", function () {
            $(this).hide().css({ height: "", overflow: "", opacity: "" });
            buttonContainer.fadeIn(160);
        });
}

function ToggleMoreOptions() {
    const container = $("#coords-sections-container");
    const isVisible = container.is(":visible");
    animateMoreOptionsSection(!isVisible, { scrollToBottom: !isVisible });
}

function CloseMoreOptions() {
    animateMoreOptionsSection(false);
}

window.ToggleListMode = function () {
    listModeActive = !listModeActive;
    const listView = $('#houses-list-view');
    const formView = $('#manage-form-view');
    const listBtnText = $('#list-mode-btn-text');
    const loading = $('#manage-houses-loading');

    if (listModeActive) {
        listView.show();
        formView.hide();
        listBtnText.text(getTranslation('normal_mode'));
        loadAllHouses();
    } else {
        listView.hide();
        formView.show();
        listBtnText.text(getTranslation('list_mode'));
        loading.hide();
    }

    if (typeof translateInterface === 'function') {
        translateInterface();
    }
};

function renderManageHousesList() {
    const housesList = $('#manage-houses-list');
    const emptyState = $('#manage-houses-empty');
    const loading = $('#manage-houses-loading');
    const searchWrapper = $('.manage-houses-search');

    if (typeof allHousesData === 'undefined') {
        allHousesData = [];
    }

    if (typeof manageHousesLoadingInProgress !== 'undefined' && manageHousesLoadingInProgress === true) {
        loading.show();
        emptyState.hide();
        housesList.hide();
        return;
    }

    loading.hide();

    housesList.empty();
    searchWrapper.toggle(allHousesData.length > 0);

    if (!allHousesData || allHousesData.length === 0) {
        updateManageHousesEmptyState(false);
        emptyState.show();
        housesList.hide();
        return;
    }

    const filteredHouses = getManageHouseSearchResults();
    if (!filteredHouses.length) {
        updateManageHousesEmptyState(String(manageHouseSearchQuery || '').trim().length > 0);
        emptyState.show();
        housesList.hide();
        return;
    }

    emptyState.hide();
    housesList.show();

    filteredHouses.forEach(function (house) {
        const houseItem = createManageHouseItem(house);
        housesList.append(houseItem);
    });
}

function createManageHouseItem(house) {
    if (typeof window.normalizeManageHouseRecord === 'function') {
        house = window.normalizeManageHouseRecord(house);
    }

    const t = {
        houseNumber: getTranslationWithFallbacks(['job_house_number', 'house_number'], 'Property #'),
        type: getTranslationWithFallbacks(['job_house_type', 'house_type'], 'Type'),
        owner: getTranslationWithFallbacks(['owner', 'job_modal_owner'], 'Owner'),
        price: getTranslationWithFallbacks(['price', 'job_house_price'], 'Price'),
        status: getTranslationWithFallbacks(['status', 'job_modal_status'], 'Status'),
        teleport: getTranslation('teleport'),
        edit: getTranslation('edit'),
        unknownOwner: getTranslationWithFallbacks(['unknown_owner', 'job_house_no_owner'], 'Unknown owner'),
        available: getTranslationWithFallbacks(['available', 'job_house_available'], 'Available'),
        sold: getTranslationWithFallbacks(['job_house_sold', 'sold'], 'Sold'),
        notDefined: getTranslationWithFallbacks(['not_defined', 'job_house_not_defined'], 'Not defined'),
        locked: getTranslationWithFallbacks(['locked', 'job_modal_locked'], 'Locked'),
        unlocked: getTranslation('unlocked')
    };

    const hasOwner = !!(house.oidentifier && String(house.oidentifier).trim() !== '');
    const statusClass = hasOwner ? 'sold' : 'available';
    const statusText = hasOwner ? t.sold : t.available;

    const houseName = house.name || (t.houseNumber + house.id);
    const houseType = (typeof getHouseType === 'function')
        ? getHouseType(house.interior)
        : getHouseTypeFromInterior(house.interior);
    const ownerText = house.oname || (house.oidentifier ? t.unknownOwner : t.available);
    const priceText = house.price ? formatPrice(house.price) : t.notDefined;
    const lockText = house.locked ? t.locked : t.unlocked;

    const item = $('<div>')
        .addClass('house-card')
        .addClass(statusClass)
        .attr('role', 'button')
        .attr('tabindex', '0');

    const imageSource = (typeof getHouseCardImageSource === 'function')
        ? getHouseCardImageSource({
            images: Array.isArray(house.images) ? house.images : [],
            interior: house.interior
        })
        : null;
    const headerImage = (typeof createHeaderImageContainer === 'function')
        ? createHeaderImageContainer(
            imageSource,
            (t.houseNumber + house.id),
            'house-header-image',
            'house-image-placeholder',
            'ph:house-line'
        )
        : $('<div>').addClass('house-header-image').append(
            $('<div>').addClass('house-image-placeholder').append(
                $('<i>').addClass('ph ph-house-line').attr('aria-hidden', 'true')
            )
        );

    const titleContainer = $('<div>').addClass('house-title-container');
    const headerTop = $('<div>').addClass('house-image-overlay-top');
    const statusBadge = $('<div>').addClass('house-status').text(statusText);

    if (house.hcoords && house.hcoords.x && house.hcoords.y && typeof viewHouseOnMap === 'function') {
        const gpsIcon = $('<button>')
            .addClass('gps-icon-btn')
            .attr('type', 'button')
            .attr('title', getTranslationWithFallbacks(['job_house_view_on_map', 'pap_show_on_map'], 'View on map'))
            .html('<i class="ph ph-map-pin"></i>')
            .on('click', function (e) {
                e.stopPropagation();
                viewHouseOnMap(house.hcoords, house.id);
            });
        titleContainer.append(gpsIcon);
    }

    titleContainer.append($('<h4>').addClass('house-id').text(houseName));

    const info = $('<div>').addClass('house-info');
    const infoGrid = $('<div>').addClass('house-info-grid');
    const addInfoItem = function (label, value) {
        if (typeof createInfoItem === 'function') {
            return createInfoItem(label, value);
        }
        return $('<div>').addClass('house-info-item')
            .append($('<span>').addClass('house-info-label').text(label))
            .append($('<span>').addClass('house-info-value').text(value));
    };
    infoGrid.append(addInfoItem(t.type, houseType));
    infoGrid.append(addInfoItem(t.owner, ownerText));
    infoGrid.append(addInfoItem(t.price, priceText));
    infoGrid.append(addInfoItem(t.status, lockText));
    info.append(infoGrid);

    const imageOverlay = $('<div>').addClass('house-image-overlay');
    headerTop.append(titleContainer);
    headerTop.append(statusBadge);
    imageOverlay.append(headerTop);
    imageOverlay.append(info);
    headerImage.append(imageOverlay);
    item.append(headerImage);

    const actions = $('<div>').addClass('house-actions');
    const createActionButton = function (text, iconClass, onClick) {
        if (typeof createHouseActionButton === 'function') {
            return createHouseActionButton(text, iconClass, '', onClick);
        }
        return $('<button>').addClass('action-btn')
            .append($('<i>').addClass(iconClass).attr('aria-hidden', 'true'))
            .append($('<span>').text(String(text || '').trim()))
            .on('click', onClick);
    };
    const editBtn = createActionButton(t.edit, 'ph ph-pencil-simple', function (e) {
        e.stopPropagation();
        editHouseFromList(house);
    });
    const teleportBtn = createActionButton(t.teleport, 'ph ph-map-pin', function (e) {
        e.stopPropagation();
        teleportToHouse(house);
    });
    actions.append(editBtn);
    actions.append(teleportBtn);
    item.append(actions);

    item.on('click', function (e) {
        if ($(e.target).closest('button').length) {
            return;
        }
        showManageHouseInfo(house);
    });

    item.on('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            showManageHouseInfo(house);
        }
    });

    return item;
}

function getHouseTypeFromInterior(interior) {
    const interiorNum = parseInt(interior) || 0;

    if (interiorNum === 1 || interiorNum === 3) {
        return getTranslation('job_house_type_studio');
    } else if (interiorNum === 6 || interiorNum === 7) {
        return getTranslation('job_house_type_house');
    } else if ((interiorNum >= 2 && interiorNum <= 5) || (interiorNum >= 47 && interiorNum <= 70)) {
        return getTranslation('job_house_type_apartment');
    } else if (interiorNum >= 11 && interiorNum <= 46) {
        return getTranslation('job_house_type_office');
    } else {
        return getTranslation('job_house_type_unknown');
    }
}

function editHouseFromList(house) {
    if (typeof window.normalizeManageHouseRecord === 'function') {
        house = window.normalizeManageHouseRecord(house);
    }

    listModeActive = false;
    const listView = $('#houses-list-view');
    const formView = $('#manage-form-view');
    const listBtnText = $('#list-mode-btn-text');

    listView.hide();
    formView.show();
    listBtnText.text(getTranslation('list_mode'));

    showManageInfoState();

    $("#houseid").text(house.id);
    $("#bname").text(house.bname || getTranslation('no_data'));
    const ownerName = house.oname;
    const ownerIdentifier = house.oidentifier;
    const ownerText = (ownerName && ownerName.trim() !== '') ? ownerName : ((ownerIdentifier && ownerIdentifier.trim() !== '') ? getTranslation('no_data') : getTranslation('vacant'));
    $("#oname").text(ownerText);
    $("#price_display").text(house.price ? formatPrice(house.price) : 'â€”');
    $("#lock").text(house.locked ? getTranslation('closed') : getTranslation('open'));
    if (typeof window.updateManageLockIcon === 'function') {
        window.updateManageLockIcon(house.locked === true);
    }

    window.currentInterior = house.interior || 1;
    window.initialInterior = house.interior || 1;
    $('#interior-change').val(window.currentInterior);
    const interiorName = getInteriorName(window.currentInterior);
    $("#interiornow").text(interiorName);

    if (typeof currentShells !== 'undefined' && currentShells.length > 0 && typeof window.renderShells === 'function') {
        window.renderShells();
    }

    window.initialValues = {
        interior: window.currentInterior,
        entranceX: house.hcoords && house.hcoords.x ? parseFloat(house.hcoords.x).toFixed(2) : '',
        entranceY: house.hcoords && house.hcoords.y ? parseFloat(house.hcoords.y).toFixed(2) : '',
        entranceZ: house.hcoords && house.hcoords.z ? parseFloat(house.hcoords.z).toFixed(2) : '',
        garageX: house.gcoords && house.gcoords.x ? parseFloat(house.gcoords.x).toFixed(2) : '',
        garageY: house.gcoords && house.gcoords.y ? parseFloat(house.gcoords.y).toFixed(2) : '',
        garageZ: house.gcoords && house.gcoords.z ? parseFloat(house.gcoords.z).toFixed(2) : '',
        garageH: house.gcoords && house.gcoords.h ? parseFloat(house.gcoords.h).toFixed(2) : ''
    };

    if (house.hcoords && house.hcoords.x && house.hcoords.y && house.hcoords.z) {
        $("#entrancex").val(parseFloat(house.hcoords.x).toFixed(2));
        $("#entrancey").val(parseFloat(house.hcoords.y).toFixed(2));
        $("#entrancez").val(parseFloat(house.hcoords.z).toFixed(2));
    } else {
        $("#entrancex").val('');
        $("#entrancey").val('');
        $("#entrancez").val('');
    }

    if (house.gcoords && house.gcoords.x && house.gcoords.y && house.gcoords.z) {
        $("#garagex-manage").val(parseFloat(house.gcoords.x).toFixed(2));
        $("#garagey-manage").val(parseFloat(house.gcoords.y).toFixed(2));
        $("#garagez-manage").val(parseFloat(house.gcoords.z).toFixed(2));
        $("#garageh-manage").val(house.gcoords.h ? parseFloat(house.gcoords.h).toFixed(2) : '');
    } else {
        $("#garagex-manage").val('');
        $("#garagey-manage").val('');
        $("#garagez-manage").val('');
        $("#garageh-manage").val('');
    }

    if (typeof window.nhApplyGarageEnabledState === 'function') {
        window.nhApplyGarageEnabledState(window.nhGaragesEnabled === true, { syncToggle: false });
    }

    $("#manage-action-row").show();
}

$(document)
    .off('input.manageHouseSearch', '#manage-house-search-input')
    .on('input.manageHouseSearch', '#manage-house-search-input', function () {
        manageHouseSearchQuery = $(this).val() || '';
        if (typeof listModeActive !== 'undefined' && listModeActive) {
            renderManageHousesList();
        }
    });

