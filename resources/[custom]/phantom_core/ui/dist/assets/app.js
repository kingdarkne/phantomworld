// Phantom Core UI JavaScript
window.addEventListener('load', function() {
    const content = document.getElementById('content');
    
    // Initialize the UI
    function initUI() {
        content.innerHTML = `
            <div class="dashboard">
                <h2>Phantom Core Dashboard</h2>
                <div class="stats">
                    <div class="stat-item">
                        <span class="stat-label">Status:</span>
                        <span class="stat-value">Online</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Version:</span>
                        <span class="stat-value">1.0.0</span>
                    </div>
                </div>
                <div class="actions">
                    <button class="btn" onclick="refreshData()">Refresh</button>
                    <button class="btn" onclick="closeUI()">Close</button>
                </div>
            </div>
        `;
    }
    
    // Refresh data function
    window.refreshData = function() {
        console.log('Refreshing Phantom Core data...');
        // Add data refresh logic here
    }
    
    // Close UI function
    window.closeUI = function() {
        // Send message to NUI to close
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).then(() => {
            // UI closed
        });
    }
    
    // Listen for messages from Lua
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch (data.action) {
            case 'showUI':
                document.getElementById('app').style.display = 'flex';
                break;
            case 'hideUI':
                document.getElementById('app').style.display = 'none';
                break;
            case 'updateData':
                if (data.content) {
                    content.innerHTML = data.content;
                }
                break;
            case 'addNotification':
                addNotification(data);
                break;
            case 'removeNotification':
                removeNotification(data.id);
                break;
        }
    });

    function addNotification(data) {
        const container = document.getElementById('notifications');
        if (!container) return;
        const notif = document.createElement('div');
        notif.className = 'notification';
        notif.id = 'notif-' + data.id;
        const color = (data.config && data.config.color) ? data.config.color : '#3b82f6';
        const icon = (data.config && data.config.icon) ? data.config.icon : 'ℹ️';
        notif.style.borderLeftColor = color;
        notif.innerHTML = '<span class="notification-icon">' + icon + '</span>'
            + '<span class="notification-message">' + (data.message || '') + '</span>';
        container.appendChild(notif);
    }

    function removeNotification(id) {
        const notif = document.getElementById('notif-' + id);
        if (notif) {
            notif.style.animation = 'notifSlideOut 0.3s ease forwards';
            setTimeout(function() { if (notif.parentNode) notif.parentNode.removeChild(notif); }, 300);
        }
    }
    
    // Initialize UI on load
    initUI();
});

// Communication with FiveM
function sendMessage(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    });
}
