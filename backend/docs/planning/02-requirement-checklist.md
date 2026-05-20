# Requirement Checklist Proyek Akhir

## A. Checklist Kepatuhan Requirement Dosen

| No  | Requirement                                                                    | Target Proyek                                  | Status Planning | Bukti yang Harus Disiapkan                       |
| --- | ------------------------------------------------------------------------------ | ---------------------------------------------- | --------------- | ------------------------------------------------ |
| 1   | Web service REST API CRUD, deploy Cloud Run atau App Engine, minimal 3 service | 3 microservice backend + frontend web          | Planned         | URL service Cloud Run + dokumentasi endpoint     |
| 2   | Database deploy di GCE atau Cloud SQL                                          | Cloud SQL untuk data relasional                | Planned         | Screenshot instance Cloud SQL + koneksi aplikasi |
| 3   | Tech stack bebas (kecuali db)                                                  | Express.js Node.js + Flutter + Firestore + GCS | Planned         | Daftar stack di laporan                          |
| 4   | Endpoint API minimal 15                                                        | Target 18 endpoint                             | Planned         | Daftar endpoint + Swagger                        |
| 5   | Tabel pada kedua database minimal 5                                            | SQL 5 tabel, Firestore 5 collection            | Planned         | ERD SQL + list collection Firestore              |
| 6   | Laporan akhir sesuai template                                                  | Disiapkan pada phase dokumentasi final         | Planned         | Dokumen laporan final                            |

## B. Checklist Fitur Inti Smart Inventory

| Fitur                       | Wajib | Strategi                                                   |
| --------------------------- | ----- | ---------------------------------------------------------- |
| Scan barcode masuk keluar   | Ya    | Endpoint transactions dan item lookup by barcode           |
| Alert stok menipis          | Ya    | Trigger saat transaksi keluar jika stok akhir <= min_stock |
| Foto produk tersimpan cloud | Ya    | Upload ke GCS lalu URL disimpan di SQL                     |
| Log aktivitas user          | Ya    | Simpan ke Firestore user_activity_logs                     |
| Dashboard analitik owner    | Ya    | Endpoint analytics summary + low stock alerts              |

## C. Checklist Endpoint Minimal

### Auth

- POST /auth/register
- POST /auth/login
- GET /auth/profile

### Suppliers

- GET /suppliers
- POST /suppliers
- PUT /suppliers/:id
- DELETE /suppliers/:id

### Items

- GET /items
- GET /items/:id
- GET /items/barcode/:barcode
- POST /items
- PUT /items/:id
- DELETE /items/:id

### Transactions

- POST /transactions/in
- POST /transactions/out
- GET /transactions/history

### Intelligence

- GET /analytics/summary
- GET /alerts/low-stock

## D. Checklist Bukti Demo Saat Presentasi

1. Login berhasil dan token JWT diterima.
2. Tambah item dengan foto, URL gambar tersimpan.
3. Transaksi keluar menurunkan stok.
4. Saat stok lewat ambang minimum, notifikasi low stock muncul di Firestore.
5. Dashboard web menampilkan ringkasan analitik.
6. Swagger endpoint dapat diakses untuk tiap service.
