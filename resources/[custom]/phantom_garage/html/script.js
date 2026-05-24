// Phantom Garage NUI

let garageData = null;
let selectedVehicle = null;

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openGarage') {
        openGarage(data);
    }

    if (data.action === 'closeGarage') {
        closeGarage();
    }
});

function openGarage(data) {
    garageData = data;
    selectedVehicle = null;

    document.getElementById('garageName').textContent = data.garageName || 'GARAGE';
    document.getElementById('garageType').textContent = data.garageType || '10-Car Garage';
    document.getElementById('vehicleCount').textContent = data.vehicles ? data.vehicles.length : 0;
    document.getElementById('maxSlots').textContent = data.slots || 10;

    renderVehicleGrid(data.vehicles, data.slots);
    document.getElementById('garageUI').classList.remove('hidden');
}

function closeGarage() {
    document.getElementById('garageUI').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeGarage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function renderVehicleGrid(vehicles, slots) {
    const grid = document.getElementById('vehicleGrid');
    const emptyMsg = document.getElementById('emptyMessage');
    grid.innerHTML = '';

    const vehicleCount = vehicles ? vehicles.length : 0;

    if (vehicleCount === 0) {
        emptyMsg.classList.remove('hidden');
    } else {
        emptyMsg.classList.add('hidden');

        // Render stored vehicles
        for (let i = 0; i < vehicleCount; i++) {
            const v = vehicles[i];
            const card = createVehicleCard(v, i + 1, false);
            grid.appendChild(card);
        }
    }

    // Render empty slots
    for (let i = vehicleCount; i < slots; i++) {
        const card = createEmptyCard(i + 1);
        grid.appendChild(card);
    }
}

function createVehicleCard(vehicle, slot, isEmpty) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.dataset.index = slot - 1;

    // Car emoji based on model (simplified)
    const carEmojis = {
        'adder': '🏎️', 'zentorno': '🏎️', 't20': '🏎️', 'osiris': '🏎️', 'turismor': '🏎️',
        'elegy': '🚙', 'buffalo': '🚙', 'fusilade': '🚙', 'penumbra': '🚙',
        'dominator': '🚗', 'gauntlet': '🚗', 'sabregt': '🚗', 'vigero': '🚗',
        'bati': '🏍️', 'akuma': '🏍️', 'double': '🏍️', 'hexer': '🏍️',
        'default': '🚗'
    };

    const emoji = carEmojis[vehicle.model] || carEmojis['default'];

    card.innerHTML = `
        <div class="car-icon">${emoji}</div>
        <div class="car-name">${vehicle.model.toUpperCase()}</div>
        <div class="car-plate">${vehicle.plate || 'NO PLATE'}</div>
    `;

    card.addEventListener('click', () => selectVehicle(vehicle, slot - 1, card));
    return card;
}

function createEmptyCard(slot) {
    const card = document.createElement('div');
    card.className = 'vehicle-card empty';
    card.innerHTML = `
        <div class="car-icon">➕</div>
        <div class="empty-label">EMPTY SLOT ${slot}</div>
    `;
    return card;
}

function selectVehicle(vehicle, index, cardElement) {
    // Remove active from all cards
    document.querySelectorAll('.vehicle-card').forEach(c => c.classList.remove('active'));
    cardElement.classList.add('active');

    selectedVehicle = { ...vehicle, index: index };

    // Show detail panel
    const detail = document.getElementById('vehicleDetail');
    detail.classList.remove('hidden');

    // Update details
    document.getElementById('detailName').textContent = vehicle.model.toUpperCase();
    document.getElementById('detailClass').textContent = 'Stored Vehicle';

    // Animate bars with random stats (would come from server in real implementation)
    setTimeout(() => {
        document.getElementById('speedBar').style.width = (Math.random() * 40 + 50) + '%';
        document.getElementById('accelBar').style.width = (Math.random() * 40 + 50) + '%';
        document.getElementById('brakeBar').style.width = (Math.random() * 40 + 50) + '%';
        document.getElementById('handlingBar').style.width = (Math.random() * 40 + 50) + '%';
    }, 100);
}

// Close button
document.getElementById('closeGarage').addEventListener('click', closeGarage);

// Action buttons
document.getElementById('btnDrive').addEventListener('click', () => {
    if (!selectedVehicle) return;
    fetch(`https://${GetParentResourceName()}/driveVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ index: selectedVehicle.index })
    });
    closeGarage();
});

document.getElementById('btnSell').addEventListener('click', () => {
    if (!selectedVehicle) return;
    fetch(`https://${GetParentResourceName()}/sellVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ index: selectedVehicle.index })
    });
});

document.getElementById('btnInsurance').addEventListener('click', () => {
    lib.notify({ title: 'Insurance', description: 'Vehicle is insured', type: 'info' });
});

// Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeGarage();
    }
});
