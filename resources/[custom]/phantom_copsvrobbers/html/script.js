window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'showLobby') {
        document.getElementById('lobby').classList.remove('hidden');
        updateTeams(data.cops, data.robbers);
    }
    if (data.action === 'hideLobby') {
        document.getElementById('lobby').classList.add('hidden');
    }
    if (data.action === 'updateTimer') {
        document.getElementById('lobbyTimer').textContent = data.time;
    }
});

function updateTeams(cops, robbers) {
    const copsList = document.getElementById('copsList');
    const robbersList = document.getElementById('robbersList');

    copsList.innerHTML = '';
    robbersList.innerHTML = '';

    if (cops && cops.length > 0) {
        cops.forEach(p => {
            const div = document.createElement('div');
            div.className = 'player-slot';
            div.textContent = p.name;
            copsList.appendChild(div);
        });
    } else {
        copsList.innerHTML = '<div class="player-slot empty">Waiting...</div>';
    }

    if (robbers && robbers.length > 0) {
        robbers.forEach(p => {
            const div = document.createElement('div');
            div.className = 'player-slot';
            div.textContent = p.name;
            robbersList.appendChild(div);
        });
    } else {
        robbersList.innerHTML = '<div class="player-slot empty">Waiting...</div>';
    }
}
