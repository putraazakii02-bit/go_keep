# GoKeep

Aplikasi catatan mobile berbasis Flutter yang terintegrasi dengan REST API Laravel dan database MySQL. GoKeep menyediakan fitur pengelolaan catatan, arsip, sampah, pin, warna, dan label. Data tersebut disimpan melalui backend agar dapat dikelola oleh aplikasi.

Project ini dikembangkan sebagai tugas kelompok Ujian Tengah Semester (UTS) mata kuliah **Pemrograman Aplikasi Bergerak**, Program Studi Sistem Informasi, Tahun Akademik 2026/2027.

## 1. Identitas Project

- **Nama aplikasi:** GoKeep
- **Aplikasi asli yang ditiru:** Google Keeps
- **Nama plesetan aplikasi:** GoKeep
- **Jenis aplikasi:** Mobile application
- **Tujuan:** Mengimplementasikan aplikasi catatan mobile dengan Flutter, REST API, dan database relasional.

## 2. Anggota Kelompok

| No. | Nama Anggota | NIM |
|---|---|---|
| 1 | Aztha Gangsar Ramadhan | 24051214215 |
| 2 | Putra Zaki Saifullaah | 24051214229 |
| 3 | Ian Frissaad | 24051214230 |
| 4 | Viorien Ronanda Adhita Riyanto | 24051214241 |

## 3. Teknologi yang Digunakan

| Komponen | Teknologi | Fungsi |
|---|---|---|
| Frontend | Flutter dan Dart | Membangun antarmuka serta menjalankan aplikasi mobile |
| Backend | Laravel dan PHP | Menyediakan REST API dan memproses permintaan aplikasi |
| Database | MySQL | Menyimpan data catatan dan label |
| Komunikasi data | REST API dan JSON | Menghubungkan frontend dengan backend |
| Version control | Git dan GitHub | Mengelola versi kode sumber dan repository project |

## 4. Fitur Aplikasi

Fitur yang tersedia dalam project GoKeep meliputi:

- Membuat, melihat, dan mengedit catatan.
- Mengelola status pin pada catatan.
- Mengatur warna catatan.
- Mengarsipkan dan menampilkan catatan yang diarsipkan.
- Memindahkan catatan ke sampah dan menghapusnya secara permanen.
- Mengelola label catatan.
- Mengatur waktu pengingat dan menampilkan catatan pada halaman Pengingat.

Pengiriman notifikasi otomatis ke perangkat belum diimplementasikan. Waktu pengingat disimpan melalui backend dan ditampilkan pada halaman Pengingat.

## 5. Struktur Project

Struktur utama repository terdiri dari:

- `lib/` — Source code aplikasi Flutter, termasuk halaman, model, provider, dan komponen aplikasi.
- `android/` — Konfigurasi platform Android.
- `ios/` — Konfigurasi platform iOS.
- `web/` — Konfigurasi platform web.
- `windows/` — Konfigurasi platform Windows.
- `linux/` — Konfigurasi platform Linux.
- `macos/` — Konfigurasi platform macOS.
- `test/` — File pengujian Flutter.
- `backend/` — Source code backend Laravel REST API.
- `backend/routes/` — Definisi route dan endpoint backend.
- `backend/database/` — Migration dan komponen database Laravel.
- `pubspec.yaml` — Konfigurasi package dan dependensi Flutter.
- `pubspec.lock` — Versi dependensi Flutter yang terkunci.
- `README.md` — Dokumentasi project.

## 6. Persyaratan Sistem

Sebelum menjalankan project, siapkan perangkat pengembangan dengan komponen berikut:

- Flutter SDK dan Dart SDK.
- Git.
- Laragon atau lingkungan PHP dan MySQL yang sesuai.
- PHP dan Composer.
- MySQL Server.
- Android Studio beserta Android Emulator, atau perangkat Android fisik.
- Koneksi jaringan yang memungkinkan frontend menjangkau backend.

Versi PHP, Flutter, serta dependensi lainnya perlu disesuaikan dengan kebutuhan project dan konfigurasi yang digunakan.

## 7. Cara Menjalankan Backend dengan Laragon

### 7.1. Menyiapkan Database

1. Buka Laragon dan jalankan MySQL.
2. Buka HeidiSQL, phpMyAdmin, atau perangkat pengelolaan database lain yang tersedia.
3. Buat database dengan nama `go_keep`.
4. Gunakan collation `utf8mb4_unicode_ci`.

Nama database harus sesuai dengan konfigurasi backend. Jika menggunakan nama berbeda, sesuaikan konfigurasi pada file `.env` lokal.

### 7.2. Menginstal Dependensi Backend

Buka terminal pada direktori utama project, kemudian masuk ke folder backend:

```powershell
cd backend
```

Instal dependensi Laravel:

```powershell
composer install
```

### 7.3. Menyiapkan Konfigurasi Environment

Buat file `.env` dari `.env.example` jika file `.env` belum tersedia:

```powershell
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
}
```

Periksa konfigurasi database dalam file `backend/.env`:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=go_keep
DB_USERNAME=root
DB_PASSWORD=
```

Contoh tersebut menggunakan pengguna MySQL `root` tanpa password, sesuai konfigurasi lokal yang diasumsikan project ini. Ubah nilainya jika konfigurasi MySQL yang digunakan berbeda.

Jangan menimpa file `.env` lokal yang sudah ada karena file tersebut mungkin berisi konfigurasi khusus komputer masing-masing.

### 7.4. Membuat Application Key dan Menjalankan Migration

Pastikan file `.env` sudah benar, kemudian jalankan:

```powershell
php artisan key:generate
php artisan migrate
```

Perintah `php artisan migrate` menjalankan migration yang tersedia untuk membuat struktur tabel database sesuai definisi migration Laravel.

Pastikan migration berhasil dan database `go_keep` dapat diakses oleh backend.

### 7.5. Menjalankan REST API

Jalankan server backend:

```powershell
php artisan serve --host=0.0.0.0
```

Secara default, API tersedia di:

`http://127.0.0.1:8000/api`

