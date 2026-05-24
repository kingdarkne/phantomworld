// Phantom Events NUI Controller

let activeEventTypes = [];

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'bigAnnouncement') {
        showBigAnnouncement(data);
    }

    if (data.action === 'eventEnded') {
        showEventEnded(data);
    }

    if (data.action === 'openAdminPanel') {
        openAdminPanel(data.events, data.activeEvents);
    }

    if (data.action === 'lotteryWinner') {
        showLotteryWinner(data);
    }

    if (data.action === 'hide') {
        // Hide all panels
        document.getElementById('bigAnnouncement').classList.add('hidden');
        document.getElementById('eventEnded').classList.add('hidden');
        document.getElementById('lotteryWinner').classList.add('hidden');
        document.getElementById('adminPanel').classList.add('hidden');
    }
});

// Big announcement
function showBigAnnouncement(data) {
    const container = document.getElementById('bigAnnouncement');
    const title = document.getElementById('announceTitle');
    const desc = document.getElementById('announceDesc');
    const timer = document.getElementById('announceTimer');
    const bar = document.getElementById('barFill');
    const icon = document.getElementById('announceIcon');

    // Set icon based on event type
    const icons = {
        moneyDrop: '💰',
        freeCars: '🚗',
        doubleXP: '✨',
        doublePayday: '💵',
        treasureHunt: '🏴‍☠️',
        lottery: '🎟️',
        vipBonus: '👑',
    };
    icon.textContent = icons[data.type] || '🎉';

    title.textContent = data.title || 'EVENT STARTED';
    desc.textContent = data.description || '';

    // Colors
    if (data.colors) {
        title.style.textShadow = `0 0 40px ${data.colors.primary}80, 0 4px 20px rgba(0,0,0,0.5)`;
        bar.style.background = `linear-gradient(90deg, ${data.colors.primary}, ${data.colors.secondary})`;
    }

    // Timer
    let timeLeft = data.duration || 60;
    updateTimerDisplay(timeLeft);

    const timerInterval = setInterval(() => {
        timeLeft--;
        updateTimerDisplay(timeLeft);
        if (timeLeft <= 0) {
            clearInterval(timerInterval);
            hideAnnouncement();
        }
    }, 1000);

    container.classList.remove('hidden');

    // Auto hide after duration
    setTimeout(() => {
        clearInterval(timerInterval);
        hideAnnouncement();
    }, data.duration ? data.duration * 1000 : 10000);
}

function updateTimerDisplay(seconds) {
    const timer = document.getElementById('announceTimer');
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    timer.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function hideAnnouncement() {
    document.getElementById('bigAnnouncement').classList.add('hidden');
}

// Event ended
function showEventEnded(data) {
    const container = document.getElementById('eventEnded');
    document.getElementById('endedDesc').textContent = data.title + ' has ended!';
    container.classList.remove('hidden');

    setTimeout(() => {
        container.classList.add('hidden');
    }, 5000);
}

// Lottery winner
function showLotteryWinner(data) {
    const container = document.getElementById('lotteryWinner');
    document.getElementById('winnerName').textContent = data.winner || 'Unknown';
    document.getElementById('winnerPrize').textContent = '$' + (data.prize || 0).toLocaleString();
    document.getElementById('winnerTickets').textContent = (data.totalTickets || 0) + ' tickets sold';
    container.classList.remove('hidden');

    setTimeout(() => {
        container.classList.add('hidden');
    }, 8000);
}

// Admin panel
function openAdminPanel(events, activeEvents) {
    // Ensure any other panels are hidden first
    document.getElementById('bigAnnouncement').classList.add('hidden');
    document.getElementById('eventEnded').classList.add('hidden');
    document.getElementById('lotteryWinner').classList.add('hidden');

    const container = document.getElementById('adminPanel');
    const grid = document.getElementById('eventGrid');
    grid.innerHTML = '';

    activeEventTypes = [];
    if (activeEvents) {
        for (const type in activeEvents) {
            activeEventTypes.push(type);
        }
    }

    const eventIcons = {
        moneyDrop: '💰',
        freeCars: '🚗',
        doubleXP: '✨',
        doublePayday: '💵',
        treasureHunt: '🏴‍☠️',
        lottery: '🎟️',
        vipBonus: '👑',
    };

    for (const [key, event] of Object.entries(events)) {
        if (!event.enabled) continue;

        const isActive = activeEventTypes.includes(key);
        const card = document.createElement('div');
        card.className = `event-card ${isActive ? 'active' : ''}`;
        card.style.setProperty('--primary', event.colors?.primary || '#ffd700');
        card.style.setProperty('--secondary', event.colors?.secondary || '#ffaa00');

        card.innerHTML = `
            <div class="event-icon">${eventIcons[key] || '🎉'}</div>
            <h3>${event.name}</h3>
            <p>${event.description}</p>
            <div class="event-actions">
                <button class="btn btn-start" ${isActive ? 'disabled' : ''} data-type="${key}">START</button>
                <button class="btn btn-stop" ${!isActive ? 'disabled' : ''} data-type="${key}">STOP</button>
            </div>
        `;

        grid.appendChild(card);
    }

    // Update active count
    document.getElementById('activeCount').textContent = activeEventTypes.length;

    container.classList.remove('hidden');

    // Button handlers
    document.querySelectorAll('.btn-start').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const type = btn.dataset.type;
            startEvent(type);
        });
    });

    document.querySelectorAll('.btn-stop').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const type = btn.dataset.type;
            stopEvent(type);
        });
    });
}

function startEvent(type) {
    // Default durations
    const durations = {
        moneyDrop: 300,
        freeCars: 600,
        doubleXP: 3600,
        doublePayday: 1800,
        treasureHunt: 900,
        lottery: 600,
        vipBonus: 3600,
    };

    fetch(`https://${GetParentResourceName()}/startEvent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            eventType: type,
            options: { duration: durations[type] || 300 }
        })
    });
}

function stopEvent(type) {
    fetch(`https://${GetParentResourceName()}/stopEvent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ eventType: type })
    });
}

// Close admin panel
document.getElementById('closeAdmin').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeAdminPanel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.getElementById('adminPanel').classList.add('hidden');
});

// Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const adminPanel = document.getElementById('adminPanel');
        if (!adminPanel.classList.contains('hidden')) {
            // Notify Lua to release focus
            fetch(`https://${GetParentResourceName()}/closeAdminPanel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
        document.getElementById('adminPanel').classList.add('hidden');
        document.getElementById('bigAnnouncement').classList.add('hidden');
        document.getElementById('eventEnded').classList.add('hidden');
        document.getElementById('lotteryWinner').classList.add('hidden');
    }
});
