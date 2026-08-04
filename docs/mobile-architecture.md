# Arsitektur Aplikasi Mobile SIP Sistem Absensi

Dokumen ini menyiapkan fondasi aplikasi mobile untuk pegawai PT Selada Indonesia Produktif.

## Prinsip Arsitektur

- Fokus pada pengguna pegawai saja.
- Memisahkan modul auth, attendance, submission, history, notification, dan profile.
- Menyediakan struktur yang siap terhubung ke Laravel REST API dan PostgreSQL/Supabase di masa depan.
- Menggunakan model domain yang jelas untuk mode absensi, status absensi, dan alur validasi.

## Modul Utama

- Auth: login, session, dan token handling.
- Attendance: check in, check out, validasi NFC/GPS/selfie, status kehadiran.
- Submission: pengajuan cuti, sakit, WFH, WFC, koreksi absensi.
- History: riwayat harian, bulanan, dan detail absensi.
- Notification: pengumuman, reminder, hasil approval.
- Profile: data karyawan, edit email, edit nomor telepon.

## Struktur Folder

- lib/core: konstanta, tema, dependency injection, router.
- lib/features/*: implementasi tiap modul.
- test/: uji regresi untuk domain model dan alur inti.