Untuk memeriksa apakah server berjalan, buka:

`http://127.0.0.1:8000/up`

Jika Composer melaporkan masalah ekstensi ZIP, periksa menu **Laragon → PHP → Extensions**, aktifkan ekstensi `zip` jika belum aktif, kemudian buka terminal baru.

Penggunaan `--host=0.0.0.0` memungkinkan server mendengarkan koneksi pada antarmuka jaringan yang tersedia. Pastikan akses jaringan dan firewall dikonfigurasi dengan tepat, terutama ketika menggunakan perangkat fisik.

## 8. Cara Menjalankan Aplikasi Flutter

Pastikan backend sudah berjalan dan URL API pada aplikasi mengarah ke backend yang benar.

Buka terminal baru pada direktori utama project `go_keep`, bukan di dalam folder `backend`.

Unduh dependensi Flutter:

```powershell
flutter pub get
```

Jalankan aplikasi:

```powershell
flutter run
```

### 8.1. Konfigurasi API untuk Android Emulator

URL default API untuk Android Emulator adalah:

`http://10.0.2.2:8000/api`

Alamat `10.0.2.2` digunakan Android Emulator untuk mengakses server yang berjalan pada komputer host.

### 8.2. Konfigurasi API untuk Web atau Perangkat Fisik

Untuk Flutter Web atau perangkat fisik, gunakan alamat host backend yang bisa dijangkau dari perangkat tersebut.

Contoh menjalankan aplikasi dengan URL API yang ditentukan melalui Dart define:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Pada perangkat fisik, ganti `127.0.0.1` dengan alamat IP komputer yang dapat dijangkau melalui jaringan lokal.

Jangan menggunakan URL emulator `10.0.2.2` pada perangkat fisik.

Konfigurasi HTTP tanpa enkripsi hanya diaktifkan pada Android debug untuk pengembangan lokal. Gunakan HTTPS untuk deployment dan aplikasi rilis. Untuk pengujian pada browser, pastikan konfigurasi CORS backend sesuai.

## 9. Dokumentasi REST API

Backend menyediakan REST API dengan respons JSON untuk operasi catatan dan label.

Objek catatan menggunakan beberapa field berikut:

- `isPinned`
- `isArchived`
- `isDeleted`
- `createdAt`
- `updatedAt`

### 9.1. Endpoint Catatan

| Method | Endpoint | Fungsi |
|---|---|---|
| `GET` | `/api/notes?view=all` | Mendapatkan daftar catatan. Parameter `view` mendukung tampilan `all`, `active`, `archived`, dan `trash`. |
| `GET` | `/api/notes/{id}` | Mendapatkan detail satu catatan. |
| `POST` | `/api/notes` | Membuat catatan baru. |
| `PUT` / `PATCH` | `/api/notes/{id}` | Mengubah catatan atau statusnya. |
| `DELETE` | `/api/notes/{id}` | Menghapus satu catatan secara permanen. |
| `DELETE` | `/api/notes/trash` | Menghapus secara permanen semua catatan di sampah. |
| `POST` | `/api/notes/import` | Mengimpor catatan lokal lama secara idempoten. |

### 9.2. Endpoint Label

| Method | Endpoint | Fungsi |
|---|---|---|
| `GET` | `/api/labels` | Mendapatkan daftar label. |
| `PATCH` | `/api/labels` | Mengganti nama label menggunakan field `oldName` dan `newName`. |
| `DELETE` | `/api/labels?name=Pribadi` | Menghapus label berdasarkan nama. |

### 9.3. Contoh Request untuk Membuat Catatan

Endpoint:

`POST /api/notes`

Contoh body JSON:

```json
{
  "title": "Belanja",
  "content": "Kopi dan susu",
  "color": "#FFF3C4",
  "isPinned": false,
  "isArchived": false,
  "isDeleted": false,
  "reminderAt": "2026-10-17T09:00:00+07:00",
  "labels": ["Pribadi"]
}
```

Contoh tersebut merupakan ilustrasi request untuk membuat catatan. Pastikan nama field dan format data sesuai dengan implementasi endpoint backend.

## 10. Catatan dan Batasan Implementasi

- Data catatan dan label dikelola melalui backend sesuai implementasi yang tersedia.
- Waktu pengingat disimpan di backend dan ditampilkan pada halaman Pengingat.
- Notifikasi otomatis ke perangkat belum diimplementasikan.
- API saat ini belum menggunakan autentikasi karena aplikasi belum memiliki alur akun.
- Data berada dalam satu koleksi bersama dan belum dipisahkan berdasarkan identitas pengguna.
- Autentikasi, otorisasi, dan pemisahan data pengguna perlu ditambahkan sebelum API dipublikasikan ke internet.
- Konfigurasi lokal, password, API key, token, serta kredensial rahasia tidak boleh dimasukkan ke repository.

## 11. Repository

Source code project GoKeep dapat diakses melalui GitHub:

https://github.com/putraazakii02-bit/go_keep.git