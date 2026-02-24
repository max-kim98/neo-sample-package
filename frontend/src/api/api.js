async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    },
    ...options
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = data.error || `request failed: ${response.status}`;
    throw new Error(message);
  }

  return data;
}

export function fetchHealth() {
  return request('/api/health');
}

export function fetchVersion() {
  return request('/api/version');
}

export function sendEcho(message) {
  return request('/api/echo', {
    method: 'POST',
    body: JSON.stringify({ message })
  });
}

export function fetchItems() {
  return request('/api/items');
}

export function createItem(name) {
  return request('/api/items', {
    method: 'POST',
    body: JSON.stringify({ name })
  });
}

export function deleteItem(id) {
  return request(`/api/items/${id}`, {
    method: 'DELETE'
  });
}
