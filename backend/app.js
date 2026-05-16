const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { PORT, UPLOAD_DIR } = require('./config');

const authRoutes = require('./routes/auth');
const supplierRoutes = require('./routes/suppliers');
const itemRoutes = require('./routes/items');
const transactionRoutes = require('./routes/transactions');
const analyticsRoutes = require('./routes/analytics');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
app.use('/uploads', express.static(path.join(__dirname, UPLOAD_DIR)));

app.use('/auth', authRoutes);
app.use('/suppliers', supplierRoutes);
app.use('/items', itemRoutes);
app.use('/transactions', transactionRoutes);
app.use('/analytics', analyticsRoutes);

app.get('/', (req, res) => {
  res.send({ message: 'Smart Inventory UMKM backend is running.', frontendMobile: 'Use /auth, /items, /suppliers, /transactions, /analytics' });
});

app.listen(PORT, () => {
  console.log(`Smart Inventory UMKM backend listening on http://localhost:${PORT}`);
});
