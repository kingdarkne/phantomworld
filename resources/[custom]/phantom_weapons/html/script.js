// Phantom Weapons NUI Controller

let currentWeapons = {};
let selectedWeapon = null;
let currentCategory = 'handguns';
let wheelCategories = [];
let wheelWeapons = [];

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openWeaponWheel') {
        openWeaponWheel(data.categories, data.weapons, data.currentSlot);
    }

    if (data.action === 'closeWeaponWheel') {
        closeWeaponWheel();
    }

    if (data.action === 'selectSlot') {
        selectSlot(data.slot);
    }

    if (data.action === 'openAmmuNation') {
        openAmmuNation(data.weapons, data.ammo, data.tints, data.attachments);
    }
});

// Weapon Wheel
function openWeaponWheel(categories, weapons, currentSlot) {
    wheelCategories = categories || [];
    wheelWeapons = weapons || [];

    const wheel = document.getElementById('weaponWheel');
    const slots = document.getElementById('wheelSlots');
    slots.innerHTML = '';

    // Position 6 slots in circle
    const radius = 180;
    for (let i = 0; i < 6; i++) {
        const angle = (i * 60 - 90) * (Math.PI / 180);
        const x = Math.cos(angle) * radius + 160;
        const y = Math.sin(angle) * radius + 160;

        const slot = document.createElement('div');
        slot.className = 'wheel-slot' + (i + 1 === currentSlot ? ' active' : '');
        slot.style.left = x + 'px';
        slot.style.top = y + 'px';

        const slotInfo = weapons && weapons[i];
        if (!slotInfo) slot.classList.add('empty');

        slot.innerHTML = `
            <div class="slot-icon">${slotInfo ? getWeaponIcon(slotInfo.weaponName) : (categories[i]?.icon || '🔫')}</div>
            <div class="slot-name">${slotInfo ? slotInfo.displayName : (categories[i]?.name || 'SLOT ' + (i + 1))}</div>
        `;

        slots.appendChild(slot);
    }

    wheel.classList.remove('hidden');
    selectSlot(currentSlot);
}

function closeWeaponWheel() {
    document.getElementById('weaponWheel').classList.add('hidden');
}

function selectSlot(slot) {
    document.querySelectorAll('.wheel-slot').forEach((s, i) => {
        s.classList.toggle('active', i + 1 === slot);
    });

    const info = wheelWeapons && wheelWeapons[slot - 1];
    const category = wheelCategories && wheelCategories[slot - 1];

    document.getElementById('selectedWeapon').textContent = info?.weaponName ? getWeaponIcon(info.weaponName) : (category?.icon || '🔫');
    document.getElementById('selectedName').textContent = info?.displayName || category?.name || 'WEAPON';
    document.getElementById('selectedAmmo').textContent = info ? `AMMO: ${info.ammo}` : 'AMMO: --';
}

// Ammu-Nation Store
function openAmmuNation(weapons, ammo, tints, attachments) {
    currentWeapons = weapons || {};
    document.getElementById('ammuNation').classList.remove('hidden');
    selectCategory('handguns');
}

function selectCategory(category) {
    currentCategory = category;

    // Update tabs
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.toggle('active', tab.dataset.category === category);
    });

    // Render weapons
    const grid = document.getElementById('weaponsGrid');
    grid.innerHTML = '';

    const categoryWeapons = getWeaponsForCategory(category);
    categoryWeapons.forEach(weapon => {
        const card = createWeaponCard(weapon);
        grid.appendChild(card);
    });
}

function getWeaponsForCategory(category) {
    const weaponsByCategory = {
        melee: ['weapon_knife', 'weapon_bat', 'weapon_crowbar', 'weapon_golfclub', 'weapon_hammer'],
        handguns: ['weapon_pistol', 'weapon_pistol_mk2', 'weapon_combatpistol', 'weapon_appistol', 'weapon_pistol50'],
        smg: ['weapon_microsmg', 'weapon_smg', 'weapon_smg_mk2', 'weapon_assaultsmg'],
        rifles: ['weapon_assaultrifle', 'weapon_assaultrifle_mk2', 'weapon_carbinerifle', 'weapon_carbinerifle_mk2'],
        shotguns: ['weapon_pumpshotgun', 'weapon_pumpshotgun_mk2', 'weapon_sawnoffshotgun', 'weapon_assaultshotgun'],
        heavy: ['weapon_mg', 'weapon_combatmg', 'weapon_combatmg_mk2', 'weapon_minigun'],
        sniper: ['weapon_sniperrifle', 'weapon_heavysniper', 'weapon_heavysniper_mk2'],
    };

    const weapons = weaponsByCategory[category] || [];
    return weapons.map(name => ({
        name: name,
        displayName: name.replace('weapon_', '').replace(/_/g, ' ').toUpperCase(),
        price: currentWeapons[name] || 1000,
        icon: getWeaponIcon(name),
    }));
}

function getWeaponIcon(weapon) {
    if (weapon.includes('knife') || weapon.includes('machete')) return '🔪';
    if (weapon.includes('bat') || weapon.includes('club')) return '🏏';
    if (weapon.includes('rifle') || weapon.includes('carbine')) return '🔫';
    if (weapon.includes('smg') || weapon.includes('micro')) return '🔫';
    if (weapon.includes('shotgun')) return '🔫';
    if (weapon.includes('heavy') || weapon.includes('mg') || weapon.includes('minigun')) return '💣';
    if (weapon.includes('sniper')) return '🎯';
    return '🔫';
}

function createWeaponCard(weapon) {
    const card = document.createElement('div');
    card.className = 'weapon-card';
    card.innerHTML = `
        <div class="weapon-icon">${weapon.icon}</div>
        <div class="weapon-name">${weapon.displayName}</div>
        <div class="weapon-price">$${weapon.price.toLocaleString()}</div>
    `;
    card.addEventListener('click', () => selectWeapon(weapon, card));
    return card;
}

function selectWeapon(weapon, cardElement) {
    document.querySelectorAll('.weapon-card').forEach(c => c.classList.remove('active'));
    cardElement.classList.add('active');

    selectedWeapon = weapon;

    // Show detail panel
    document.getElementById('detailName').textContent = weapon.displayName;
    document.getElementById('detailPrice').textContent = '$' + weapon.price.toLocaleString();
    document.getElementById('detailImage').textContent = weapon.icon;

    // Random stats animation
    setTimeout(() => {
        document.getElementById('damageBar').style.width = (Math.random() * 30 + 50) + '%';
        document.getElementById('fireRateBar').style.width = (Math.random() * 40 + 40) + '%';
        document.getElementById('accuracyBar').style.width = (Math.random() * 30 + 60) + '%';
        document.getElementById('rangeBar').style.width = (Math.random() * 40 + 40) + '%';
    }, 100);
}

// Tab handlers
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        selectCategory(tab.dataset.category);
    });
});

// Close button
document.getElementById('closeStore').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeAmmuNation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.getElementById('ammuNation').classList.add('hidden');
});

// Buy button
document.getElementById('btnBuyWeapon').addEventListener('click', () => {
    if (!selectedWeapon) return;

    fetch(`https://${GetParentResourceName()}/buyWeapon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ weaponName: selectedWeapon.name })
    });
});

// Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeWeaponWheel();
        document.getElementById('ammuNation').classList.add('hidden');
    }
});
