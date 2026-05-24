let currentMenu = 'main';
let currentElements = [];
let currentVehicle = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openMenu') {
        currentVehicle = data.vehicle;
        currentElements = data.elements;
        showMainMenu(data.elements, data.vehicle);
    } else if (data.action === 'openSubMenu') {
        currentElements = data.elements;
        showSubMenu(data.elements, data.title);
    }
});

function showMainMenu(elements, vehicle) {
    const menu = document.getElementById('menu');
    const content = document.getElementById('menu-content');
    
    let html = '';
    
    if (vehicle) {
        html += `
            <div class="vehicle-info">
                <div class="vehicle-info-label">Vehicle:</div>
                <div class="vehicle-info-value">${vehicle.model}</div>
                <div class="vehicle-info-label">Class:</div>
                <div class="vehicle-info-value">${vehicle.class}</div>
            </div>
        `;
    }
    
    elements.forEach(element => {
        html += `
            <div class="menu-item" onclick="selectOption('${element.value}')">
                <div class="menu-item-label">${element.label}</div>
            </div>
        `;
    });
    
    content.innerHTML = html;
    menu.classList.remove('hidden');
    currentMenu = 'main';
}

function showSubMenu(elements, title) {
    const menu = document.getElementById('menu');
    const content = document.getElementById('menu-content');
    
    let html = `
        <button class="back-btn" onclick="showMainMenu(currentElements, currentVehicle)">← Back</button>
        <div class="sub-menu-title">${title}</div>
    `;
    
    elements.forEach(element => {
        let priceHtml = '';
        if (element.price) {
            priceHtml = `<div class="menu-item-price">$${element.price}</div>`;
        }
        
        html += `
            <div class="menu-item" onclick="selectSubOption('${element.value}')">
                <div class="menu-item-label">${element.label}</div>
                ${priceHtml}
            </div>
        `;
    });
    
    content.innerHTML = html;
    currentMenu = 'sub';
}

function selectOption(option) {
    fetch(`https://${GetParentResourceName()}/selectOption`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ option: option })
    });
}

function selectSubOption(option) {
    fetch(`https://${GetParentResourceName()}/selectOption`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ option: option })
    });
}

function closeMenu() {
    const menu = document.getElementById('menu');
    menu.classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function installMod(modType, modIndex) {
    fetch(`https://${GetParentResourceName()}/installMod`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ modType: modType, modIndex: modIndex })
    });
}
