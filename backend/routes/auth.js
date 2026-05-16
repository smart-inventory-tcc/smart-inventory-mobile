const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { JWT_SECRET } = require('../config');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.post('/register', (req, res) => {
  const { username, password, role = 'Staff', name = null, email = null } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required.' });
  }
  if (email && !/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
    return res.status(400).json({ error: 'Invalid email address.' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });
  }

  const hashedPassword = bcrypt.hashSync(password, 10);
  const createdAt = new Date().toISOString();

  const query = 'INSERT INTO users (username, name, email, password, role, created_at) VALUES (?, ?, ?, ?, ?, ?)';
  db.run(query, [username, name, email, hashedPassword, role, createdAt], function (err) {
    if (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        return res.status(409).json({ error: 'Username already exists.' });
      }
      return res.status(500).json({ error: 'Could not create user.' });
    }
    res.status(201).json({ id: this.lastID, username, name, email, role, created_at: createdAt });
  });
});

router.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required.' });
  }

  db.get('SELECT * FROM users WHERE username = ?', [username], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to query user.' });
    }
    if (!row || !bcrypt.compareSync(password, row.password)) {
      return res.status(401).json({ error: 'Invalid username or password.' });
    }

    const token = jwt.sign({ id: row.id, username: row.username, role: row.role }, JWT_SECRET, {
      expiresIn: '12h'
    });
    res.json({ token, user: { id: row.id, username: row.username, name: row.name, email: row.email, role: row.role } });
  });
});

router.get('/profile', authenticateToken, (req, res) => {
  db.get('SELECT id, username, name, email, role, created_at FROM users WHERE id = ?', [req.user.id], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to read profile.' });
    }
    if (!row) {
      return res.status(404).json({ error: 'User not found.' });
    }
    res.json(row);
  });
});

module.exports = router;
