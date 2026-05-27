# Product Requirements Document (PRD)
## Aplikasi Kasir & Manajemen Stok Terintegrasi

**Dokumen Info**
*   **Inisiatif:** Digitalisasi UMKM
*   **Pemilik Produk:** Tim Garis Awan
*   **Status:** Draft / Portofolio & Showcase
*   **Target Rilis:** Q3 2026 (Internal Demo)

---

## 1. Ringkasan Produk (Product Overview)
Sistem kasir (*Point of Sale*) modern yang dirancang khusus untuk memenuhi kebutuhan UMKM dengan mengintegrasikan pencatatan transaksi dan manajemen stok secara *real-time*. Sistem ini difokuskan pada kecepatan operasional, kemudahan penggunaan (*user-friendly*), dan keandalan data. Sebagai portofolio dan *showcase* solusi dari Garis Awan, aplikasi ini didesain agar tetap tangguh dan responsif di lingkungan jaringan lokal, dengan arsitektur yang siap di-skalakan ke lingkungan *cloud* di masa depan.

## 2. Tujuan & Sasaran (Objectives & Goals)
*   **Tujuan Utama:** Menyediakan satu platform terpadu di mana pelaku bisnis UMKM dapat memproses penjualan sekaligus memantau ketersediaan barang tanpa harus melakukan *double input* data.
*   **Sasaran Showcase:** Mendemonstrasikan aplikasi kasir yang memiliki latensi super rendah dan UI/UX yang responsif di hadapan calon *customer* menggunakan ekosistem lokal (laptop sebagai server lokal dan tablet sebagai klien).

## 3. Spesifikasi Teknologi (Tech Stack)
*   **Frontend / Client Aplikasi:** Flutter (Berjalan di Tablet Android & Desktop).
*   **Database:** PostgreSQL (Di-deploy secara lokal di laptop *developer* untuk tahap *showcase*).
*   **Desain Antarmuka:** Figma (Untuk *prototyping* dan panduan komponen UI/UX).
*   **Konektivitas:** Koneksi IP Lokal (Wi-Fi *tethering*) untuk simulasi komunikasi klien dan server.

---

## 4. Kebutuhan Fungsional (Functional Requirements)

### 4.1. Modul Kasir (Point of Sale)
| Fitur | Deskripsi | Prioritas |
| :--- | :--- | :--- |
| **Katalog Produk Cepat** | Menampilkan daftar produk dengan gambar, nama, dan harga. Mendukung pencarian instan (*search as you type*) dan filter berdasarkan kategori. | Tinggi |
| **Keranjang Belanja** | Menambah, mengurangi, atau menghapus *item* pesanan. Menghitung subtotal, pajak (jika ada), dan total akhir secara otomatis. | Tinggi |
| **Proses Pembayaran** | Mendukung input jumlah uang pelanggan dan menghitung uang kembalian secara presisi. | Tinggi |
| **Cetak Struk (Simulasi)** | Men-generate struk digital (tampilan layar pop-up atau PDF) yang mencakup detail pesanan, waktu, dan nomor *invoice*. | Sedang |

### 4.2. Modul Manajemen Stok (Inventory Management)
| Fitur | Deskripsi | Prioritas |
| :--- | :--- | :--- |
| **Master Data Produk** | Fitur CRUD (*Create, Read, Update, Delete*) informasi produk termasuk SKU, Nama, Kategori, Harga Beli, Harga Jual, dan Stok Awal. | Tinggi |
| **Pengurangan Stok Otomatis** | Jumlah stok pada database PostgreSQL langsung berkurang tepat setelah status transaksi kasir dinyatakan "Berhasil". | Tinggi |
| **Input Stok Masuk** | Formulir untuk mencatat penambahan stok barang baru (restok) ke dalam inventaris. | Tinggi |
| **Peringatan Stok Tipis** | Indikator visual (misal: *badge* warna merah) pada daftar produk jika jumlah stok menyentuh batas minimum. | Menengah |

### 4.3. Dashboard & Pelaporan (Fase Lanjutan)
| Fitur | Deskripsi | Prioritas |
| :--- | :--- | :--- |
| **Ringkasan Harian** | Menampilkan total pendapatan, jumlah transaksi, dan kalkulasi margin harian secara sederhana. | Menengah |
| **Produk Terlaris** | Menampilkan 5 produk dengan volume penjualan tertinggi untuk analisis bisnis. | Rendah |

---

## 5. Kebutuhan Non-Fungsional (Non-Functional Requirements)
*   **Kinerja & Responsivitas:** Aplikasi kasir Flutter harus me-render UI di atas 60fps. Pencarian produk dan kalkulasi keranjang harus merespons dalam waktu kurang dari 200 milidetik untuk mencegah antrean pelanggan di meja kasir.
*   **Keandalan Jaringan Lokal:** Sistem harus bisa berjalan dengan stabil menggunakan koneksi IP Lokal (misal: 192.168.x.x) agar presentasi bisnis dapat dilakukan tanpa bergantung pada koneksi internet eksternal.
*   **Kepatuhan Data (ACID):** Database PostgreSQL harus menggunakan skema transaksional yang memastikan stok tidak akan minus secara tidak wajar jika terjadi transaksi bersamaan.

---

## 6. Rancangan Skema Database (High-Level PostgreSQL)
Berikut adalah struktur tabel inti yang akan dibangun:

1.  **`categories`**
    *   Menyimpan kelompok barang (contoh: Makanan, Minuman, Kebutuhan Pokok).
    *   *Kolom:* `id`, `name`.
2.  **`products`**
    *   Menyimpan profil barang yang dijual.
    *   *Kolom:* `id`, `category_id` (FK), `sku`, `name`, `buy_price`, `sell_price`, `current_stock`.
3.  **`transactions`**
    *   Menyimpan *header* atau nota induk dari setiap pembayaran kasir.
    *   *Kolom:* `id`, `invoice_number`, `total_amount`, `payment_method`, `created_at`.
4.  **`transaction_details`**
    *   Menyimpan daftar rincian barang di dalam satu nota (relasi *many-to-one* ke tabel `transactions`).
    *   *Kolom:* `id`, `transaction_id` (FK), `product_id` (FK), `quantity`, `unit_price`, `subtotal`.
5.  **`stock_adjustments`**
    *   Mencatat riwayat keluar masuknya barang di luar transaksi kasir (misal: penambahan stok).
    *   *Kolom:* `id`, `product_id` (FK), `adjustment_type` ('IN' atau 'OUT'), `quantity`, `created_at`, `note`.