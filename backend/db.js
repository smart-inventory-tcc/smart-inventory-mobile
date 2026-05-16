const sqlite3 = require('sqlite3').verbose();
const { DB_FILE } = require('./config');

const db = new sqlite3.Database(DB_FILE, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

module.exports = db;
