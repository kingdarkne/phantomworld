const root = document.getElementById('root');

function post(action, data) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

window.addEventListener('message', function (event) {
  const data = event.data || {};
  if (data.action === 'open') {
    root.classList.remove('hidden');
  } else if (data.action === 'close') {
    root.classList.add('hidden');
  }
});

document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') {
    root.classList.add('hidden');
    post('close');
  }
});

document.addEventListener('click', function (e) {
  const btn = e.target.closest('button[data-action]');
  if (!btn) return;
  const action = btn.dataset.action;
  if (!action) return;

  if (action === 'jobs_set') {
    const job = btn.dataset.job;
    post(action, { job });
  } else {
    post(action);
  }
});

