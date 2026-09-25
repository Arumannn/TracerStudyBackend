# Rencana: Rapikan UI halaman Insight agar mudah dipakai & dipahami

## Context

Halaman Insight (`/dashboard/insight`) adalah OLAP Explorer. Pengguna (Ketua Prodi/Fakultas,
admin) menyusun pertanyaan sendiri lewat panel kiri "Susun Analisis", hasilnya muncul di kanan.
Pemilik proyek bilang UI-nya berantakan dan ia sendiri bingung cara memakainya. Ini analisis
hasil membaca `InsightPage.tsx`, `ExplorerControls.tsx`, `ExplorerResultView.tsx`, `rbac.ts`,
`MultidimensiInsightPage.tsx`. Belum ada kode yang diubah (mode analisis).

## Diagnosis: kenapa terasa berantakan

1. **Panel kiri terlalu panjang dan datar (678 baris).** Semua kontrol ditumpuk berurutan dalam
   satu kartu sticky: Sumber Data → Siap pakai (daftar checkbox setinggi 176px) → Hitung dari kolom
   angka → Buat rumus → Kelompokkan (3 dropdown) → Saringan → Olah hasil (persen, n minimum,
   urutkan, arah, top N, selisih dua kolom). Sekitar 15-20 kontrol terlihat sekaligus. Pemula tidak
   tahu mana yang wajib dan mana yang opsional.
2. **Istilah teknis bercampur.** "Sumber Data", "Kelompok utama (baris)", "Bandingkan berdampingan
   per (kolom)", "Olah hasil", "Tampilkan jumlah sebagai", "Selisih dua kolom" — memakai jargon
   pivot (baris/kolom) yang tidak dikenal orang awam.
3. **Tidak ada urutan langkah.** Tidak ada penanda "Langkah 1, 2, 3", dan tidak ada indikasi
   bagian mana yang wajib. Kolom hasil baru terisi setelah minimal satu ukuran dipilih, tapi
   itu tidak dikomunikasikan di panel.
4. **Empty state menumpuk tiga hal.** Ilustrasi + kalimat panjang + contoh (starter) + daftar
   pertanyaan tersimpan dalam satu kartu. Contoh starter cuma tombol teks tanpa penjelasan apa
   yang akan dilihat. Padahal starter adalah jalan masuk terbaik bagi pemula.
5. **Header halaman menyembunyikan fitur.** Pertanyaan tersimpan hanya berupa dropdown kecil di
   pojok kanan atas; tombol Simpan/Sematkan/CSV baru muncul setelah ada hasil, dan ketiganya
   tampil setara (tiga `outline`), jadi tidak jelas mana aksi utama.
6. **Tiga menu yang mirip.** Sidebar: "Multidimensi Insight" (link ke Metabase), "Insight",
   "Dashboard Saya". Deskripsi "Eksplorasi data multidimensi" dan "Susun sendiri analisis
   multidimensi" hampir sama; pengguna tidak tahu bedanya.
7. **Umpan balik lemah.** Setelah memilih sesuatu, tidak ada ringkasan kalimat *sebelum* hasil
   muncul; kalimat ringkasan (`describeQuestion`) baru tampil di atas hasil. Batas (maks 4 ukuran,
   3 dimensi) hanya terlihat sebagai `0/4` kecil atau opsi yang memudar tanpa alasan.
8. **Chart, tabel, dan hint berurutan panjang.** Hasil = kartu angka/chart + Tabel + hint; pada
   layar sedang, panel kontrol mendorong hasil jauh ke bawah (grid `lg:grid-cols-4`, di bawah
   `lg` kontrol menumpuk di atas hasil).

## Prinsip desain yang diusulkan

- **Progressive disclosure:** tampilkan yang wajib dulu, sembunyikan yang lanjutan.
- **Bahasa pengguna, bukan bahasa pivot:** susun sebagai kalimat.
- **Mulai dari contoh, bukan kanvas kosong.**
- **Selalu tunjukkan "apa yang sedang saya lihat"** dalam satu kalimat.
- **Satu aksi utama per tahap.**

## Rancangan yang direkomendasikan

### A. Panel kiri → "Pembangun kalimat" tiga langkah
Ganti daftar panjang dengan tiga kartu bernomor. Logika (`consistent`, `update`, batas katalog,
hook `useDimensionValues`) dipertahankan; hanya susunan dan teks yang berubah.

1. **Apa yang ingin dihitung?** — pilih ukuran (wajib). Ganti daftar checkbox setinggi 176px
   dengan daftar bergrup + kolom cari; ukuran terpilih tampil sebagai chip di atasnya.
   "Hitung dari kolom angka" dan "Buat rumus" dipindah ke tautan "Ukuran lanjutan".
