// Phantom Heists - Minigames JavaScript

let gameState = null;
let timerInterval = null;

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'startHack') {
        startHackGame(data.duration, data.gridSize, data.requiredMatches);
    } else if (data.action === 'startThermite') {
        startThermiteGame(data.duration, data.gridSize, data.requiredMatches);
    } else if (data.action === 'startDrill') {
        startDrillGame(data.duration, data.targetDepth, data.heatLimit);
    }
});

// ==================== HACKING GAME ====================
function startHackGame(duration, gridSize, requiredMatches) {
    hideAllGames();
    document.getElementById('hackGame').classList.remove('hidden');

    const grid = document.getElementById('hackGrid');
    grid.style.gridTemplateColumns = `repeat(${gridSize}, 1fr)`;
    grid.innerHTML = '';

    const pairs = (gridSize * gridSize) / 2;
    const symbols = ['⚡', '🔒', '🔑', '💻', '📡', '🔌', '💾', '📀', '🎛️', '🔋', '📟', '🔨'];
    let cards = [];

    for (let i = 0; i < pairs; i++) {
        const symbol = symbols[i % symbols.length];
        cards.push({ id: i, symbol: symbol, matched: false });
        cards.push({ id: i, symbol: symbol, matched: false });
    }

    // Shuffle
    cards.sort(() => Math.random() - 0.5);

    let flipped = [];
    let matched = 0;
    let canClick = true;

    cards.forEach((card, index) => {
        const cell = document.createElement('div');
        cell.className = 'grid-cell';
        cell.dataset.index = index;
        cell.dataset.id = card.id;
        cell.textContent = '?';
        cell.addEventListener('click', () => {
            if (!canClick || card.matched || flipped.includes(index)) return;

            cell.classList.add('flipped');
            cell.textContent = card.symbol;
            flipped.push(index);

            if (flipped.length === 2) {
                canClick = false;
                const idx1 = flipped[0];
                const idx2 = flipped[1];
                const card1 = cards[idx1];
                const card2 = cards[idx2];

                if (card1.id === card2.id) {
                    card1.matched = true;
                    card2.matched = true;
                    matched++;
                    setTimeout(() => {
                        grid.children[idx1].classList.add('matched');
                        grid.children[idx2].classList.add('matched');
                        flipped = [];
                        canClick = true;
                        updateProgress(matched, requiredMatches);

                        if (matched >= requiredMatches) {
                            endGame(true);
                        }
                    }, 300);
                } else {
                    setTimeout(() => {
                        grid.children[idx1].classList.add('wrong');
                        grid.children[idx2].classList.add('wrong');
                        setTimeout(() => {
                            grid.children[idx1].classList.remove('flipped', 'wrong');
                            grid.children[idx2].classList.remove('flipped', 'wrong');
                            grid.children[idx1].textContent = '?';
                            grid.children[idx2].textContent = '?';
                            flipped = [];
                            canClick = true;
                        }, 400);
                    }, 600);
                }
            }
        });
        grid.appendChild(cell);
    });

    startTimer(duration, () => endGame(false));
}

// ==================== THERMITE GAME ====================
function startThermiteGame(duration, gridSize, requiredMatches) {
    hideAllGames();
    document.getElementById('thermiteGame').classList.remove('hidden');

    const grid = document.getElementById('thermiteGrid');
    grid.style.gridTemplateColumns = `repeat(${gridSize}, 1fr)`;
    grid.innerHTML = '';

    let pattern = [];
    let playerPattern = [];
    let currentMatch = 0;
    let phase = 'watch'; // watch or play

    // Create cells
    for (let i = 0; i < gridSize * gridSize; i++) {
        const cell = document.createElement('div');
        cell.className = 'grid-cell';
        cell.dataset.index = i;
        cell.addEventListener('click', () => {
            if (phase !== 'play') return;
            handleThermiteClick(i);
        });
        grid.appendChild(cell);
    }

    // Generate and show pattern
    function generatePattern() {
        pattern = [];
        for (let i = 0; i < requiredMatches; i++) {
            pattern.push(Math.floor(Math.random() * (gridSize * gridSize)));
        }
    }

    function showPattern() {
        phase = 'watch';
        document.getElementById('thermitePhase').textContent = 'WATCH PATTERN';
        playerPattern = [];
        currentMatch = 0;

        let i = 0;
        const interval = setInterval(() => {
            if (i >= pattern.length) {
                clearInterval(interval);
                phase = 'play';
                document.getElementById('thermitePhase').textContent = 'REPEAT PATTERN';
                return;
            }
            const cell = grid.children[pattern[i]];
            cell.classList.add('pattern');
            setTimeout(() => cell.classList.remove('pattern'), 400);
            i++;
        }, 600);
    }

    function handleThermiteClick(index) {
        if (playerPattern.includes(index)) return;

        const cell = grid.children[index];
        cell.classList.add('player-select');
        setTimeout(() => cell.classList.remove('player-select'), 200);

        if (index === pattern[currentMatch]) {
            cell.classList.add('correct');
            playerPattern.push(index);
            currentMatch++;

            if (currentMatch >= requiredMatches) {
                endGame(true);
            }
        } else {
            cell.classList.add('wrong');
            setTimeout(() => endGame(false), 300);
        }
    }

    generatePattern();
    showPattern();
    startTimer(duration, () => endGame(false));
}

