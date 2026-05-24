// GTA Weapon Wheel - JavaScript

let currentCategories = {};
let selectedCategory = null;
let selectedWeapon = null;

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        openWeaponWheel(data.categories, data.config);
    } else if (data.action === 'close') {
        closeWeaponWheel();
    }
});

function openWeaponWheel(categories, config) {
    currentCategories = categories;
    const wheel = document.querySelector('.wheel');
    wheel.innerHTML = '';

    // Calculate positions for categories in a circle
    const categoryKeys = Object.keys(categories);
    const centerX = 250;
    const centerY = 250;
    const radius = 180;

    categoryKeys.forEach((categoryKey, index) => {
        const category = categories[categoryKey];
        const angle = (index / categoryKeys.length) * 2 * Math.PI - Math.PI / 2;
        const x = centerX + radius * Math.cos(angle) - 30;
        const y = centerY + radius * Math.sin(angle) - 30;

        const categoryElement = document.createElement('div');
        categoryElement.className = 'category';
        categoryElement.style.left = x + 'px';
        categoryElement.style.top = y + 'px';
        categoryElement.style.borderColor = category.color;
        categoryElement.style.boxShadow = `0 0 15px ${category.color}40`;
        categoryElement.dataset.category = categoryKey;

        // Category icon (using emoji as placeholder)
        const iconElement = document.createElement('div');
        iconElement.className = 'category-icon';
        iconElement.style.color = category.color;
        
        // Map category names to emoji icons
        const iconMap = {
            'Handguns': '🔫',
            'Submachine Guns': '🔫',
            'Shotguns': '🔫',
            'Assault Rifles': '🔫',
            'Light Machine Guns': '🔫',
            'Sniper Rifles': '🎯',
            'Heavy Weapons': '💣',
            'Thrown': '💣',
        };
        
        iconElement.textContent = iconMap[category.name] || '🔫';
        categoryElement.appendChild(iconElement);

        // Weapon list for this category
        if (category.weapons && category.weapons.length > 0) {
            const weaponList = document.createElement('div');
            weaponList.className = 'weapon-list';
            weaponList.id = `weapon-list-${categoryKey}`;
            
            category.weapons.forEach(weapon => {
                const weaponItem = document.createElement('div');
                weaponItem.className = 'weapon-item';
                weaponItem.dataset.weapon = JSON.stringify(weapon);
                weaponItem.dataset.category = categoryKey;
                
                const weaponName = document.createElement('div');
                weaponName.className = 'weapon-name';
                weaponName.textContent = weapon.label || weapon.name;
                weaponItem.appendChild(weaponName);
                
                const weaponAmmo = document.createElement('div');
                weaponAmmo.className = 'weapon-ammo';
                weaponAmmo.textContent = `Ammo: ${weapon.ammo || 0}`;
                weaponItem.appendChild(weaponAmmo);
                
                weaponItem.addEventListener('click', function() {
                    selectWeapon(weapon, categoryKey);
                });
                
                weaponItem.addEventListener('mouseenter', function() {
                    hoverWeapon(weapon);
                });
                
                weaponList.appendChild(weaponItem);
            });
            
            // Position weapon list outside the wheel
            const listX = x + 70;
            const listY = y - 50;
            weaponList.style.left = listX + 'px';
            weaponList.style.top = listY + 'px';
            
            categoryElement.appendChild(weaponList);
            
            categoryElement.addEventListener('click', function(e) {
                e.stopPropagation();
                toggleWeaponList(categoryKey);
            });
            
            categoryElement.addEventListener('mouseenter', function() {
                selectCategory(categoryKey);
            });
        }

        wheel.appendChild(categoryElement);
    });

    document.getElementById('weapon-wheel').classList.remove('hidden');
}

function closeWeaponWheel() {
    document.getElementById('weapon-wheel').classList.add('hidden');
    
    if (selectedWeapon) {
        fetch(`https://${GetParentResourceName()}/selectWeapon`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                weapon: selectedWeapon
            })
        });
    }
    
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function selectCategory(categoryKey) {
    // Remove selected class from all categories
    document.querySelectorAll('.category').forEach(cat => {
        cat.classList.remove('selected');
    });
    
    // Add selected class to clicked category
    const categoryElement = document.querySelector(`[data-category="${categoryKey}"]`);
    if (categoryElement) {
        categoryElement.classList.add('selected');
    }
    
    selectedCategory = categoryKey;
    
    // Update center info
    const category = currentCategories[categoryKey];
    if (category) {
        document.getElementById('weapon-name').textContent = category.name;
        document.getElementById('weapon-ammo').textContent = `${category.weapons.length} weapons`;
    }
}

function toggleWeaponList(categoryKey) {
    const weaponList = document.getElementById(`weapon-list-${categoryKey}`);
    if (weaponList) {
        weaponList.classList.toggle('show');
    }
}

function selectWeapon(weapon, categoryKey) {
    // Remove selected class from all weapons
    document.querySelectorAll('.weapon-item').forEach(w => {
        w.classList.remove('selected');
    });
    
    // Add selected class to clicked weapon
    const weaponElement = document.querySelector(`[data-weapon="${JSON.stringify(weapon).replace(/"/g, '&quot;')}"]`);
    if (weaponElement) {
        weaponElement.classList.add('selected');
    }
    
    selectedWeapon = weapon;
    
    // Update center info
    document.getElementById('weapon-name').textContent = weapon.label || weapon.name;
    document.getElementById('weapon-ammo').textContent = `Ammo: ${weapon.ammo || 0}`;
    
    // Close weapon wheel after selection
    setTimeout(() => {
        closeWeaponWheel();
    }, 200);
}

function hoverWeapon(weapon) {
    fetch(`https://${GetParentResourceName()}/hoverWeapon`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            weapon: weapon
        })
    });
}

// Close on escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeWeaponWheel();
    }
});
