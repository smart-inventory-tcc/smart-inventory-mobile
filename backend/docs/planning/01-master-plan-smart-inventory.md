# Master Plan Smart Inventory UMKM

## 1. Tujuan Proyek

Membangun sistem Smart Inventory UMKM berbasis cloud dengan fokus:

- Pencatatan stok masuk dan keluar yang akurat.
- Peringatan stok menipis secara real-time.
- Integrasi media foto barang ke Google Cloud Storage.
- Dukungan Web Owner dan Mobile Pegawai (scan barcode).

## 2. Scope Wajib

- Arsitektur minimal 3 service dan deploy di Cloud Run.
- REST API dengan CRUD dan total endpoint minimal 15.
- SQL Cloud SQL minimal 5 tabel.
- NoSQL Firestore minimal 5 collection.
- Swagger API docs aktif pada setiap service.
- Bukti laporan final sesuai template dosen.

## 3. Arsitektur Service

### Service A: Identity and Supplier

Tanggung jawab:

- Autentikasi user.
- Otorisasi berbasis JWT.
- CRUD supplier.

Endpoint target:

- POST /auth/register
- POST /auth/login
- GET /auth/profile
- GET /suppliers
- POST /suppliers
- PUT /suppliers/:id
- DELETE /suppliers/:id

### Service B: Core Inventory and Storage

Tanggung jawab:

- CRUD barang.
- Transaksi stok masuk dan keluar.
- Upload foto barang ke GCS dan simpan URL di SQL.

Endpoint target:

- GET /items
- GET /items/:id
- GET /items/barcode/:barcode
- POST /items
- PUT /items/:id
- DELETE /items/:id
- POST /transactions/in
- POST /transactions/out
- GET /transactions/history

### Service C: Intelligence and Notifications

Tanggung jawab:

- Ringkasan dashboard analitik.
- Feed peringatan stok menipis untuk web.
- Konsolidasi data alert historis.

Endpoint target:

- GET /analytics/summary
- GET /alerts/low-stock

Total endpoint target saat ini: 18 endpoint.

## 4. Desain Data

### SQL Cloud SQL (5 tabel wajib)

1. users
2. suppliers
3. categories
4. items
5. stock_transactions

Kolom penting yang wajib ada:

- items.min_stock (default 10)
- items.barcode (unique)
- items.image_url (link GCS)

### NoSQL Firestore (5 collection wajib)

1. notifications
2. user_activity_logs
3. stock_alerts_history
4. temp_scan_sessions
5. system_config

## 5. Smart Logic Kritis

Flow wajib pada transaksi keluar:

1. Validasi stok cukup.
2. Kurangi stok di SQL dalam transaction.
3. Simpan histori ke stock_transactions.
4. Jika stok akhir kurang dari atau sama dengan min_stock:
   - Tulis dokumen ke notifications.
   - Tulis histori ke stock_alerts_history.

## 6. Standar Error Handling API

- 400: Input invalid atau stok tidak cukup.
- 401: Token tidak ada atau tidak valid.
- 403: Akses role tidak sesuai.
- 404: Data tidak ditemukan.
- 409: Konflik data (contoh barcode duplikat).
- 500: Error internal server atau integrasi cloud gagal.

## 7. Deliverables Final

- 3 service berjalan di Cloud Run.
- API docs Swagger aktif di setiap service.
- Database SQL dan Firestore sesuai jumlah minimum.
- Demo skenario stok menipis berhasil memicu notifikasi.
- Laporan final dengan diagram arsitektur, ERD, mapping endpoint, dan bukti deployment.

## 8. Risiko Utama dan Mitigasi

1. Risiko: ketidakkonsistenan kontrak antar service.
   Mitigasi: kunci OpenAPI contract sebelum coding.
2. Risiko: stok ganda berkurang akibat request bersamaan.
   Mitigasi: SQL transaction dan validasi stok atomik.
3. Risiko: keterlambatan dokumentasi.
   Mitigasi: Swagger harus dibuat sejalan dengan endpoint, bukan di akhir.
4. Risiko: perubahan scope menjelang demo.
   Mitigasi: gunakan checklist requirement tunggal sebagai acuan resmi tim.
