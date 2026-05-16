const express = require('express');
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

router.post('/in', (req, res) => {
  const { item_id, quantity } = req.body;
  const userId = req.user.id;
  const qty = Number(quantity || 0);
  if (!item_id || qty <= 0) {
    return res.status(400).json({ error: 'item_id and positive quantity are required.' });
  }

  db.get('SELECT * FROM items WHERE id = ?', [item_id], (err, item) => {
    if (err) return res.status(500).json({ error: 'Failed to query item.' });
    if (!item) return res.status(404).json({ error: 'Item not found.' });

    const newStock = item.stock + qty;
    db.run('UPDATE items SET stock = ? WHERE id = ?', [newStock, item_id], function (updateErr) {
      if (updateErr) return res.status(500).json({ error: 'Failed to update item stock.' });
      db.run('INSERT INTO stock_transactions (item_id, user_id, type, quantity, created_at) VALUES (?, ?, ?, ?, ?)', [item_id, userId, 'IN', qty, new Date().toISOString()], function (insertErr) {
        if (insertErr) return res.status(500).json({ error: 'Failed to record transaction.' });
        res.json({ message: 'Stock updated.', item_id, new_stock: newStock, transaction_id: this.lastID });
      });
    });
  });
});

router.post('/out', (req, res) => {
  const { item_id, quantity } = req.body;
  const userId = req.user.id;
  const qty = Number(quantity || 0);
  if (!item_id || qty <= 0) {
    return res.status(400).json({ error: 'item_id and positive quantity are required.' });
  }

  db.get('SELECT * FROM items WHERE id = ?', [item_id], (err, item) => {
    if (err) return res.status(500).json({ error: 'Failed to query item.' });
    if (!item) return res.status(404).json({ error: 'Item not found.' });
    const newStock = item.stock - qty;
    if (newStock < 0) {
      return res.status(400).json({ error: 'Not enough stock to complete the transaction.' });
    }

    db.run('UPDATE items SET stock = ? WHERE id = ?', [newStock, item_id], function (updateErr) {
      if (updateErr) return res.status(500).json({ error: 'Failed to update item stock.' });
      db.run('INSERT INTO stock_transactions (item_id, user_id, type, quantity, created_at) VALUES (?, ?, ?, ?, ?)', [item_id, userId, 'OUT', qty, new Date().toISOString()], function (insertErr) {
        if (insertErr) return res.status(500).json({ error: 'Failed to record transaction.' });
        const alert = newStock <= item.min_stock;
        res.json({ message: 'Stock updated.', item_id, new_stock: newStock, alert, transaction_id: this.lastID });
      });
    });
  });
});

router.get('/history', (req, res) => {
  const query = `SELECT t.id, t.item_id, items.name AS item_name, t.user_id, u.username AS user_name, t.type, t.quantity, t.created_at
    FROM stock_transactions AS t
    LEFT JOIN items ON t.item_id = items.id
    LEFT JOIN users AS u ON t.user_id = u.id
    ORDER BY t.created_at DESC LIMIT 200`;
  db.all(query, [], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch transaction history.' });
    res.json(rows);
  });
});

module.exports = router;
