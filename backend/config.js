module.exports = {
  PORT: process.env.PORT || 3000,
  JWT_SECRET: process.env.JWT_SECRET || 'smart-inventory-secret',
  DB_FILE: process.env.DB_FILE || './inventory.db',
  UPLOAD_DIR: process.env.UPLOAD_DIR || './uploads',
  BASE_URL: process.env.BASE_URL || 'http://localhost:3000'
};
