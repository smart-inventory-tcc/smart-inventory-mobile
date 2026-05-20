# Smart Inventory UMKM — Frontend Mobile

Aplikasi mobile Flutter untuk manajemen stok UMKM: scan barcode, lihat daftar barang, dan catat transaksi masuk/keluar.

---

## Prasyarat

Pastikan sudah terinstall:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.x ke atas)
- Android Studio atau VS Code dengan plugin Flutter
- Backend sudah berjalan (lihat `../backend/README.md`)

---

## Setup Awal

```powershell
# Masuk ke folder ini
cd "d:\Flutter\smart-inventory-mobile\frontend-mobile"

# Install dependencies
flutter pub get
```

---

## ▶️ Cara Menjalankan di Web (Browser)

> Pastikan backend berjalan dengan `node app.js` di folder `backend/`.
> Base URL di `lib/services/api_service.dart` harus `http://localhost:3000`.

```powershell
# Jalankan di Chrome
flutter run -d chrome
```

> ⚠️ Fitur scanner barcode **tidak tersedia** di web (kamera mobile_scanner tidak support browser).
> Gunakan input barcode manual yang tersedia di halaman Scanner.

---

## ▶️ Cara Menjalankan di HP / Perangkat Fisik (Android)

### Langkah 1 — Aktifkan Developer Mode di HP

1. Buka **Settings → About Phone**
2. Ketuk **Build Number** sebanyak **7 kali** hingga muncul notifikasi *"You are now a developer"*
3. Kembali ke **Settings → Developer Options**
4. Aktifkan **USB Debugging**

### Langkah 2 — Sambungkan HP ke Laptop

1. Hubungkan HP ke laptop via kabel **USB**
2. Saat muncul popup *"Allow USB Debugging?"* di HP → tap **Allow / OK**
3. Pastikan HP dan laptop terhubung ke **jaringan WiFi yang sama**

Verifikasi HP terdeteksi Flutter:
```powershell
flutter devices
```
Nama HP kamu harus muncul dalam daftar.

### Langkah 3 — Ubah Base URL Backend

Karena HP tidak bisa menggunakan `localhost`, ganti URL di `lib/services/api_service.dart`:

```dart
// Ganti localhost dengan IP WiFi laptop kamu
static const baseUrl = 'http://192.168.X.X:3000'; // ganti X.X dengan IP kamu
```

Cara cek IP WiFi laptop (PowerShell):
```powershell
ipconfig
# Lihat bagian "Wireless LAN adapter Wi-Fi" → IPv4 Address
```

### Langkah 4 — Izinkan Port 3000 di Windows Firewall

```powershell
# Jalankan PowerShell sebagai Administrator
New-NetFirewallRule -DisplayName "Smart Inventory Backend" `
  -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

### Langkah 5 — Jalankan Backend & Aplikasi

```powershell
# Terminal 1: Jalankan backend
cd ..\backend
node app.js

# Terminal 2: Jalankan Flutter ke HP
cd ..\frontend-mobile
flutter run
```

Flutter akan otomatis memilih perangkat yang terhubung dan menginstall APK ke HP.

### Setelah Selesai Testing

Untuk kembali ke testing di web, ganti kembali URL di `api_service.dart`:
```dart
static const baseUrl = 'http://localhost:3000'; // untuk web/emulator
```

---

## Akun Demo

| Username | Password   | Role  |
|----------|-----------|-------|
| `owner`  | `password123` | Owner |

---