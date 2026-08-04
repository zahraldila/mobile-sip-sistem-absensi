# Panduan Kontribusi

Terima kasih telah berkontribusi pada proyek **SIP Sistem Absensi**.

Dokumen ini berisi panduan dasar dalam proses pengembangan aplikasi. Panduan ini dapat diperbarui seiring perkembangan proyek.

---

## Branch yang Digunakan

| Branch | Fungsi |
|--------|--------|
| `main` | Menyimpan versi aplikasi yang stabil. |
| `develop` | Branch utama untuk pengembangan. |
| `feature/*` | Digunakan untuk mengembangkan fitur baru. |
| `hotfix/*` | Digunakan untuk perbaikan bug mendesak (jika diperlukan). |

---

## Alur Pengembangan

1. Gunakan branch `develop` sebagai dasar pengembangan.
2. Buat branch baru sesuai fitur yang akan dikerjakan.
3. Lakukan pengembangan pada branch tersebut.
4. Commit perubahan dengan pesan yang jelas.
5. Push branch ke GitHub.
6. Gabungkan perubahan ke branch `develop` sesuai mekanisme yang disepakati tim.

> **Catatan:** Mekanisme Pull Request, code review, dan CI/CD akan diterapkan pada tahap pengembangan berikutnya sesuai kebutuhan proyek.

---

## Penamaan Branch

Gunakan format berikut:

```
feature/backend-auth
feature/mobile-attendance
feature/web-admin-approval
feature/tv-dashboard-popup
```

---

## Penulisan Commit

Gunakan pesan commit yang singkat dan mudah dipahami.

Contoh:

```
feat: menambahkan fitur login
fix: memperbaiki validasi absensi
docs: memperbarui dokumentasi
refactor: merapikan struktur backend
```

---

## Dokumentasi

Apabila terdapat perubahan yang memengaruhi alur sistem, struktur proyek, atau proses deployment, harap memperbarui dokumentasi pada folder `docs/`.
