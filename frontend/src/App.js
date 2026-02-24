import { useState } from 'react';
import {
  createItem,
  deleteItem,
  fetchHealth,
  fetchItems,
  fetchVersion,
  sendEcho
} from './api/api';

function App() {
  const [health, setHealth] = useState(null);
  const [version, setVersion] = useState(null);
  const [echoText, setEchoText] = useState('hello package');
  const [echoResult, setEchoResult] = useState(null);
  const [itemName, setItemName] = useState('sample-item');
  const [items, setItems] = useState([]);
  const [error, setError] = useState('');

  async function onRefreshHealth() {
    setError('');
    try {
      const [healthData, versionData] = await Promise.all([
        fetchHealth(),
        fetchVersion()
      ]);
      setHealth(healthData);
      setVersion(versionData);
    } catch (err) {
      setError(err.message);
    }
  }

  async function onSendEcho() {
    setError('');
    try {
      const result = await sendEcho(echoText);
      setEchoResult(result);
    } catch (err) {
      setError(err.message);
    }
  }

  async function onLoadItems() {
    setError('');
    try {
      const result = await fetchItems();
      setItems(result.items || []);
    } catch (err) {
      setError(err.message);
    }
  }

  async function onCreateItem() {
    setError('');
    try {
      await createItem(itemName);
      await onLoadItems();
    } catch (err) {
      setError(err.message);
    }
  }

  async function onDeleteItem(id) {
    setError('');
    try {
      await deleteItem(id);
      await onLoadItems();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <main style={{ fontFamily: 'Arial, sans-serif', margin: '2rem', maxWidth: 900 }}>
      <h1>Package Dashboard</h1>
      <p>Frontend + backend package integration test application.</p>

      <section style={{ marginTop: '1.5rem' }}>
        <button onClick={onRefreshHealth}>Refresh Health</button>
        {health && (
          <pre aria-label="health-response" style={{ background: '#f4f4f4', padding: '0.75rem' }}>
            {JSON.stringify({ health, version }, null, 2)}
          </pre>
        )}
      </section>

      <section style={{ marginTop: '1.5rem' }}>
        <h2>Echo</h2>
        <input
          aria-label="echo-input"
          value={echoText}
          onChange={(e) => setEchoText(e.target.value)}
        />
        <button onClick={onSendEcho} style={{ marginLeft: '0.5rem' }}>Send Echo</button>
        {echoResult && (
          <pre aria-label="echo-response" style={{ background: '#f4f4f4', padding: '0.75rem' }}>
            {JSON.stringify(echoResult, null, 2)}
          </pre>
        )}
      </section>

      <section style={{ marginTop: '1.5rem' }}>
        <h2>Items</h2>
        <input
          aria-label="item-input"
          value={itemName}
          onChange={(e) => setItemName(e.target.value)}
        />
        <button onClick={onCreateItem} style={{ marginLeft: '0.5rem' }}>Create Item</button>
        <button onClick={onLoadItems} style={{ marginLeft: '0.5rem' }}>Load Items</button>
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              {item.name}
              <button onClick={() => onDeleteItem(item.id)} style={{ marginLeft: '0.5rem' }}>
                Delete
              </button>
            </li>
          ))}
        </ul>
      </section>

      {error && <p role="alert" style={{ color: '#b00020' }}>{error}</p>}
    </main>
  );
}

export default App;
