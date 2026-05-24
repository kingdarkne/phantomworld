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
let garageVehicles = [];
let garageCurrentPage = 1;
let garageVehiclesPerPage = 6;
let garageSpawnCoords = null;
let garageHasOxFuel = false;
let garageHasQBFuel = false;






function translateGarageInterface() {
    if (!translations || Object.keys(translations).length === 0) return;

    $("#garage-subtitle").text(translations.my_garage);
    $("#garage-loading-text").text(translations.loading_vehicles);
    $("#garage-empty-title").text(translations.no_vehicles);
    $("#garage-empty-desc").text(translations.no_vehicles_message);
    $("#garage-prev-btn span").text(translations.previous_page);
    $("#garage-next-btn span").text(translations.next_page_garage);
}






window.OpenGarageUI = function (vehicles, spawnCoords, hasOxFuel, hasQBFuel) {
    garageVehicles = vehicles || [];
    garageSpawnCoords = spawnCoords;
    garageCurrentPage = 1;
    garageHasOxFuel = hasOxFuel || false;
    garageHasQBFuel = hasQBFuel || false;

    translateGarageInterface();

    $('#garage-container').css('display', 'flex');
    $('#nui-background').show();

    updateGarageVehicleCount();

    if (garageVehicles.length === 0) {
        $('#garage-loading').hide();
        $('#garage-empty').show();
        $('#garage-vehicles-list').hide();
        $('#garage-pagination').hide();
    } else {
        renderGarageVehicles();
    }
};

window.CloseGarageMenu = function () {
    $('#garage-container').hide();
    $('#nui-background').hide();
    $.post('http://next_housing/closeGarage', JSON.stringify({}));
};






function renderGarageVehicles() {
    $('#garage-loading').hide();
    $('#garage-empty').hide();

    const startIndex = (garageCurrentPage - 1) * garageVehiclesPerPage;
    const endIndex = Math.min(startIndex + garageVehiclesPerPage, garageVehicles.length);
    const pageVehicles = garageVehicles.slice(startIndex, endIndex);

    const list = $('#garage-vehicles-list');
    list.empty();

    if (pageVehicles.length > 0) {
        try {
            pageVehicles.forEach((vehicle, index) => {
                try {
                    const vehicleCard = createGarageVehicleCard(vehicle, startIndex + index);
                    list.append(vehicleCard);
                } catch (error) {
                }
            });
            list.css('display', 'grid');
        } catch (error) {
            $('#garage-empty').show();
        }
    } else {
        list.hide();
    }


    updateGaragePagination();
}






function createGarageVehicleCard(vehicle, index) {
    let vehicleModel = vehicle.vehicle || vehicle.model || 'Unknown';
    if (typeof vehicleModel !== 'string') {
        vehicleModel = String(vehicleModel);
    }

    const vehicleName = vehicle.vehicleLabel || GetGarageVehicleDisplayName(vehicleModel) || vehicleModel;
    const plate = vehicle.plate || 'N/A';
    const engine = vehicle.engine !== undefined
        ? Math.floor(vehicle.engine / 10)
        : (typeof vehicle.stats?.engine === 'number' ? Math.floor(vehicle.stats.engine / 10) : 100);
    const body = vehicle.body !== undefined
        ? Math.floor(vehicle.body / 10)
        : (typeof vehicle.stats?.body === 'number' ? Math.floor(vehicle.stats.body / 10) : 100);

    const fuelValue = vehicle.fuel !== undefined && vehicle.fuel !== null
        ? vehicle.fuel
        : (vehicle.vehicleProps && vehicle.vehicleProps.fuel !== undefined && vehicle.vehicleProps.fuel !== null
            ? vehicle.vehicleProps.fuel
            : null);

    let fuelHtml = '';
    if (garageHasOxFuel || garageHasQBFuel) {
        const fuelPercent = fuelValue !== null && fuelValue !== undefined
            ? Math.max(0, Math.min(100, Math.floor(fuelValue)))
            : 0;
        fuelHtml = `
            <div class="garage-stat-item full-width">
                <span class="garage-stat-label">${translations.fuel}</span>
                <div class="garage-stat-bar-container">
                    <div class="garage-stat-bar">
                        <div class="garage-stat-bar-fill" style="width: ${fuelPercent}%"></div>
                    </div>
                    <span class="garage-stat-percent">${fuelPercent}%</span>
                </div>
            </div>
        `;
    }

    const useLabel = translations.use_vehicle;

    const card = $(`
        <div class="garage-vehicle-card" data-index="${index}">
            <div class="garage-card-header">
                <div class="garage-card-title-container">
                    <div class="garage-card-icon"><i class="ph ph-car-profile"></i></div>
                    <h4 class="garage-card-title">${vehicleName}</h4>
                </div>
                <span class="garage-plate-badge">${plate}</span>
            </div>
            <div class="garage-card-info">
                <div class="garage-stats-grid">
                    <div class="garage-stat-item">
                        <span class="garage-stat-label">${translations.body}</span>
                        <div class="garage-stat-bar-container">
                            <div class="garage-stat-bar">
                                <div class="garage-stat-bar-fill" style="width: ${body}%"></div>
                            </div>
                            <span class="garage-stat-percent">${body}%</span>
                        </div>
                    </div>
                    <div class="garage-stat-item">
                        <span class="garage-stat-label">${translations.engine}</span>
                        <div class="garage-stat-bar-container">
                            <div class="garage-stat-bar">
                                <div class="garage-stat-bar-fill" style="width: ${engine}%"></div>
                            </div>
                            <span class="garage-stat-percent">${engine}%</span>
                        </div>
                    </div>
                    ${fuelHtml}
                </div>
            </div>
            <div class="garage-card-actions">
                <button class="garage-spawn-btn" onclick="SpawnVehicleFromGarage(${index})">
                    <i class="ph ph-key"></i>
                    <span>${useLabel}</span>
                </button>
            </div>
        </div>
    `);

    return card;
}

