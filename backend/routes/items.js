const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');
const { BASE_URL, UPLOAD_DIR } = require('../config');

const router = express.Router();
router.use(authenticateToken);

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const safeName = `${Date.now()}-${file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
    cb(null, safeName);
  }
});

const upload = multer({ storage });

router.get('/', (req, res) => {
  const query = `SELECT items.*, categories.category_name AS category_name, suppliers.name AS supplier_name
    FROM items
    LEFT JOIN categories ON items.category_id = categories.id
    LEFT JOIN suppliers ON items.supplier_id = suppliers.id
    ORDER BY items.id DESC`;
  db.all(query, [], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch items.' });
    res.json(rows);
  });
});

router.get('/:id', (req, res) => {
  const { id } = req.params;
  const field = Number.isNaN(Number(id)) ? 'barcode' : 'items.id';
  const query = `SELECT items.*, categories.category_name AS category_name, suppliers.name AS supplier_name
    FROM items
    LEFT JOIN categories ON items.category_id = categories.id
    LEFT JOIN suppliers ON items.supplier_id = suppliers.id
    WHERE ${field} = ?`;
  db.get(query, [id], (err, row) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch item.' });
    if (!row) return res.status(404).json({ error: 'Item not found.' });
    res.json(row);
  });
});

router.post('/', upload.single('image'), (req, res) => {
  const { name, barcode, price, stock, min_stock, category_id, supplier_id } = req.body;
  if (!name || !barcode || !price) {
    return res.status(400).json({ error: 'Name, barcode, and price are required.' });
  }

  const imageUrl = req.file ? `${BASE_URL}/uploads/${req.file.filename}` : '';
  const query = 'INSERT INTO items (barcode, name, price, stock, min_stock, category_id, supplier_id, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
  db.run(query, [barcode, name, price, stock || 0, min_stock || 0, category_id || null, supplier_id || null, imageUrl], function (err) {
    if (err) return res.status(500).json({ error: 'Failed to create item.' });
    res.status(201).json({ id: this.lastID, barcode, name, price: Number(price), stock: Number(stock || 0), min_stock: Number(min_stock || 0), category_id, supplier_id, image_url: imageUrl });
  });
});

router.put('/:id', upload.single('image'), (req, res) => {
  const { id } = req.params;
  const { barcode, name, price, stock, min_stock, category_id, supplier_id } = req.body;

  db.get('SELECT image_url FROM items WHERE id = ?', [id], (err, existing) => {
    if (err) return res.status(500).json({ error: 'Failed to query item.' });
    if (!existing) return res.status(404).json({ error: 'Item not found.' });

    let imageUrl = existing.image_url;
    if (req.file) {
      if (imageUrl) {
        const existingPath = path.join(__dirname, '..', imageUrl.replace(`${BASE_URL}/`, ''));
        if (fs.existsSync(existingPath)) fs.unlinkSync(existingPath);
      }
      imageUrl = `${BASE_URL}/uploads/${req.file.filename}`;
    }

    const query = 'UPDATE items SET barcode = ?, name = ?, price = ?, stock = ?, min_stock = ?, category_id = ?, supplier_id = ?, image_url = ? WHERE id = ?';
    db.run(query, [barcode, name, price, stock, min_stock, category_id, supplier_id, imageUrl, id], function (err2) {
      if (err2) return res.status(500).json({ error: 'Failed to update item.' });
      if (this.changes === 0) return res.status(404).json({ error: 'Item not found.' });
      res.json({ id: Number(id), barcode, name, price: Number(price), stock: Number(stock), min_stock: Number(min_stock), category_id, supplier_id, image_url: imageUrl });
    });
  });
});

router.delete('/:id', (req, res) => {
  const { id } = req.params;
  db.get('SELECT image_url FROM items WHERE id = ?', [id], (err, row) => {
    if (err) return res.status(500).json({ error: 'Failed to query item.' });
    if (!row) return res.status(404).json({ error: 'Item not found.' });
    if (row.image_url) {
      const existingPath = path.join(__dirname, '..', row.image_url.replace(`${BASE_URL}/`, ''));
      if (fs.existsSync(existingPath)) fs.unlinkSync(existingPath);
    }

    db.run('DELETE FROM items WHERE id = ?', [id], function (err2) {
      if (err2) return res.status(500).json({ error: 'Failed to delete item.' });
      res.json({ message: 'Item removed.' });
    });
  });
});

module.exports = router;