// ==================== DRILLING GAME ====================
let drilling = false;
let drillDepth = 0;
let drillHeat = 0;
let drillTimer = null;
let drillLoop = null;

function startDrillGame(duration, targetDepth, heatLimit) {
    hideAllGames();
    document.getElementById('drillGame').classList.remove('hidden');

    drillDepth = 0;
    drillHeat = 0;
    drilling = false;

    const heatFill = document.getElementById('heatFill');
    const depthFill = document.getElementById('depthFill');
    const drillBit = document.getElementById('drillBit');

    startTimer(duration, () => {
        if (drillDepth >= targetDepth) {
            endGame(true);
        } else {
            endGame(false);
        }
    });

    drillLoop = setInterval(() => {
        if (drilling) {
            drillDepth += 0.5;
            drillHeat += 1.5;
        } else {
            drillHeat -= 2;
        }

        drillHeat = Math.max(0, Math.min(heatLimit, drillHeat));

        // Update visuals
        heatFill.style.width = (drillHeat / heatLimit * 100) + '%';
        depthFill.style.width = (drillDepth / targetDepth * 100) + '%';

        const bitPosition = 20 + (drillDepth / targetDepth * 100);
        drillBit.style.top = bitPosition + 'px';

        if (drilling) {
            drillBit.classList.add('active');
        } else {
            drillBit.classList.remove('active');
        }

        // Overheat = fail
        if (drillHeat >= heatLimit) {
            clearInterval(drillLoop);
            endGame(false);
        }

        // Success
        if (drillDepth >= targetDepth) {
            clearInterval(drillLoop);
            endGame(true);
        }
    }, 50);
}

function startDrilling() {
    drilling = true;
}

function stopDrilling() {
    drilling = false;
}

// ==================== UTILITIES ====================
function startTimer(duration, onComplete) {
    let timeLeft = duration;
    const timerEl = document.querySelector('.game-container:not(.hidden) .timer');

    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => {
        timeLeft -= 0.01;
        if (timerEl) timerEl.textContent = timeLeft.toFixed(2);

        if (timeLeft <= 0) {
            clearInterval(timerInterval);
            onComplete();
        }
    }, 10);
}

function updateProgress(current, total) {
    const fill = document.getElementById('hackProgress');
    if (fill) fill.style.width = (current / total * 100) + '%';
}

function endGame(success) {
    if (timerInterval) clearInterval(timerInterval);
    if (drillLoop) clearInterval(drillLoop);
    drilling = false;

    let resultAction = '';
    const hackVisible = !document.getElementById('hackGame').classList.contains('hidden');
    const thermiteVisible = !document.getElementById('thermiteGame').classList.contains('hidden');

    if (hackVisible) resultAction = 'hackResult';
    else if (thermiteVisible) resultAction = 'thermiteResult';
    else resultAction = 'drillResult';

    fetch(`https://${GetParentResourceName()}/${resultAction}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ success: success })
    });

    setTimeout(() => {
        hideAllGames();
    }, 500);
}

function hideAllGames() {
    document.querySelectorAll('.game-container').forEach(el => el.classList.add('hidden'));
}