function GetGarageVehicleDisplayName(model) {
    return model;
}






function updateGarageVehicleCount() {
    const count = garageVehicles.length;
    const label = count <= 1 ? (translations.vehicle_singular) : (translations.vehicle_plural);
    $('#garage-vehicle-count').text(`${count} ${label}`);
}






function updateGaragePagination() {
    const totalPages = Math.ceil(garageVehicles.length / garageVehiclesPerPage);
    const pageText = translations.page;
    $('#garage-page-info').text(`${pageText} ${garageCurrentPage} / ${totalPages || 1}`);

    $('#garage-prev-btn').prop('disabled', garageCurrentPage <= 1);
    $('#garage-next-btn').prop('disabled', garageCurrentPage >= totalPages);

    if (garageVehicles.length > 0) {
        $('#garage-pagination').css('display', 'flex');
    } else {
        $('#garage-pagination').hide();
    }
}

window.GaragePreviousPage = function () {
    if (garageCurrentPage > 1) {
        garageCurrentPage--;
        renderGarageVehicles();
    }
};

window.GarageNextPage = function () {
    const totalPages = Math.ceil(garageVehicles.length / garageVehiclesPerPage);
    if (garageCurrentPage < totalPages) {
        garageCurrentPage++;
        renderGarageVehicles();
    }
};






window.SpawnVehicleFromGarage = function (globalIndex) {
    const vehicle = garageVehicles[globalIndex];

    if (!vehicle) return;

    $.post('http://next_housing/takeOutVehicle', JSON.stringify({
        vehicle: vehicle.vehicle || vehicle.model,
        plate: vehicle.plate,
        vehicleProps: vehicle.vehicleProps || vehicle.vehicle,
        stats: vehicle.stats || {
            engine: typeof vehicle.engine === 'number' ? vehicle.engine : 1000,
            body: typeof vehicle.body === 'number' ? vehicle.body : 1000
        },
        x3: garageSpawnCoords.x,
        y3: garageSpawnCoords.y,
        z3: garageSpawnCoords.z,
        h3: garageSpawnCoords.h || 0
    }));

    CloseGarageMenu();
};






window.addEventListener('message', function (event) {
    if (event.data.type === "openGarage") {
        if (event.data.translations) {
            window.translations = event.data.translations;
            window.currentLocale = event.data.locale || 'en';
            translations = window.translations;
            currentLocale = window.currentLocale;
        }
        OpenGarageUI(event.data.vehicles, event.data.spawnCoords, event.data.hasOxFuel, event.data.hasQBFuel);
    }
});

$(document).on('keydown.garageEscape', function (e) {
    if (e.key === 'Escape') {
        if ($('#garage-container').is(':visible')) {
            CloseGarageMenu();
        }
    }
});