2. **Dibagi menurut apa?** — satu dropdown utama "Per …" (mis. Jurusan). Pemecahan kedua dan
   perbandingan berdampingan ada di bawah "Pecah lagi / bandingkan" (terlipat). Label diganti:
   "Kelompok utama (baris)" → "Per", "Bandingkan berdampingan (kolom)" → "Dibandingkan antar".
3. **Hanya untuk siapa? (opsional)** — saringan; label "Hanya tampilkan data…" → "Batasi ke".

Bagian **"Olah hasil"** (persen, sembunyikan kelompok kecil, urutan/top N, selisih) dipindah ke
`Accordion` terlipat "Pengaturan tampilan" di bawah, bukan di panel utama. Sumber data pindah
ke bagian atas sebagai satu selector kecil (hanya tampil bila ada lebih dari satu sumber).

### B. Ringkasan kalimat langsung (live sentence)
Di atas panel hasil/kontrol, tampilkan `describeQuestion(...)` (sudah ada di `lib/olapExplorer.ts`)
sebagai kalimat besar yang berubah saat pengguna memilih, mis. *"Rata-rata gaji, per jurusan,
hanya angkatan 2023"*. Sebelum ukuran dipilih: *"Pilih apa yang ingin dihitung untuk memulai."*

### C. Empty state berbasis contoh
Pisahkan tiga hal itu:
- **Kartu contoh** (grid 2-3 kolom) dengan judul + satu baris penjelasan "Anda akan melihat …".
  Data sudah ada di `STARTER_QUESTIONS`; tambahkan field `description`.
- **Pertanyaan tersimpan** dipindah ke tab/bagian sendiri di atas: tab "Contoh · Tersimpan
  saya · Dibagikan", menggantikan dropdown pojok kanan atas.
- Teks panduan ringkas: 3 langkah bernomor.

### D. Bar aksi hasil yang jelas
Satu tombol utama ("Simpan" — `default` variant), sisanya di menu `⋯` atau ikon: Sematkan ke
Dashboard Saya, Unduh CSV. Status "(diubah)" jadi badge di samping judul.

### E. Navigasi sidebar
Kelompokkan tiga menu di bawah satu heading "Analisis" dan perjelas: "Multidimensi (Metabase)" →
diberi ikon link-keluar dan deskripsi "Alat analis, tab baru"; "Insight" → "Buat analisis";
"Dashboard Saya" → "Analisis yang disematkan". Ubah `description` di `rbac.ts:252-254`.

### F. Layout responsif
Di bawah `lg`, kontrol jadi `Sheet`/drawer "Susun analisis" dengan tombol tetap di atas hasil,
supaya hasil tidak terdorong ke bawah. Di layar lebar, pertahankan grid 1:3 tetapi panel kiri
scrollable sendiri (sudah `lg:sticky`; tambahkan `max-h` + `overflow-auto`).

### G. Panduan pemakaian ringan
- Tooltip `?` pada istilah (Dibagi menurut / Dibandingkan antar / Persen dari total).
- Pesan batas yang jelas: "Maksimal 4 ukuran — lepas satu untuk menambah".
- Tur singkat sekali-saja (3 balon) untuk pengguna baru, disimpan di `localStorage` (opsional).

## Prioritas (dampak/usaha)

| Tahap | Perubahan | Dampak | Usaha |
|---|---|---|---|
| 1 | Ganti label & teks (A, G tooltip), ubah deskripsi menu (E) | Sedang | Kecil |
| 2 | Empty state contoh + tab tersimpan (C), kalimat langsung (B) | Tinggi | Sedang |
| 3 | Panel kiri 3 langkah + accordion "Pengaturan tampilan" (A) | Tinggi | Sedang-besar |
| 4 | Bar aksi (D), drawer responsif (F), tur (G) | Sedang | Sedang |

Rekomendasi: kerjakan tahap 1 dan 2 dulu — murah dan paling mengurangi kebingungan — lalu
nilai lagi sebelum tahap 3.

## Berkas yang akan diubah

- `fe-tracer-study/src/pages/InsightPage.tsx` — empty state, header, bar aksi, tab tersimpan, kalimat langsung.
- `fe-tracer-study/src/components/dashboard/insight/ExplorerControls.tsx` — pecah jadi langkah + accordion; ganti label. Kemungkinan dipecah jadi subkomponen (`MeasurePicker`, `GroupingPicker`, `FilterSection`, `DisplayOptions`) di folder yang sama.
- `fe-tracer-study/src/components/dashboard/insight/SavedQuestionsList.tsx` — dipakai ulang untuk tab.
- `fe-tracer-study/src/lib/olapExplorer.ts` — tambah `description` pada `STARTER_QUESTIONS` (~baris 850-887).
- `fe-tracer-study/src/lib/rbac.ts:252-254` — deskripsi menu.
- Dipakai ulang tanpa diubah: `describeQuestion`, `availableStarters`, `isRunnable`, `useExplorerCatalog`, `useExplorerQuery`, `useInsightQuestions`, `useInsightBoard`, komponen `ui/*` (Accordion, Tabs, Sheet, Tooltip yang sudah ada).
- Tidak ada perubahan backend.

