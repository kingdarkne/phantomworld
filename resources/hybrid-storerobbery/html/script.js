let menuVisible = false;
let currentStore = null;

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'showMenu':
            showMenu(data);
            break;
        case 'hideMenu':
            hideMenu();
            break;
    }
});

// Show menu function
function showMenu(data) {
    currentStore = data.storeId;
    
    // Update store title
    const storeTitle = document.getElementById('storeTitle');
    storeTitle.textContent = data.storeType.toUpperCase() + ' STORE OPTIONS';
    
    // Show menu
    const menuContainer = document.getElementById('menuContainer');
    menuContainer.classList.remove('hidden');
    menuContainer.classList.remove('slide-out');
    
    menuVisible = true;
    
    // Focus on close button for accessibility
    document.getElementById('closeBtn').focus();
}

// Hide menu function
function hideMenu() {
    const menuContainer = document.getElementById('menuContainer');
    menuContainer.classList.add('slide-out');
    
    setTimeout(() => {
        menuContainer.classList.add('hidden');
        menuContainer.classList.remove('slide-out');
    }, 300);
    
    menuVisible = false;
    currentStore = null;
}

// Handle menu button clicks
document.addEventListener('click', function(event) {
    if (event.target.classList.contains('menu-btn')) {
        const action = event.target.getAttribute('data-action');
        
        // Send selection to Lua
        fetch(`https://hybrid-storerobbery/selectOption`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                storeId: currentStore,
                action: action
            })
        });
    }
    
    if (event.target.id === 'closeBtn') {
        // Send close to Lua
        fetch(`https://hybrid-storerobbery/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }
});

// Keyboard navigation
document.addEventListener('keydown', function(event) {
    if (!menuVisible) return;
    
    switch (event.key) {
        case 'Escape':
            // Close menu
            fetch(`https://hybrid-storerobbery/closeMenu`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({})
            });
            break;
        case 'Enter':
            // Activate focused button
            const focusedElement = document.activeElement;
            if (focusedElement.classList.contains('menu-btn')) {
                focusedElement.click();
            }
            break;
        case 'ArrowUp':
        case 'ArrowDown':
            event.preventDefault();
            navigateMenu(event.key === 'ArrowDown' ? 1 : -1);
            break;
    }
});

// Navigate menu with arrow keys
function navigateMenu(direction) {
    const buttons = Array.from(document.querySelectorAll('.menu-btn:not([disabled])'));
    const currentIndex = buttons.findIndex(btn => btn === document.activeElement);
    
    let nextIndex;
    if (currentIndex === -1) {
        nextIndex = direction > 0 ? 0 : buttons.length - 1;
    } else {
        nextIndex = currentIndex + direction;
        if (nextIndex < 0) nextIndex = buttons.length - 1;
        if (nextIndex >= buttons.length) nextIndex = 0;
    }
    
    buttons[nextIndex].focus();
}

// Add hover effects
document.addEventListener('DOMContentLoaded', function() {
    const buttons = document.querySelectorAll('.menu-btn');
    
    buttons.forEach(button => {
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px) scale(1.02)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
        
        button.addEventListener('mousedown', function() {
            this.style.transform = 'translateY(0) scale(0.98)';
        });
        
        button.addEventListener('mouseup', function() {
            this.style.transform = 'translateY(-2px) scale(1.02)';
        });
    });
});

// Prevent context menu
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});

// Handle window focus/blur for performance
window.addEventListener('blur', function() {
    // Optional: Hide menu when window loses focus
    // hideMenu();
});

window.addEventListener('focus', function() {
    // Optional: Restore menu state when window regains focus
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Set initial state
    hideMenu();
});
