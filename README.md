# 🏠 KosApp

Aplikasi manajemen kos berbasis **Flutter** dan **Supabase** untuk mempermudah pengelolaan kamar, transaksi tagihan, dan pengaduan keluhan antara **Owner** dan **Penghuni Kos**.

## 📌 Fitur Utama

### 👨‍💼 Owner
- **Kamar & Booking**: Atur daftar kamar dan konfirmasi pemesanan calon penghuni.
- **Tagihan**: Buat tagihan bulanan dan verifikasi bukti pembayaran.
- **Keluhan**: Pantau dan tanggapi laporan kerusakan dari penghuni.

### 👤 Penghuni
- **Kamar**: Lihat status kamar dan ajukan sewa/booking.
- **Tagihan**: Cek rincian tagihan dan upload bukti transfer.
- **Keluhan**: Laporkan kendala fasilitas kos.

## 🛠 Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (Auth, Database, Storage)

## 🚀 Cara Menjalankan

1. Clone repo:
   ```bash
   git clone https://github.com/username-kamu/kos_app.git
   ```
2. Install dependensi:
   ```bash
   flutter pub get
   ```
3. Sesuaikan URL & Key Supabase di `lib/main.dart`.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```
