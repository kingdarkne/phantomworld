const root = document.getElementById('call');
const nameEl = document.getElementById('name');
const titleEl = document.getElementById('title');
const blurbEl = document.getElementById('blurb');
const timerEl = document.getElementById('timer');
let timer = null;

function post(name) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: '{}',
  });
}

document.getElementById('accept').addEventListener('click', () => post('accept'));
document.getElementById('decline').addEventListener('click', () => post('decline'));

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'incoming') {
    nameEl.textContent = data.name || 'Unknown';
    titleEl.textContent = data.title || 'Incoming contract';
    blurbEl.textContent = data.blurb || '';
    root.classList.remove('hidden');
    let left = data.ringSeconds || 12;
    timerEl.textContent = `Auto-decline in ${left}s`;
    clearInterval(timer);
    timer = setInterval(() => {
      left -= 1;
      timerEl.textContent = `Auto-decline in ${Math.max(left, 0)}s`;
      if (left <= 0) clearInterval(timer);
    }, 1000);
  }
  if (data.action === 'hide') {
    root.classList.add('hidden');
    clearInterval(timer);
  }
});
