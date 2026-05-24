// Phantom Gangs NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'showGang') {
        document.getElementById('gangName').textContent = data.gangName || 'NO GANG';
        document.getElementById('gangTag').textContent = data.gangTag || '---';
        document.getElementById('territoryCount').textContent = data.territories || 0;
        document.getElementById('memberCount').textContent = data.members || 0;
        document.getElementById('warsWon').textContent = data.warsWon || 0;
        document.getElementById('app').classList.remove('hidden');
    }
    if (data.action === 'hide') {
        document.getElementById('app').classList.add('hidden');
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        document.getElementById('app').classList.add('hidden');
    }
});
