(function () {
  const root = document.getElementById('phantom-dashboard');
  const els = {
    serverName: document.getElementById('pd-server-name'),
    time: document.getElementById('pd-time'),
    id: document.getElementById('pd-id'),
    name: document.getElementById('pd-name'),
    gang: document.getElementById('pd-gang'),
    street: document.getElementById('pd-street'),
    cash: document.getElementById('pd-cash'),
    bank: document.getElementById('pd-bank'),
    rank: document.getElementById('pd-rank'),
    job: document.getElementById('pd-job'),
    rankWrap: document.getElementById('pd-rank-wrap'),
    jobWrap: document.getElementById('pd-job-wrap'),
    money: document.getElementById('pd-money'),
    voice: document.getElementById('pd-voice'),
    voiceLabel: document.getElementById('pd-voice-label'),
    players: document.getElementById('pd-players'),
    uptime: document.getElementById('pd-uptime'),
    identity: document.getElementById('pd-identity'),
  };

  function formatUptime(seconds) {
    const total = Math.floor(Number(seconds) || 0);
    if (total <= 0) return 'Uptime —';
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    if (h > 0) return `Uptime ${h}h ${m}m`;
    return `Uptime ${m}m`;
  }

  const fmt = (value) => {
    const n = Number(value);
    if (Number.isNaN(n)) return '$0';
    return '$' + new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format(n);
  };

  const setVisible = (show) => {
    root.classList.toggle('pd-hidden', !show);
  };

  window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || typeof d !== 'object') return;

    if (d.action === 'phantomVoice') {
      els.voice.classList.toggle('pd-talking', !!d.talking);
      if (d.voiceLabel) els.voiceLabel.textContent = d.voiceLabel;
      return;
    }

    if (d.action !== 'phantomDashboard') return;

    if (d.visible !== undefined) setVisible(!!d.visible);

    if (d.serverName !== undefined) els.serverName.textContent = d.serverName || 'Phantom World';
    if (d.serverTime !== undefined) els.time.textContent = d.serverTime || '—';
    if (d.playerId !== undefined) els.id.textContent = 'ID ' + d.playerId;
    if (d.playerName !== undefined) els.name.textContent = d.playerName || 'Player';
    if (d.gang !== undefined) els.gang.textContent = d.gang || '—';
    if (d.street !== undefined) els.street.textContent = d.street || '—';
    if (d.cash !== undefined) els.cash.textContent = fmt(d.cash);
    if (d.bank !== undefined) els.bank.textContent = fmt(d.bank);
    if (d.rank !== undefined) els.rank.textContent = String(d.rank);
    if (d.job !== undefined) els.job.textContent = d.job || '—';

    if (d.showGang === false) els.gang.style.display = 'none';
    if (d.showStreet === false) els.street.style.display = 'none';
    if (d.showMoney === false) els.money.style.display = 'none';
    if (d.showVoice === false) els.voice.style.display = 'none';

    if (d.showRank === false) els.rankWrap.style.display = 'none';
    else els.rankWrap.style.display = '';

    if (d.showJob === false) els.jobWrap.style.display = 'none';
    else els.jobWrap.style.display = '';

    if (d.uptimeSeconds !== undefined && els.uptime) {
      els.uptime.textContent = formatUptime(d.uptimeSeconds);
    }

    if (d.playerCount !== undefined && d.maxPlayers !== undefined) {
      els.players.textContent = d.playerCount + '/' + d.maxPlayers + ' online';
    }
  });
})();