## Verifikasi

1. `cd fe-tracer-study && npm run build` dan `npx tsc --noEmit` lolos.
2. Jalankan test yang ada: `npx vitest run src/hooks/useInsightBoard.test.ts` dan test lib `olapExplorer` (jika ada).
3. Jalankan dev server, login sebagai head_tracer dan ketua prodi; uji manual:
   - Buka Insight tanpa pilihan → kartu contoh muncul; klik satu → hasil tampil.
   - Susun dari nol: ukuran → per jurusan → saringan; kalimat langsung berubah.
   - Simpan, sematkan, lihat di Dashboard Saya, unduh CSV.
   - Lebar layar 1440px, 1024px, 390px (drawer kontrol).
4. Playwright MCP (tersedia di `.playwright-mcp/`) untuk tangkapan layar sebelum/sesudah.
5. Uji dengan satu pengguna non-teknis: beri tugas "cari rata-rata gaji per jurusan" dan
   ukur apakah selesai tanpa bantuan.

## Keputusan yang perlu dari pemilik proyek

- Mulai dari tahap 1-2 saja, atau langsung sampai tahap 3?
- Apakah pengguna utamanya Ketua Prodi/Fakultas (non-teknis) — bila ya, bagian "Ukuran lanjutan"
  dan "Pengaturan tampilan" harus terlipat secara bawaan.

## Status pengerjaan (2026-09-25)

- **Tahap 1 — selesai:** label panel kiri diganti ke bahasa pengguna dan diberi nomor langkah
  (`ExplorerControls.tsx`), pesan batas 4 ukuran, deskripsi tiga menu (`rbac.ts`).
- **Tahap 2 — selesai:** empty state dipisah jadi `InsightStartPanel.tsx` (langkah bernomor,
  kartu contoh dengan kalimat ringkas otomatis dari `describeQuestion`, tab Contoh / Tersimpan saya /
  Dibagikan). Teks "Menghitung: <kalimat>" saat loading. Dropdown pertanyaan tersimpan di header
  sengaja dipertahankan supaya pengguna tetap bisa berpindah pertanyaan saat hasil sedang tampil.
- **Tahap 3 — selesai (dengan perubahan dari rencana awal):** panel "Susun analisis" dipindah dari
  kolom kiri ke **atas** hasil. Tiga langkah tampil berdampingan (3 kolom di layar lebar, menumpuk di
  layar kecil), hasil memakai lebar penuh. Panel bisa diringkas jadi satu kalimat + tombol "Ubah
  susunan"; otomatis diringkas setelah contoh/pertanyaan tersimpan dibuka. "Pengaturan tampilan"
  (persen, sembunyikan kelompok kecil, urutan, selisih) terlipat bawaan. Pemilih sumber data hanya
  muncul bila ada lebih dari satu sumber. Ini menggantikan drawer responsif (F) di tahap 4.
- **Tahap 4 — selesai sebagian:** bar aksi hasil (D): "Simpan" jadi tombol utama, "Sematkan ke
  Dashboard Saya" dan "Unduh CSV" pindah ke menu "Lainnya", status "(diubah)" jadi badge. Tooltip
  istilah (G): komponen `HelpTip.tsx` di langkah 1-3, "Dibandingkan berdampingan antar", persen,
  dan sembunyikan kelompok kecil. **Belum:** tur pengguna baru (opsional, sengaja ditunda).
- Verifikasi: eslint bersih di berkas yang diubah; `tsc` 6 galat lama, tidak bertambah; 9 test
  `formDraft.test.ts` gagal sejak sebelum perubahan (tidak terkait). Smoke test baru `ExplorerControls.test.tsx` (4 lulus). Cek visual di browser (Playwright, data nyata, login head_tracer) pada 1440/1280/1024/390 px: empty state,
  klik contoh, panel diringkas, menu "Lainnya", panel terbuka — tanpa galat konsol. Temuan: tiga kolom
  di 1024 px terlalu sempit karena sidebar, titik pindah digeser dari `lg` ke `xl`; `aria-label` pada
  tombol "Lainnya" menimpa teks yang terlihat, dihapus.

## Tahap 5 — Samakan gaya dengan dashboard lain (2026-09-25)

