# Smart Inventory UMKM Mobile

Aplikasi mobile Flutter untuk Smart Inventory UMKM.

## Setup

1. Masuk ke folder mobile:
   ```powershell
   cd "d:\hafid\Semester 6\prak_tcc\inventaris-umkm\frontend-mobile"
   ```
2. Install dependencies:
   ```powershell
   flutter pub get
   ```
3. Jalankan aplikasi di emulator atau perangkat:
   ```powershell
   flutter run
   ```

## Catatan

- API backend lokal default menggunakan `http://10.0.2.2:3000` untuk emulator Android.
- Jika memakai perangkat fisik, ganti `baseUrl` di `lib/services/api_service.dart` menjadi alamat IP komputer Anda.
- Default login demo: `owner` / `password123`.
