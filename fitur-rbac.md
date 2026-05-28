# Spesifikasi Fitur: Role-Based Access Control (RBAC)
## Modul Keamanan & Hak Akses Aplikasi Kasir

**Informasi Dokumen**
*   **Proyek:** Sistem POS & Inventaris Garis Awan
*   **Fokus Modul:** Manajemen Otorisasi Pengguna (RBAC)
*   **Versi:** 1.0.0

---

## 1. Deskripsi Umum
Sistem *Role-Based Access Control* (RBAC) ini dirancang untuk memastikan bahwa setiap karyawan yang menggunakan aplikasi kasir hanya memiliki akses ke fitur dan data yang sesuai dengan tanggung jawab pekerjaan mereka. Pendekatan ini meminimalkan risiko manipulasi data keuangan, menjaga integritas stok barang, dan mencegah penyalahgunaan wewenang di tingkat operasional.

Sistem ini menerapkan dua tingkatan peran (*role*) absolut: **Admin** (Manajer/Pemilik) dan **Kasir** (Staf Operasional).

## 2. Definisi Peran (Roles)

### 2.1. Admin (Administrator / Manajer)
*   **Tingkat Akses:** *Super User* (Level 1)
*   **Deskripsi:** Pemilik bisnis atau manajer toko yang memiliki kendali penuh atas seluruh sistem operasi, manajemen data master, kontrol karyawan, dan laporan analitik keuangan.
*   **Otentikasi Khusus:** Memiliki kode PIN rahasia (4-6 digit) yang digunakan untuk memberikan persetujuan (*override authorization*) secara cepat (on-the-fly) pada perangkat Kasir.

### 2.2. Kasir (Staf Operasional)
*   **Tingkat Akses:** *Restricted User* (Level 2)
*   **Deskripsi:** Karyawan garis depan yang bertugas melayani transaksi pelanggan sehari-hari. Hak akses dikunci ketat hanya pada ruang lingkup pembuatan nota pesanan dan pelaporan uang fisik di akhir *shift*.
*   **Batasan Utama:** Tidak dapat menghapus data, tidak dapat melihat modal dasar/HPP barang, dan tidak dapat membatalkan pesanan tanpa persetujuan Admin.

---

## 3. Matriks Hak Akses (Access Control Matrix)

Tabel berikut memetakan izin akses (Tampil, Tambah, Ubah, Hapus) untuk setiap peran pada berbagai modul aplikasi.

| Modul / Fitur | Kasir | Admin | Catatan Khusus |
| :--- | :---: | :---: | :--- |
| **Kasir (Point of Sale)** | | | |
| Membuat Transaksi Baru | ✔️ | ✔️ | |
| Akses Katalog Produk | ✔️ | ✔️ | Hanya menampilkan Harga Jual dan Stok Tersisa. |
| *Void* / Batal Transaksi | ❌ | ✔️ | Kasir memerlukan input PIN Admin di layar pop-up. |
| **Manajemen Shift** | | | |
| Buka Shift (Input Modal Awal) | ✔️ | ✔️ | Terbatas pada akun milik sendiri. |
| Tutup Shift (Input Uang Fisik) | ✔️ | ✔️ | Kasir tidak dapat melihat *Expected System Cash*. |
| Lihat Riwayat Shift Karyawan | ❌ | ✔️ | |
| **Manajemen Stok & Produk** | | | |
| Tambah/Edit Master Produk | ❌ | ✔️ | Termasuk set Harga Beli (HPP) & Harga Jual. |
| Input Stok Masuk (Restok) | ❌ | ✔️ | |
| Koreksi Stok Manual | ❌ | ✔️ | |
| Hapus Produk (*Soft Delete*) | ❌ | ✔️ | |
| **Laporan & Karyawan** | | | |
| Laporan Laba Rugi / Margin | ❌ | ✔️ | |
| Manajemen Akun Karyawan | ❌ | ✔️ | Reset *password* & buat akun Kasir baru. |

---

## 4. Alur Otorisasi Khusus (PIN Override Protocol)

Untuk menjaga kelancaran antrean tanpa mengharuskan Admin *login* ulang di tablet Kasir, sistem menggunakan mekanisme **PIN Override** untuk aksi sensitif.

**Skenario: Kasir salah memasukkan barang dan nota sudah tercetak (Void Transaksi)**
1.  Kasir menekan tombol "Void Nota" pada riwayat transaksi.
2.  Aplikasi memblokir aksi tersebut dan menampilkan *pop-up dialog* **"Otorisasi Dibutuhkan"**.
3.  Admin/Manajer yang sedang berada di lokasi datang ke meja kasir dan memasukkan PIN 6 digit miliknya di layar tersebut.
4.  Aplikasi memvalidasi PIN ke *database* (`SELECT id FROM users WHERE role = 'admin' AND pin_code = [INPUT]`).
5.  Jika valid, transaksi dibatalkan (status diubah menjadi `void`), dan ID Admin dicatat pada kolom `void_authorized_by` di tabel transaksi untuk keperluan audit pelacakan.
