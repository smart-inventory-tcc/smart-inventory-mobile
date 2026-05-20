Kunci kontrak API dulu (wajib sebelum coding).

Buat OpenAPI untuk semua endpoint backend yang sudah disepakati.

Hasil akhir tahap ini: tim web dan mobile bisa mulai integrasi tanpa nunggu backend selesai 100%.

Finalkan skema database.

SQL: users, suppliers, categories, items, stock_transactions.

Firestore: notifications, user_activity_logs, stock_alerts_history, temp_scan_sessions, system_config.

Hasil akhir: migration SQL + definisi field Firestore yang konsisten.

Scaffold 3 service backend.

Service A: auth + suppliers.

Service B: items + transactions + upload GCS.

Service C: analytics + alerts.

Setup wajib di tiap service: JWT middleware, validation, error handler, logging, Swagger endpoint.

Implement endpoint prioritas tinggi.

Mulai dari alur kritis:

auth login/register/profile

items CRUD

transactions in/out + history

analytics summary + low-stock alerts

Implement smart logic stok menipis.

Di transaksi keluar:

validasi stok

update stok dan simpan histori dalam SQL transaction

kalau stok akhir <= min_stock, tulis ke Firestore notifications dan stock_alerts_history

Tambah hardening backend.

Parameterized query semua akses SQL.

Standard response error 400/401/403/404/409/500.

Pastikan route terproteksi benar-benar reject token invalid.

Test yang wajib ada.

Unit test service logic transaksi.

Integration test minimal:

transaksi out normal

transaksi out memicu low stock alert

upload foto item gagal dan handling error

Siapkan bukti untuk dosen dari backend side.

Swagger hidup.

Bukti endpoint minimal 15 (kalian target 18).

Bukti trigger low-stock end-to-end.

Bukti SQL 5 tabel + Firestore 5 collection terpakai.