Acuan: halaman Employment/Overview/Education. Polanya: pita filter selebar layar yang menempel di
bawah top bar (`GlobalFilters`), label kapital kecil di atas dropdown `h-9`, tombol aksi di kanan,
strip status di bawahnya ("Diperbarui …"), konten `max-w-[1400px]`, tab berbentuk pil.

- `DashboardLayout`: prop opsional `filterBar` di slot sticky yang sama dengan `GlobalFilters`.
- `ExplorerControls` jadi pita filter: DATA · DIHITUNG (popover ukuran) · PER · LALU PER ·
  DIBANDINGKAN · BATASI (popover) · TAMPILAN (popover), tombol Reset di kanan. Hitung dari kolom
  angka dan Buat rumus tetap ada di dalam popover DIHITUNG. Hasil tetap dihitung otomatis (tidak
  ada tombol Terapkan) agar umpan balik langsung.
- Strip status: kalimat pertanyaan sebagai badge + "Diperbarui …" / "Menghitung…".
- `InsightPage`: judul halaman dihapus (sudah ada di top bar), konten `space-y-4 max-w-[1400px]`.
- Tab contoh/tersimpan memakai gaya pil yang sama dengan dashboard.

### Status tahap 5 + pemilih visualisasi ala Metabase (2026-09-25) — selesai, belum di-commit

- **Pita filter** (`ExplorerControls.tsx`, slot `filterBar` di `DashboardLayout.tsx`): label kapital,
  dropdown `h-9`, popover untuk Dihitung / Batasi / Tampilan, tombol Reset, strip status
  (kalimat pertanyaan + "Diperbarui …"). Auto-hitung dipertahankan (tanpa tombol Terapkan).
- **Pemilih visualisasi** (`VizPicker.tsx`, ikon seperti Metabase): Otomatis, Batang, Batang
  mendatar, Garis, Area, Batang bertumpuk (hanya bila >1 seri), Pai (hanya 1 seri dan ≤12 irisan),
  Tabel. Logika di `lib/olapExplorer.ts` (`availableViz`, `applyViz`, tipe `Viz`), 9 test baru.
  Pilihan yang tak lagi tersedia jatuh ke Otomatis. Bentuk chart baru ada di `ExplorerChart.tsx`.
- **Tersimpan bersama pertanyaan:** `query.viz` masuk validasi
  (`InsightQuestionController`) dan normalizer (`InsightQuestionService`, konstanta `VIZ`); kartu
  Dashboard Saya ikut memakainya lewat `display`. Test backend 12 lulus (1 baru). Roundtrip API
  diuji: simpan, baca ulang, nilai asing ditolak 422.
- Legenda chart diperkecil dan netral; tooltip pai memuat persentase; tab contoh bergaya pil.
- Cek visual 1440 px dengan data nyata: semua bentuk chart, tiga popover, empty state, tanpa galat konsol.
- **Belum:** Dashboard Saya belum dicek visual dengan `viz` selain otomatis; layar sempit (390 px)
  belum dicek ulang setelah pita filter; tur pengguna baru.

### Pemilih dimensi dua langkah ala Metabase (2026-09-25) — selesai, belum di-commit

- Inventaris `dim_*` (olap_schema.sql) dibandingkan dengan katalog. Sudah terbuka: prodi, alumni,
  status, kesesuaian, perusahaan (jenis/tingkat/provinsi), wirausaha, studi lanjut, rentang angka.
  **Belum terbuka:** `dim_perusahaan.nama_kota`, `dim_prodi.nama_pt`, `dim_ump` (provinsi/tahun)
  sebagai dimensi, `dim_waktu`. NIM/nama sengaja tidak dibuka (privasi).
- `DimensionPicker.tsx`: pilih tabel dimensi dulu (panel kiri: Perusahaan, Program Studi, Alumni, …),
  lalu sisinya (panel kanan: jenis instansi, tingkat, provinsi / jurusan, jenjang, …), dengan
  pencarian lintas tabel dan tombol Kosongkan. Dipakai di Per, Lalu per, Dibandingkan antar, dan
  Tambah batasan. 5 test baru.
- Katalog: grup "Tempat Kerja" diganti nama jadi "Perusahaan" (`config/olap_catalog.php`).
- Perbaikan layout bersama: kolom konten `DashboardLayout` diberi `min-w-0` supaya tabel lebar tidak
  melebarkan seluruh halaman (top bar dan pita filter ikut terpotong). Employment/Overview dicek: tidak ada overflow.
- Pemicu popover memakai hover netral (`hover:bg-muted`) karena `--accent` tema berwarna cyan terang.
- **Belum:** tombol tukar baris/kolom, dimensi kota kerja / PT / provinsi UMP (perlu ubah katalog + Cube),
  drill hierarki Jurusan → Prodi.
