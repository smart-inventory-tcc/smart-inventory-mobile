const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const { DB_FILE } = require('../config');

const schema = fs.readFileSync(path.join(__dirname, '..', 'database', 'schema.sql'), 'utf8');
const seed = fs.readFileSync(path.join(__dirname, '..', 'database', 'seed.sql'), 'utf8');

const db = new sqlite3.Database(DB_FILE, (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
    process.exit(1);
  }
});

const defaultPasswordHash = bcrypt.hashSync('password123', 10);

function ensureUserColumn(column, definition, callback) {
  db.get(`PRAGMA table_info(users)`, (err, row) => {
    if (err) return callback(err);
    db.all(`PRAGMA table_info(users)`, (infoErr, columns) => {
      if (infoErr) return callback(infoErr);
      const exists = columns.some((col) => col.name === column);
      if (exists) return callback(null);
      db.run(`ALTER TABLE users ADD COLUMN ${column} ${definition}`, callback);
    });
  });
}

function seedData() {
  db.run(
    "INSERT OR IGNORE INTO users (username, name, email, password, role, created_at) VALUES ('owner', 'Administrator', 'owner@example.com', ?, 'Owner', ?)",
    [defaultPasswordHash, new Date().toISOString()],
    function (insertErr) {
      if (insertErr) {
        console.error('Failed to insert default user:', insertErr.message);
        process.exit(1);
      }

      db.exec(seed, (seedErr) => {
        if (seedErr) {
          console.error('Failed to execute seed data:', seedErr.message);
          process.exit(1);
        }
        console.log('Database initialized. Default admin user: owner / password123');
        db.close();
      });
    }
  );
}

// Create tables if missing, then ensure any added columns exist before seeding.
db.exec(schema, (schemaErr) => {
  if (schemaErr) {
    console.error('Failed to create schema:', schemaErr.message);
    process.exit(1);
  }

  ensureUserColumn('name', 'TEXT', (nameErr) => {
    if (nameErr) {
      console.error('Failed to update users schema (name):', nameErr.message);
      process.exit(1);
    }
    ensureUserColumn('email', 'TEXT', (emailErr) => {
      if (emailErr) {
        console.error('Failed to update users schema (email):', emailErr.message);
        process.exit(1);
      }
      seedData();
    });
  });
});
