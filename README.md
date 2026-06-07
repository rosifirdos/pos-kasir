# POS Kasir & Manajemen Stok Terintegrasi

Aplikasi Point of Sale (POS) Kasir modern yang dirancang khusus untuk memenuhi kebutuhan digitalisasi UMKM. Sistem ini mengintegrasikan pencatatan transaksi penjualan secara langsung (*real-time*) dengan manajemen stok barang untuk mencegah ketidaksesuaian data. 

Aplikasi ini didesain tangguh berjalan pada jaringan lokal (jaringan server lokal-klien) dengan latensi super rendah, menggunakan laptop sebagai server lokal dan tablet/desktop sebagai klien kasir.

---

## 🚀 Fitur Utama

### 1. Otentikasi & Keamanan (RBAC)
* **Multi-Role User:** Pembagian peran pengguna antara `ADMIN` (pemilik toko/manajer) dan `KASIR` (staf operasional).
* **Otentikasi Aman:** Sistem login aman menggunakan enkripsi *password* (`bcrypt`) dan token otorisasi (`JWT`).
* **Pembatasan Hak Akses (Authorization):** Kasir hanya memiliki akses ke modul penjualan dan manajemen shift mandiri, sementara Admin memegang kontrol penuh atas data produk, stok, laporan laba rugi, dan manajemen akun karyawan.

### 2. Modul Kasir (Point of Sale)
* **Katalog Produk Cepat:** Filter produk berdasarkan kategori dan pencarian instan (*search-as-you-type*).
* **Keranjang Belanja Dinamis:** Tambah, kurangi, hapus item, dan edit jumlah item di keranjang dengan kalkulasi subtotal dan total harga secara otomatis.
* **Metode Pembayaran:** Pilihan metode pembayaran `CASH` dan `DEBIT` dengan input nominal pembayaran dan hitung kembalian presisi.
* **Struk Digital (Simulasi Cetak):** Generate struk digital instan setelah transaksi sukses, dengan fitur ekspor ke PDF atau cetak langsung menggunakan printer lokal.
* **Otorisasi PIN Admin (Override Protocol):** Pembatalan (*void*) transaksi kasir membutuhkan input PIN dari Admin langsung di layar kasir secara *on-the-fly* untuk mencegah manipulasi data.

### 3. Manajemen Shift Kerja
* **Buka Shift:** Kasir memasukkan jumlah modal uang kas awal sebelum melayani transaksi penjualan.
* **Tutup Shift:** Kasir menginput jumlah uang fisik yang ada di laci kasir pada akhir shift untuk rekonsiliasi dengan pencatatan otomatis sistem (*expected cash*).
* **Riwayat Shift:** Admin dapat melihat histori pembukaan dan penutupan shift semua karyawan beserta selisih kasnya.

### 4. Manajemen Stok & Inventaris
* **Pengurangan Stok Otomatis:** Pengurangan stok dilakukan menggunakan skema *Interactive Transaction* di database untuk menjamin integritas data (ACID Compliance) saat transaksi diselesaikan.
* **Manajemen Master Data:** Fitur CRUD (*Create, Read, Update, Delete*) Kategori dan Produk (termasuk upload gambar, SKU, harga beli/HPP, harga jual, dan stok awal).
* **Penyesuaian Stok (Restock):** Pencatatan riwayat restok barang masuk/keluar di luar transaksi kasir.
* **Indikator Stok Tipis:** Notifikasi visual (badge merah) ketika jumlah stok berada di bawah batas minimum (≤ 5 item).

### 5. Dashboard Bisnis & Audit Trail
* **Ringkasan Performa:** Dashboard harian untuk melihat total pendapatan, jumlah transaksi, margin keuntungan (laba kotor), dan produk terlaris.
* **Log Aktivitas (Audit Trail):** Pencatatan riwayat aktivitas penting (penghapusan produk, modifikasi stok, void transaksi) untuk keperluan pengawasan internal.

---

## 🛠️ Tech Stack

### Frontend (Klien)
* **Framework:** Flutter (Android / Windows Desktop)
* **State Management:** Provider
* **Desain UI:** Material Design 3 (Clean & Modern Layout) dengan Google Fonts (Inter)
* **Libraries Utama:** `http` (API integration), `pdf` & `printing` (receipt generation & printer integration), `intl` (formatting).

### Backend (Server API)
* **Runtime:** Node.js (TypeScript)
* **Framework:** Express.js
* **Database Client:** Prisma ORM
* **Libraries Utama:** `jsonwebtoken` (JWT), `bcrypt` (password hashing), `cors`, `multer` (upload file/gambar), `dotenv`.

### Database
* **DBMS:** PostgreSQL

---

## 💻 Cara Menjalankan Proyek

### Prasyarat (Prerequisites)
Before running, pastikan Anda telah menginstal:
* [Node.js](https://nodejs.org/) (versi 18+)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.0+)
* [PostgreSQL](https://www.postgresql.org/) running secara lokal.

---

### Langkah 1: Setup & Jalankan Database
1. Buat database baru di PostgreSQL lokal Anda bernama `pos_db`.
2. Pastikan port PostgreSQL berjalan sesuai konfigurasi (default: `5432` atau ubah di konfigurasi backend).

---

### Langkah 2: Setup & Jalankan Backend API
1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Salin atau buat file konfigurasi `.env` dan sesuaikan URL database Anda:
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/pos_db?schema=public"
   PORT=3000
   ```
3. Install dependensi:
   ```bash
   npm install
   ```
4. Jalankan migrasi skema database & seeding data awal:
   ```bash
   npx prisma migrate dev --name init
   npx prisma db seed
   ```
5. Jalankan server backend dalam mode development:
   ```bash
   npm run dev
   ```
   Server backend akan aktif di `http://localhost:3000`.

---

### Langkah 3: Setup & Jalankan Frontend (Flutter)
1. Buka terminal baru dan masuk ke direktori frontend:
   ```bash
   cd frontend
   ```
2. Ambil dependensi Flutter yang dibutuhkan:
   ```bash
   flutter pub get
   ```
3. Hubungkan perangkat Anda atau jalankan langsung ke Windows Desktop dengan perintah:
   ```bash
   flutter run -d windows
   ```
   
> **Tips Windows:** Jika perintah `flutter` tidak dikenali oleh shell/terminal Anda, jalankan file skrip pembantu di direktori utama:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\run_flutter.ps1
> ```

---

## 📂 Struktur Proyek
```text
pos-kasir/
├── backend/            # Aplikasi Node.js / Express Server API
│   ├── prisma/         # Skema Database & Migrasi Prisma
│   ├── src/            # Kode Sumber (Controllers, Routes, Services)
│   └── package.json
│
├── frontend/           # Aplikasi Klien Flutter
│   ├── lib/            # Kode Sumber Flutter (Screens, Models, Providers)
│   └── pubspec.yaml    # Dependensi Flutter
│
├── README.md           # Dokumentasi Proyek
└── run_flutter.ps1     # Skrip Windows untuk menjalankan Flutter
```
