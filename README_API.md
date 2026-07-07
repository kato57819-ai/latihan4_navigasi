# Backend API untuk Aplikasi Pengingat Tugas

## Setup

1. **Copy API Files:**
   - Copy folder `api/` dari project ini ke `C:\xampp\htdocs\` (atau folder htdocs XAMPP Anda).
   - Jadi path menjadi `C:\xampp\htdocs\api\`

2. **Database:**
   - Pastikan database `pengingat_tugas` sudah dibuat di MySQL XAMPP (lihat `database_setup.sql`).

3. **Jalankan XAMPP:**
   - Start Apache dan MySQL di XAMPP Control Panel.

4. **Test API:**
   - Buka browser: `http://localhost/api/login.php` (akan error karena method POST, tapi untuk cek koneksi).

## API Endpoints

- `POST http://localhost/api/register.php` - Register user baru
- `POST http://localhost/api/login.php` - Login user
- `GET/POST http://localhost/api/profil.php?user_id=1` - Get/Update profil
- `GET/POST/DELETE http://localhost/api/mk.php?user_id=1` - Mata Kuliah CRUD
- `GET/POST/PUT/DELETE http://localhost/api/tugas.php?user_id=1` - Tugas CRUD

## Catatan untuk Flutter

- Gunakan `http://10.0.2.2/api/` jika run di Android Emulator.
- Gunakan `http://192.168.x.x/api/` (IP komputer) jika run di device fisik.
- Pastikan internet permission di AndroidManifest.xml.

## Contoh Request

### Register:
```json
POST /api/register.php
{
  "nama": "John Doe",
  "username": "johndoe",
  "password": "password123"
}
```

### Login:
```json
POST /api/login.php
{
  "username": "johndoe",
  "password": "password123"
}
```