# Smart Inventory UMKM Backend

Local backend for Smart Inventory UMKM with Express and SQLite.

## Fitur utama
- Auth: `POST /auth/register`, `POST /auth/login`, `GET /auth/profile`
- Items: CRUD dengan upload foto lokal
- Suppliers: CRUD
- Transactions: `POST /transactions/in`, `POST /transactions/out`, `GET /transactions/history`
- Analytics: `GET /analytics/summary`

## Setup lokal
1. Buka terminal
2. Masuk ke folder backend:
   ```powershell
   cd "d:\hafid\Semester 6\prak_tcc\inventaris-umkm\backend"
   ```
3. Install dependensi:
   ```powershell
   npm install
   ```
4. Inisialisasi database:
   ```powershell
   npm run init-db
   ```
5. Jalankan server:
   ```powershell
   npm start
   ```

Server akan berjalan di `http://localhost:3000`.

## Catatan testing
- Default user: `owner`, password: `password123`
- Upload foto item disimpan di folder `uploads/`
- API akan melayani `GET /items`, `POST /items`, `PUT /items/:id`, `DELETE /items/:id`

## Konversi ke backend nyata
Untuk koneksi ke Cloud SQL dan GCS di masa depan:
- `db.js` dapat diganti dengan driver MySQL atau PostgreSQL
- upload file `routes/items.js` dapat diganti dengan upload ke GCS
- `middleware/auth.js` dan JWT tidak perlu diubah
