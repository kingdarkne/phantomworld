export function cfxJoinId() {
  return process.env.CFX_SERVER_ID || '';
}

export function joinUrl() {
  const id = cfxJoinId();
  return id ? `https://cfx.re/join/${id}` : null;
}

export function displayServerName(status) {
  return (
    process.env.PHANTOM_SERVER_NAME ||
    process.env.FIVEM_DISPLAY_NAME ||
    status?.serverName ||
    'Phantom World'
  );
}
