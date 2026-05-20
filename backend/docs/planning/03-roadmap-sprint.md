# Roadmap Sprint Smart Inventory UMKM

## Sprint 1: Foundation and Contract

Durasi: 1 minggu

Target:

- Finalisasi architecture decision 3 service.
- Finalisasi contract endpoint per service.
- Setup skeleton project, lint, env, Swagger.

Output sprint:

- Dokumen OpenAPI awal.
- Struktur folder service.
- Checklist requirement tervalidasi.

## Sprint 2: Identity and Supplier Service

Durasi: 1 minggu

Target:

- Implement auth register, login, profile.
- Implement CRUD supplier.
- Integrasi JWT middleware pada route terproteksi.
- Logging aktivitas login ke Firestore.

Output sprint:

- Service A siap diuji.
- Swagger Service A aktif.

## Sprint 3: Inventory and Transaction Core

Durasi: 1 minggu

Target:

- Implement CRUD items dengan barcode unik.
- Integrasi upload foto item ke GCS.
- Implement transaksi masuk dan keluar.
- Tambah endpoint histori transaksi.

Output sprint:

- Service B siap untuk skenario operasional mobile.
- Bukti upload media ke GCS.

## Sprint 4: Intelligence and Smart Alert

Durasi: 1 minggu

Target:

- Implement analytics summary.
- Implement endpoint low stock alert.
- Implement trigger low stock saat transaksi keluar.
- Simpan notifikasi dan histori alert di Firestore.

Output sprint:

- Service C siap untuk dashboard owner.
- Smart logic stok menipis berjalan.

## Sprint 5: Deployment and Final Hardening

Durasi: 1 minggu

Target:

- Deploy 3 service ke Cloud Run.
- Integrasi dengan Cloud SQL, Firestore, GCS.
- Uji end to end dan perbaikan bug kritis.
- Verifikasi semua requirement dosen terpenuhi.

Output sprint:

- URL Cloud Run aktif.
- Bukti test case utama dan compliance checklist.

## Sprint 6: Final Report and Presentation Package

Durasi: 3 sampai 5 hari

Target:

- Susun laporan sesuai template kampus.
- Buat diagram arsitektur dan ERD final.
- Siapkan script demo presentasi.
- Siapkan bukti screenshot dan ringkasan endpoint.

Output sprint:

- Laporan final siap submit.
- Deck presentasi dan demo checklist siap pakai.

## Pembagian Tanggung Jawab Tim

- Backend lead: implement service, security, database, integrasi cloud.
- Web team: dashboard analytics dan manajemen supplier barang.
- Mobile team: flow scan barcode masuk keluar.
- Semua tim: validasi endpoint lewat Swagger.

## Definisi Selesai per Sprint

Sebuah sprint dianggap selesai jika:

1. Fitur sprint sudah jalan di environment dev.
2. Endpoint terkait sudah tercatat di Swagger.
3. Test minimal happy path sudah dijalankan.
4. Bukti progres dicatat untuk bahan laporan akhir.
