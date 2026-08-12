const root = document.getElementById('root');

function post(action, data) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

function setTab(name) {
  document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('active', p.id === `panel-${name}`));
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') root.classList.remove('hidden');
  if (data.action === 'close') root.classList.add('hidden');
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    root.classList.add('hidden');
    post('close');
  }
});

document.getElementById('tabs').addEventListener('click', (e) => {
  const tab = e.target.closest('.tab');
  if (!tab) return;
  setTab(tab.dataset.tab);
});

document.addEventListener('click', (e) => {
  const btn = e.target.closest('[data-action]');
  if (!btn) return;
  const action = btn.dataset.action;
  if (action === 'close') {
    root.classList.add('hidden');
    post('close');
    return;
  }
  if (action === 'jobs_set') {
    post(action, { job: btn.dataset.job });
    return;
  }
  post(action);
});
