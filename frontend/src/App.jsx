import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [health, setHealth] = useState('');

  const API_URL = import.meta.env.VITE_API_URL;

  const fetchUsers = async () => {
    const res = await fetch(`${API_URL}/api/users`);
    const data = await res.json();
    setUsers(data);
  };

  const addUser = async (e) => {
    e.preventDefault();
    await fetch(`${API_URL}/api/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email })
    });
    setName('');
    setEmail('');
    fetchUsers();
  };

  useEffect(() => {
      // Check backend health
    fetch(`${API_URL}/api/health`)
      .then(res => res.json())
      .then(data => setHealth(data.status))
      .catch(err => setHealth('Backend unavailable'));

    // Fetch users
    fetchUsers();
  }, []);

  return (
    <div className="App">
      <h1>User Manager Details[List]</h1>
      <form onSubmit={addUser}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" required />
        <br></br>
        <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" required />
                <br></br>
        <button type="submit">Add</button>
      </form>
      <ul>
        {users.map(user => <li key={user._id}>{user.name} - {user.email}</li>)}
      </ul>
    </div>
  );
}

export default App;
