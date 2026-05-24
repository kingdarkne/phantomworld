window.addEventListener('message', function (event) {
  const data = event.data || {};
  const setText = (id, value) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = value;
  };

  const setHidden = (id, hidden) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.toggle('is-hidden', !!hidden);
  };

  const setRootHidden = (hidden) => {
    const root = document.getElementById('hud-root');
    if (!root) return;
    root.classList.toggle('is-hidden', !!hidden);
  };

  const pulse = (id) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.add('pulse');
    window.setTimeout(() => el.classList.remove('pulse'), 220);
  };

  const applyCommon = () => {
    if (data.serverName) setText('serverName', String(data.serverName));
    if (data.playerId !== undefined) setText('playerId', 'ID ' + String(data.playerId));
    if (data.serverTime) setText('serverTime', String(data.serverTime));
    if (data.playerName) setText('playerName', String(data.playerName));
    if (data.playerGang) setText('playerGang', String(data.playerGang));
    if (data.playerStreet) setText('playerStreet', String(data.playerStreet));
  };

  if (data.action === 'hudConfig') {
    setHidden('rankStat', data.showRank === false);
    setHidden('jobStat', data.showJob === false);
    return;
  }

  if (data.action === 'setVisible') {
    setRootHidden(data.visible === false);
    return;
  }

  if (data.action === 'voiceUpdate') {
    const widget = document.getElementById('voiceWidget');
    if (widget) widget.classList.toggle('is-talking', !!data.talking);

    const prox = data.proximity || {};
    const mode = prox.mode ? String(prox.mode) : 'VOICE';
    const dist = typeof prox.distance === 'number' ? prox.distance : null;
    const label = dist ? `${mode} ${Math.round(dist)}m` : mode;
    setText('voiceMode', label);
    return;
  }

  if (data.action === 'updateServerInfo') {
    applyCommon();
    return;
  }

  if (data.action === 'updateHUD') {
    applyCommon();

    if (typeof data.cash === 'number') {
      setText('cash', '$' + data.cash.toLocaleString());
      pulse('cash');
    }
    if (typeof data.bank === 'number') {
      setText('bank', '$' + data.bank.toLocaleString());
      pulse('bank');
    }
    if (data.rank !== undefined) {
      setText('rank', String(data.rank));
      pulse('rank');
    }
    if (data.job) {
      setText('job', String(data.job));
      pulse('job');
    }
  }
});

