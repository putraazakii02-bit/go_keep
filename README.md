# GoKeep

Aplikasi catatan Flutter dengan REST API Laravel dan database MySQL. Catatan,
arsip, sampah, pin, warna, dan label tersimpan di server.

## Menjalankan backend dengan Laragon

1. Buka Laragon, lalu jalankan **MySQL**.
2. Buka **Database** di Laragon (HeidiSQL/phpMyAdmin) dan buat database bernama
   `go_keep` dengan collation `utf8mb4_unicode_ci`.
3. Buka terminal di folder `backend`, salin `.env.example` menjadi `.env`, lalu
   jalankan:

   ```powershell
   Copy-Item .env.example .env -Force
   composer install
   php artisan key:generate
   php artisan migrate
   php artisan serve --host=0.0.0.0
   ```

   Jika Composer mengeluhkan ekstensi ZIP, aktifkan **zip** di menu Laragon
   **PHP > Extensions**, lalu buka ulang terminal.
   Jika memakai Laragon Terminal, PHP dan Composer biasanya sudah tersedia di
   `PATH`. Secara default konfigurasi memakai pengguna MySQL `root` tanpa
   password; ubah `backend/.env` bila konfigurasi MySQL Anda berbeda.

4. API berjalan di `http://127.0.0.1:8000/api`. Cek `http://127.0.0.1:8000/up`
   untuk memastikan server aktif.

## Menjalankan Flutter

Dependensi `http` sudah digunakan aplikasi. Jalankan dari root proyek:

```powershell
flutter pub get
flutter run
```

URL default aplikasi adalah `http://10.0.2.2:8000/api` untuk Android Emulator.
Konfigurasi HTTP tanpa enkripsi hanya diaktifkan pada Android debug untuk
pengembangan lokal; gunakan HTTPS sebelum membuat aplikasi rilis.
Untuk Flutter Web atau perangkat fisik, arahkan URL ke host backend yang bisa
dijangkau perangkat tersebut:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Pada perangkat fisik, ganti `127.0.0.1` dengan alamat IP komputer di jaringan
lokal. Jangan gunakan URL emulator `10.0.2.2` pada perangkat fisik.

## REST API

Semua respons berhasil memakai JSON. Objek catatan memakai field `isPinned`,
`isArchived`, `isDeleted`, `createdAt`, dan `updatedAt`.

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| `GET` | `/api/notes?view=all` | Daftar catatan (`all`, `active`, `archived`, `trash`) |
| `GET` | `/api/notes/{id}` | Detail catatan |
| `POST` | `/api/notes` | Membuat catatan |
| `PUT` / `PATCH` | `/api/notes/{id}` | Mengubah catatan atau statusnya |
| `DELETE` | `/api/notes/{id}` | Menghapus permanen satu catatan |
| `DELETE` | `/api/notes/trash` | Menghapus permanen semua catatan di sampah |
| `POST` | `/api/notes/import` | Impor catatan lokal lama secara idempoten |
| `GET` | `/api/labels` | Daftar label |
| `PATCH` | `/api/labels` | Mengganti nama label (`oldName`, `newName`) |
| `DELETE` | `/api/labels?name=Pribadi` | Menghapus label |

Contoh body untuk `POST /api/notes`:

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

Waktu pengingat disimpan di backend dan ditampilkan pada halaman Pengingat.
Pengiriman notifikasi otomatis ke perangkat belum diimplementasikan.

API saat ini belum memakai autentikasi karena aplikasi belum memiliki alur akun;
data berada pada satu koleksi bersama. Tambahkan autentikasi sebelum API
dipublikasikan ke internet.
