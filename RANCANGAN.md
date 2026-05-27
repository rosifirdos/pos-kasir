# Rencana Arsitektur & Implementasi POS Garis Awan

## 1. Background & Motivation
Tim Garis Awan menginisiasi pembuatan aplikasi kasir (Point of Sale) modern yang dirancang untuk UMKM, yang mampu menangani pencatatan transaksi dan manajemen stok secara terintegrasi dan real-time. Aplikasi harus responsif, ringan, dan berjalan di lingkungan jaringan IP lokal dengan latensi sangat rendah, menggunakan perangkat tablet (client) dan laptop (server).

## 2. Scope & Impact
*   **Aplikasi Frontend (Client):** Menggunakan **Flutter**, menargetkan tablet Android/Desktop dengan performa minimal 60fps.
*   **Backend API:** Menggunakan **Node.js (Express)** dengan **Prisma ORM**.
*   **Database:** Menggunakan **PostgreSQL** yang berjalan secara lokal.
*   **Fitur Utama:** Katalog Produk, Keranjang Belanja, Pembayaran, Cetak Struk (Simulasi), Master Data Produk, Manajemen Stok, dan Dashboard Ringkasan.

## 3. Proposed Solution
Pendekatan implementasi dibagi menjadi dua repository/proyek utama yang dapat disatukan dalam monorepo sederhana atau terpisah pada folder yang sama:
1.  **Backend (`/backend`)**
    *   Setup Node.js dengan TypeScript.
    *   Setup Express.js untuk API routing.
    *   Setup Prisma ORM dan PostgreSQL (Migrasi dan Seeding berdasarkan skema di PRD).
    *   Implementasi RESTful API endpoint untuk Produk, Kategori, Transaksi, dan Stok. Transaksi dan pengurangan stok dibungkus dalam *Prisma Transactions* untuk memastikan kepatuhan ACID.
2.  **Frontend (`/frontend`)**
    *   Setup Flutter project.
    *   Manajemen State: **Provider** (digunakan untuk kesederhanaan dan kehandalan state tree aplikasi).
    *   Struktur arsitektur bersih (*Clean Architecture* / MVC) memisahkan UI, State, dan API service.
    *   Implementasi *offline-first* minimal atau state manajemen yang tidak me-blocking UI.

## 4. Alternatives Considered
*   **Dart Frog:** Menawarkan kesatuan bahasa (full Dart), namun ekosistem ORM di Node.js (Prisma) lebih teruji untuk penanganan transaksi database dan lebih populer.
*   **Supabase Lokal:** Menawarkan real-time out of the box dan API instan dari PostgreSQL, tetapi mengharuskan docker container dan setup yang lebih berat dibanding Node.js native.

## 5. Phased Implementation Plan

### Fase 1: Setup Proyek & Backend Foundation (✅ SELESAI)
1.  Inisialisasi folder `backend` dan setup package.json, TypeScript.
2.  Inisialisasi Prisma ORM dengan PostgreSQL.
3.  Membuat skema Prisma berdasarkan PRD (Kategori, Produk, Transaksi, Detail Transaksi, Penyesuaian Stok).
4.  Menjalankan migrasi database (`prisma migrate dev`).
5.  Membuat API routing dengan Express.js.

### Fase 2: Implementasi API Services & ACID Transactions (✅ SELESAI)
1.  **Kategori & Produk API:** Endpoint CRUD.
2.  **Stok API:** Endpoint Restok dan pengurangan stok otomatis.
3.  **Transaksi API:** Endpoint `POST /transactions` yang akan menyimpan header, detail, dan mengurangi stok melalui *Interactive Transaction* di Prisma.

### Fase 3: Setup Frontend (Flutter) & Integrasi Katalog (✅ SELESAI)
1.  Inisialisasi folder `frontend` dengan Flutter.
2.  Setup arsitektur folder (seperti `lib/models`, `lib/services`, `lib/screens`, `lib/providers`).
3.  Setup `http` atau `dio` untuk komunikasi API ke backend (dengan base URL konfigurasi IP lokal).
4.  Membuat UI **Katalog Produk** (grid, search, kategori filter).

### Fase 4: Implementasi Keranjang & Kasir (✅ SELESAI)
1.  Membuat state manajemen keranjang (`CartProvider`).
2.  UI dan logika penambahan barang, hitung total harga pesanan.
3.  UI dan logika Pembayaran (Integrasi API `POST /transactions`).

### Fase 5: Manajemen Toko & Dashboard (⏳ TERTUNDA / SELANJUTNYA)
1.  UI Master Data (CRUD Produk dan input Stok).
2.  UI Ringkasan Transaksi Harian dan peringatan stok tipis.

## 6. Verification & Testing
*   **Backend:** Menjalankan manual test untuk menguji integritas transaksi (Prisma Transaction).
*   **Frontend:** Menjalankan Flutter app di simulator/device tablet/web browser memastikan komunikasi API di localhost berjalan baik.
*   **Sistem:** Uji skenario end-to-end: Tambah produk -> Produk tampil di POS -> Tambah ke keranjang -> Bayar -> Verifikasi stok berkurang secara akurat.

## 7. Migration & Rollback Strategies
*   Karena ini proyek inisiasi (fase showcase), migrasi database akan ditangani murni oleh Prisma Migrate. Rollback pada tahap development dilakukan dengan `prisma migrate reset` untuk mengulang DB dari awal.
