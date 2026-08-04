# Panduan Kontribusi

Terima kasih telah berkontribusi pada proyek **SIP Sistem Absensi**.

Dokumen ini berisi panduan dasar bagi seluruh anggota tim dalam proses pengembangan aplikasi agar alur kerja tetap konsisten dan terstruktur.

---

## Branch yang Digunakan

Repository ini menggunakan beberapa branch dengan fungsi sebagai berikut.

| Branch | Fungsi |
|--------|--------|
| `main` | Menyimpan versi aplikasi yang stabil. |
| `develop` | Branch utama untuk proses pengembangan. |
| `feature/*` | Digunakan untuk mengembangkan fitur baru. |
| `hotfix/*` | Digunakan untuk perbaikan bug yang bersifat mendesak (jika diperlukan). |

---

## Alur Pengembangan

1. Pastikan branch `develop` sudah dalam kondisi terbaru.
2. Buat branch baru dari `develop` sesuai fitur yang akan dikerjakan.
3. Lakukan pengembangan pada branch tersebut.
4. Commit perubahan secara berkala dengan pesan yang jelas.
5. Push branch ke GitHub.
6. Setelah fitur selesai, gabungkan perubahan ke branch `develop` sesuai mekanisme yang disepakati oleh tim.

> **Catatan:** Mekanisme Pull Request, Branch Protection, code review, dan CI/CD akan diterapkan pada tahap pengembangan berikutnya sesuai kebutuhan proyek.

---

## Penamaan Branch

Gunakan format berikut:

```text
feature/<modul>-<nama-fitur>
```

Contoh untuk repository **Web**:

```text
feature/web-admin-dashboard
feature/web-admin-approval
feature/tv-dashboard-monitoring
```

Contoh untuk repository **Mobile**:

```text
feature/mobile-login
feature/mobile-attendance
feature/mobile-profile
```

Setiap developer bertanggung jawab membuat branch `feature/*` sesuai dengan fitur yang sedang dikerjakan.

---

## Penulisan Commit

Gunakan pesan commit yang singkat, jelas, dan menggambarkan perubahan yang dilakukan.

Contoh:

```text
feat: menambahkan fitur login
fix: memperbaiki validasi absensi
docs: memperbarui dokumentasi
refactor: merapikan struktur kode
```

---

## Dokumentasi

Apabila perubahan yang dilakukan memengaruhi alur sistem, struktur proyek, atau proses deployment, harap memperbarui dokumentasi yang terdapat pada folder `docs/`.

---

## Catatan

Panduan ini dapat diperbarui sesuai dengan kebutuhan proyek dan perkembangan proses pengembangan.
