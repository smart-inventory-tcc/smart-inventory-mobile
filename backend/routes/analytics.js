const express = require('express');
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

router.get('/summary', (req, res) => {
  const stats = {};

  db.get('SELECT COUNT(*) AS count FROM items', [], (err, itemsRow) => {
    if (err) return res.status(500).json({ error: 'Failed to count items.' });
    stats.items = itemsRow.count;
    db.get('SELECT COUNT(*) AS count FROM suppliers', [], (err2, suppliersRow) => {
      if (err2) return res.status(500).json({ error: 'Failed to count suppliers.' });
      stats.suppliers = suppliersRow.count;
      db.get('SELECT COUNT(*) AS count FROM stock_transactions', [], (err3, txRow) => {
        if (err3) return res.status(500).json({ error: 'Failed to count transactions.' });
        stats.transactions = txRow.count;
        db.all('SELECT id, name, stock, min_stock FROM items WHERE stock <= min_stock ORDER BY stock ASC LIMIT 10', [], (err4, lowRows) => {
          if (err4) return res.status(500).json({ error: 'Failed to fetch low stock items.' });
          stats.lowStock = lowRows;
          res.json(stats);
        });
      });
    });
  });
});

module.exports = router;
