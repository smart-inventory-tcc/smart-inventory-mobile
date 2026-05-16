const express = require('express');
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

router.get('/', (req, res) => {
  db.all('SELECT * FROM suppliers ORDER BY id DESC', [], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch suppliers.' });
    res.json(rows);
  });
});

router.post('/', (req, res) => {
  const { name, phone, address, email } = req.body;
  if (!name) return res.status(400).json({ error: 'Supplier name is required.' });

  const query = 'INSERT INTO suppliers (name, phone, address, email) VALUES (?, ?, ?, ?)';
  db.run(query, [name, phone || '', address || '', email || ''], function (err) {
    if (err) return res.status(500).json({ error: 'Failed to add supplier.' });
    res.status(201).json({ id: this.lastID, name, phone, address, email });
  });
});

router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { name, phone, address, email } = req.body;
  const query = 'UPDATE suppliers SET name = ?, phone = ?, address = ?, email = ? WHERE id = ?';
  db.run(query, [name, phone, address, email, id], function (err) {
    if (err) return res.status(500).json({ error: 'Failed to update supplier.' });
    if (this.changes === 0) return res.status(404).json({ error: 'Supplier not found.' });
    res.json({ id: Number(id), name, phone, address, email });
  });
});

router.delete('/:id', (req, res) => {
  const { id } = req.params;
  db.run('DELETE FROM suppliers WHERE id = ?', [id], function (err) {
    if (err) return res.status(500).json({ error: 'Failed to delete supplier.' });
    if (this.changes === 0) return res.status(404).json({ error: 'Supplier not found.' });
    res.json({ message: 'Supplier removed.' });
  });
});

module.exports = router;
