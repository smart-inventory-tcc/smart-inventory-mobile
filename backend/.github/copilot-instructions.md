# Copilot Instructions - Smart Inventory UMKM

## 0. Project Final Requirements (Tugas Akhir)
Bagian ini adalah pemetaan mutlak (mapping) dari syarat tugas akhir agar AI (Copilot) selalu menjaga batas minimal project:
- **Arsitektur:** Web Service REST API dengan kemampuan CRUD.
- **Service & Deployment:** Pilihan service App Engine / Cloud Run dengan minimal 3 service (Frontend wajib, Autentikasi, CRUD Barang, CRUD Supplier, dll). Terhubung ke Cloud Storage. *(Di project ini: 3 Backend Microservices di Cloud Run + 1 Frontend).*
- **Database:** Deploy dengan GCE atau Cloud SQL. *(Di project ini: Cloud SQL & Firestore).*
- **Tech Stack:** Bebas (Node Js, Express, dll). *(Di project ini: Node.js + Express).*
- **Endpoint API:** Minimal 15 endpoint (create, read, update, delete dihitung 4).
- **Tabel Database:** Minimal 5 tabel pada kedua database.
- **Laporan:** Harus sesuai template.

## 1. Project Context

Proyek ini adalah sistem **Smart Inventory UMKM** berbasis cloud.
- **Topik Inti:** Pencatatan stok keluar masuk dengan sistem peringatan stok menipis.
- **Masalah yang Diselesaikan:** Ketidaksesuaian stok fisik dan sistem, serta risiko kehabisan barang.
- **Platform:** 
  - *Web (Owner):* Analitik Penjualan, Manajemen Supplier.
  - *Mobile (Pegawai):* Scan Barcode Masuk/Keluar.
- **Penggunaan SQL:** Menyimpan data barang, supplier, stok masuk-keluar, transaksi penjualan, dan laporan inventori.
- **Penggunaan NoSQL:** Menyimpan cache stok cepat, notifikasi stok menipis, scan barcode sementara, dan log aktivitas mobile.

- Arsitektur wajib: 3 microservices backend terpisah.
- Platform deploy: Google Cloud Run.
- Database: Cloud SQL (relasional) + Firestore (NoSQL).
- Object storage: Google Cloud Storage (GCS) untuk file gambar.

Gunakan instruksi ini sebagai sumber aturan utama saat menghasilkan kode, dokumentasi, test, dan refactor.

## 2. Non-Negotiable Requirements

Semua output Copilot harus menjaga syarat berikut:

1. Minimal 15 endpoint API aktif (target saat ini: 18).
2. SQL minimal 5 tabel inti.
3. Firestore minimal 5 collection inti.
4. Semua endpoint baru wajib masuk Swagger/OpenAPI.
5. Route terproteksi wajib JWT middleware.
6. Logic alert stok menipis wajib berjalan di backend transaksi keluar.

Jika ada usulan yang melanggar poin di atas, tolak usulan tersebut dan berikan alternatif yang sesuai.

## 3. Service Boundaries

### Service A - Identity and Supplier

Scope:

- Auth: register, login, profile.
- CRUD supplier.

Endpoint minimum:

- POST /auth/register
- POST /auth/login
- GET /auth/profile
- GET /suppliers
- POST /suppliers
- PUT /suppliers/:id
- DELETE /suppliers/:id

### Service B - Inventory and Storage

Scope:

- CRUD items.
- Transaksi stok masuk/keluar.
- Upload gambar item ke GCS.

Endpoint minimum:

- GET /items
- GET /items/:id
- GET /items/barcode/:barcode
- POST /items
- PUT /items/:id
- DELETE /items/:id
- POST /transactions/in
- POST /transactions/out
- GET /transactions/history

### Service C - Intelligence and Notifications

Scope:

- Ringkasan analitik dashboard.
- Feed low-stock alert.

Endpoint minimum:

- GET /analytics/summary
- GET /alerts/low-stock

## 4. Data Model Rules

### SQL (Cloud SQL)

Tabel minimum:

- users
- suppliers
- categories
- items
- stock_transactions

Kolom penting yang wajib ada:

- items.barcode harus unique.
- items.min_stock wajib tersedia (default 10 direkomendasikan).
- items.image_url menyimpan URL file di GCS.

Relasi inti:

- items.category_id -> categories.id
- items.supplier_id -> suppliers.id
- stock_transactions.item_id -> items.id
- stock_transactions.user_id -> users.id

### Firestore (NoSQL)

Collection minimum:

- notifications
- user_activity_logs
- stock_alerts_history
- temp_scan_sessions
- system_config

## 5. Smart Logic Rules

Pada POST /transactions/out, urutan wajib:

1. Validasi JWT dan payload.
2. Validasi stok cukup.
3. Kurangi stok dengan SQL transaction (atomic).
4. Simpan histori ke stock_transactions (type: OUT).
5. Jika stock akhir <= min_stock:
   - tulis dokumen ke notifications,
   - tulis dokumen ke stock_alerts_history.

Jangan implementasikan transaksi keluar yang hanya menolak saat stok 0 tanpa low-stock trigger.

## 6. Security and API Standards

- Wajib pakai parameterized query (anti SQL injection).
- Jangan simpan secret hardcoded di source code.
- Wajib gunakan status code yang konsisten:
  - 400 bad request atau stok tidak cukup
  - 401 unauthorized
  - 403 forbidden
  - 404 not found
  - 409 conflict (misal barcode duplikat)
  - 500 internal error
- Return payload error harus konsisten dan mudah di-debug.

## 7. Code Style and Quality

- Gunakan nama variabel jelas dengan camelCase.
- Hindari breaking change pada API lama tanpa alasan jelas.
- Tambahkan komentar singkat hanya saat logic tidak langsung jelas.
- Prioritaskan code yang mudah diuji dan mudah dibaca tim.

## 8. Documentation Rules

- Setiap endpoint baru atau perubahan contract wajib update Swagger/OpenAPI.
- Dokumentasi harus memuat request body, response, dan kemungkinan error.
- Diagram arsitektur/ERD/flow harus konsisten dengan implementasi aktual.

## 9. Deployment Rules

- Target deployment utama: Cloud Run untuk semua service.
- Konfigurasi environment lewat env var atau Secret Manager.
- Pastikan konektivitas ke Cloud SQL, Firestore, dan GCS tervalidasi sebelum demo.

## 10. Definition of Done for Copilot Outputs

Sebuah task dianggap selesai jika:

1. Perubahan kode mengikuti boundary service yang benar.
2. Security baseline terpenuhi (JWT + parameterized query).
3. Swagger/OpenAPI ikut ter-update.
4. Tidak menurunkan requirement minimal endpoint dan database.
5. Untuk fitur stok keluar, low-stock alert teruji secara logika.

## 11. Build and Verification Checklist

- Jalankan dependency install sebelum development.
- Verifikasi environment variables koneksi Cloud SQL/Firestore/GCS.
- Lakukan test minimal untuk happy path dan error path utama.
