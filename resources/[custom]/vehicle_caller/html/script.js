// Vehicle Calling Menu - JavaScript

let currentVehicles = {};

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        openVehicleMenu(data.categories, data.vehicles, data.config);
    } else if (data.action === 'close') {
        closeVehicleMenu();
    }
});

function openVehicleMenu(categories, vehicles, config) {
    currentVehicles = vehicles;
    
    // Render personal vehicles
    renderVehicleList('personal-vehicles', vehicles.personal);
    
    // Render rented vehicles
    renderVehicleList('rented-vehicles', vehicles.rented);
    
    // Render job vehicles
    renderVehicleList('job-vehicles', vehicles.job);
    
    document.getElementById('vehicle-menu').classList.remove('hidden');
}

function closeVehicleMenu() {
    document.getElementById('vehicle-menu').classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function renderVehicleList(containerId, vehicles) {
    const container = document.getElementById(containerId);
    container.innerHTML = '';
    
    if (!vehicles || vehicles.length === 0) {
        container.innerHTML = `
            <div class="no-vehicles">
                <div class="no-vehicles-icon">🚗</div>
                <div>No vehicles available</div>
            </div>
        `;
        return;
    }
    
    vehicles.forEach(vehicle => {
        const vehicleItem = document.createElement('div');
        vehicleItem.className = 'vehicle-item';
        
        const iconDiv = document.createElement('div');
        iconDiv.className = 'vehicle-icon';
        iconDiv.textContent = '🚗';
        
        const infoDiv = document.createElement('div');
        infoDiv.className = 'vehicle-info';
        
        const nameDiv = document.createElement('div');
        nameDiv.className = 'vehicle-name';
        nameDiv.textContent = vehicle.name || vehicle.model;
        
        const detailsDiv = document.createElement('div');
        detailsDiv.className = 'vehicle-details';
        const details = [];
        if (vehicle.plate) details.push(`Plate: ${vehicle.plate}`);
        if (vehicle.type === 'rented' && vehicle.expiry) details.push(`Expires: ${vehicle.expiry}`);
        if (vehicle.type === 'owned' && !vehicle.stored) details.push('Already spawned');
        detailsDiv.textContent = details.join(' | ');
        
        infoDiv.appendChild(nameDiv);
        infoDiv.appendChild(detailsDiv);
        
        const spawnBtn = document.createElement('button');
        spawnBtn.className = 'spawn-btn';
        spawnBtn.textContent = 'Spawn';
        
        spawnBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            spawnVehicle(vehicle);
        });
        
        vehicleItem.appendChild(iconDiv);
        vehicleItem.appendChild(infoDiv);
        vehicleItem.appendChild(spawnBtn);
        
        vehicleItem.addEventListener('click', function() {
            spawnVehicle(vehicle);
        });
        
        container.appendChild(vehicleItem);
    });
}

function spawnVehicle(vehicle) {
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            vehicle: vehicle
        })
    });
}

// Tab switching
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', function() {
        // Remove active class from all tabs
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        
        // Add active class to clicked tab
        this.classList.add('active');
        
        // Hide all tab contents
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.add('hidden');
        });
        
        // Show selected tab content
        const tabName = this.dataset.tab;
        document.getElementById(tabName + '-tab').classList.remove('hidden');
    });
});

// Close button
document.getElementById('close-btn').addEventListener('click', closeVehicleMenu);

// Close on escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeVehicleMenu();
    }
});
