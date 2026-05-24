// Phantom Mechanic Tablet JS

let currentTab = 'pending';
let currentOrderData = null;

// Clock update
function updateClock() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: true 
    });
    document.getElementById('clock').textContent = timeStr;
}
setInterval(updateClock, 1000);
updateClock();

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openTablet') {
        document.getElementById('tablet').classList.remove('hidden');
    }

    if (data.action === 'loadOrders') {
        renderPendingOrders(data.pending);
        renderMyOrders(data.myOrders);
    }
});

// Close button
document.getElementById('closeBtn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeTablet`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.getElementById('tablet').classList.add('hidden');
});

// Tab navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tab = this.dataset.tab;
        switchTab(tab);
    });
});

function switchTab(tab) {
    currentTab = tab;

    // Update nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tab) {
            btn.classList.add('active');
        }
    });

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    if (tab === 'pending') {
        document.getElementById('pendingTab').classList.add('active');
    } else if (tab === 'active') {
        document.getElementById('activeTab').classList.add('active');
    } else if (tab === 'completed') {
        document.getElementById('completedTab').classList.add('active');
    }
}

// Refresh button
document.getElementById('refreshBtn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/refreshOrders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Render pending orders
function renderPendingOrders(orders) {
    const container = document.getElementById('pendingOrdersList');
    const count = orders ? orders.length : 0;
    document.getElementById('pendingCount').textContent = count;

    if (!orders || orders.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📭</div>
                <p>No pending orders</p>
            </div>
        `;
        return;
    }

    container.innerHTML = orders.map(order => `
        <div class="order-card" onclick="viewOrderDetails('${order.id}')">
            <div class="order-status pending">⏳</div>
            <div class="order-info">
                <div class="order-id">#${order.id}</div>
                <div class="order-title">${order.customerName} - ${order.vehicleModel}</div>
                <div class="order-details">
                    <span>📋 ${order.upgrades ? order.upgrades.length : 0} upgrades</span>
                    <span>🚗 ${order.plate}</span>
                </div>
            </div>
            <div class="order-price">$${order.totalPrice}</div>
            <div class="order-actions">
                <button class="btn btn-primary" onclick="event.stopPropagation(); acceptOrder('${order.id}')">Accept</button>
            </div>
        </div>
    `).join('');
}

// Render my orders (active + completed)
function renderMyOrders(orders) {
    if (!orders) orders = [];

    const activeOrders = orders.filter(o => o.status === 'in_progress');
    const completedOrders = orders.filter(o => o.status === 'completed');

    // Active tab
    const activeContainer = document.getElementById('activeOrdersList');
    if (activeOrders.length === 0) {
        activeContainer.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">🔧</div>
                <p>No active jobs</p>
            </div>
        `;
    } else {
        activeContainer.innerHTML = activeOrders.map(order => `
            <div class="order-card" onclick="viewOrderDetails('${order.id}')">
                <div class="order-status in_progress">🔧</div>
                <div class="order-info">
                    <div class="order-id">#${order.id}</div>
                    <div class="order-title">${order.customerName} - ${order.vehicleModel}</div>
                    <div class="order-details">
                        <span>🚗 ${order.plate}</span>
                        <span>⏱️ ${getTimeAgo(order.accepted_at || order.created_at)}</span>
                    </div>
                </div>
                <div class="order-price">$${order.totalPrice}</div>
                <div class="order-actions">
                    <button class="btn btn-success" onclick="event.stopPropagation(); completeOrder('${order.id}')">Complete</button>
                </div>
            </div>
        `).join('');
    }

    // Completed tab
    const completedContainer = document.getElementById('completedOrdersList');
    if (completedOrders.length === 0) {
        completedContainer.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📊</div>
                <p>No completed orders yet</p>
            </div>
        `;
    } else {
        completedContainer.innerHTML = completedOrders.map(order => `
            <div class="order-card">
                <div class="order-status completed">✅</div>
                <div class="order-info">
                    <div class="order-id">#${order.id}</div>
                    <div class="order-title">${order.customerName} - ${order.vehicleModel}</div>
                    <div class="order-details">
                        <span>🚗 ${order.plate}</span>
                        <span>✓ Completed</span>
                    </div>
                </div>
                <div class="order-price">$${order.totalPrice}</div>
            </div>
        `).join('');
    }
}

// View order details
function viewOrderDetails(orderId) {
    fetch(`https://${GetParentResourceName()}/getOrderDetails`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId: orderId })
    }).then(resp => resp.json()).then(order => {
        if (!order) return;
        currentOrderData = order;

        const modalBody = document.getElementById('modalBody');
        const modalFooter = document.getElementById('modalFooter');

        let upgradesHtml = '';
        if (order.upgrades && order.upgrades.length > 0) {
            upgradesHtml = `
                <div class="upgrades-list">
                    <h4>Requested Upgrades</h4>
                    ${order.upgrades.map(u => `
                        <div class="upgrade-item">
                            <span class="check">✓</span>
                            <span>${u.label || u.name} - $${u.price}</span>
                        </div>
                    `).join('')}
                </div>
            `;
        }

        modalBody.innerHTML = `
            <div class="detail-row">
                <span class="detail-label">Order ID</span>
                <span class="detail-value">#${order.id}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Customer</span>
                <span class="detail-value">${order.customerName}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Vehicle</span>
                <span class="detail-value">${order.vehicleModel}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Plate</span>
                <span class="detail-value">${order.plate}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status</span>
                <span class="detail-value">${order.status.replace('_', ' ').toUpperCase()}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Total Price</span>
                <span class="detail-value">$${order.totalPrice}</span>
            </div>
            ${order.mechanicName ? `
                <div class="detail-row">
                    <span class="detail-label">Mechanic</span>
                    <span class="detail-value">${order.mechanicName}</span>
                </div>
            ` : ''}
            ${order.description ? `
                <div class="detail-row" style="flex-direction: column; align-items: flex-start;">
                    <span class="detail-label">Description</span>
                    <span class="detail-value" style="margin-top: 5px;">${order.description}</span>
                </div>
            ` : ''}
            ${upgradesHtml}
        `;

        // Footer buttons based on status
        modalFooter.innerHTML = '';
        if (order.status === 'pending') {
            modalFooter.innerHTML = `
                <button class="btn btn-primary" onclick="acceptOrder('${order.id}')">Accept Order</button>
                <button class="btn btn-secondary modal-close-btn">Close</button>
            `;
        } else if (order.status === 'in_progress') {
            modalFooter.innerHTML = `
                <button class="btn btn-success" onclick="completeOrder('${order.id}')">Complete Order</button>
                <button class="btn btn-secondary modal-close-btn">Close</button>
            `;
        } else {
            modalFooter.innerHTML = `
                <button class="btn btn-secondary modal-close-btn">Close</button>
            `;
        }

        document.getElementById('orderModal').classList.remove('hidden');

        // Re-attach close listeners
        document.querySelectorAll('.modal-close-btn').forEach(btn => {
            btn.addEventListener('click', closeModal);
        });
    });
}

// Close modal
function closeModal() {
    document.getElementById('orderModal').classList.add('hidden');
    currentOrderData = null;
}

document.querySelector('.modal-backdrop').addEventListener('click', closeModal);
document.querySelector('.modal-close').addEventListener('click', closeModal);

// Accept order
function acceptOrder(orderId) {
    fetch(`https://${GetParentResourceName()}/acceptOrder`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId: orderId })
    });
    closeModal();
}

// Complete order
function completeOrder(orderId) {
    fetch(`https://${GetParentResourceName()}/completeOrder`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId: orderId })
    });
    closeModal();
}

// Helper: Time ago
function getTimeAgo(timestamp) {
    if (!timestamp) return 'Just now';
    const seconds = Math.floor((Date.now() / 1000) - timestamp);
    if (seconds < 60) return 'Just now';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return minutes + 'm ago';
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return hours + 'h ago';
    const days = Math.floor(hours / 24);
    return days + 'd ago';
}

// Escape key to close
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (!document.getElementById('orderModal').classList.contains('hidden')) {
            closeModal();
        } else {
            document.getElementById('closeBtn').click();
        }
    }
});
