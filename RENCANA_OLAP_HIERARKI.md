# Rencana: Hierarki Dimensi & Operasi OLAP yang Benar di Halaman Insight

## Context

Halaman Insight (OLAP Explorer) mengklaim mendukung slice, dice, roll-up, dan drill-down.
Dicocokkan dengan materi Data Warehouse (Silberschatz 11.68–11.70; slide "Summary of
Operations"), hasilnya:

| Operasi | Sekarang | Status |
|---|---|---|
| Pivot | `swapRowsColumns` menukar Baris ↔ Kolom | ✅ benar |
| Slice | "Filter ke ini" mengunci **semua** dimensi titik; dimensinya tetap di Baris | ⚠️ sebenarnya dice |
| Dice | `diceInput` → `A ∈ {…}, B ∈ {…}` | ✅ logika benar, perlu penjelasan |
| Drill-down | "Rinci per…" menawarkan **dimensi apa saja** yang belum dipakai | ❌ bukan turun hierarki |
| Roll-up | lepas dimensi terakhir; bila tinggal satu, lepas **saringan** terakhir | ❌ membuka filter ≠ roll-up |
| Drill-through | "Lihat daftar alumni" (endpoint `drill-down`) | ⚠️ salah istilah |

Akar masalah: `config/olap_catalog.php` hanya punya `dimension_groups` (pengelompokan untuk
tampilan), **tidak ada definisi hierarki** (level ringkas → rinci). Tanpa itu, frontend tidak
tahu bahwa Program studi adalah anak Jurusan.

Batasan: video demo sudah diserahkan → **tidak ada relayout/restyle**. Semua perubahan lewat
interaksi yang sudah ada (dialog aksi titik `PointActionDialog`, tombol roll-up yang ada).

## Hierarki yang dipasang (hasil diskusi)

Urutan ditulis **ringkas → rinci**. Level teratas selalu bisa di-roll-up ke "semua" (dimensi
dilepas).

| Cube | Hierarki | Level |
|---|---|---|
| FactTracerStudy | Program Studi | `DimProdi.jurusan` → `DimProdi.nama_prodi` |
| FactTracerStudy | Lokasi kerja | `DimPerusahaan.nama_provinsi` → `DimPerusahaan.nama_kota` *(kota baru ditambahkan ke katalog)* |
| FactTracerStudy | Lokasi usaha | `DimWirausaha.nama_provinsi` → `DimWirausaha.nama_kota` |
| FactRangeEvaluasi | Program Studi | `DimProdi.jurusan` → `DimProdi.nama_prodi` |
| FactRangeEvaluasi | Pertanyaan | `DimIndikatorEvaluasi.kategori_label` → `DimIndikatorEvaluasi.label_pertanyaan` |
| FactMultiSelect | Program Studi | `DimProdi.jurusan` → `DimProdi.nama_prodi` |

**Tidak** dipasang (sengaja): DIM_WAKTU (waktu ETL, measure semi-additive), DIM_UMP (tabel
acuan), `nama_pt` (single-tenant, satu nilai), `grup_gap` (bukan induk kategori), Status
Alumni / Kesesuaian / Studi Lanjut / Kesesuaian Level / tahun_lulus (satu level → slice/dice
saja). Level fakultas & kategori Terserap/Sesuai → fase opsional (lihat akhir).

## Prinsip desain

1. **Drill-down = sisipkan level anak tepat setelah induknya, induk tetap tampil** (cross-tab
   dengan hierarki, Silberschatz 11.70). Alasan:
   - nama anak tidak unik antar-induk (nama kota kembar antar-provinsi; label pertanyaan
     Kompetensi A dan B bisa sama) — induk yang tetap tampil membuat setiap baris tak ambigu;
   - grafik bertingkat (`buildNestedPlan`) dan subtotal tabel (`buildTableLayout`) sudah
     mendukung susunan [induk, anak].
   - Bila batas dimensi (`maxDimensionsOf`) sudah penuh, induk **diganti** anak; konteksnya
     tetap terbaca dari chip saringan.
2. **Roll-up tidak pernah menyentuh saringan buatan pengguna.** Saringan hasil drill-down diberi
   penanda asal (`origin: "drill"`); roll-up hanya melepas saringan berpenanda itu.
3. **Slice = kunci satu dimensi, lalu dimensi itu keluar dari tampilan** (dimensionalitas
   berkurang, contoh `TIME = day 1`). Mengunci ≥ 2 dimensi sekaligus = Dice.
4. **Kontrak backend tetap kompatibel**: field baru opsional; pertanyaan tersimpan lama tetap
   terbuka.

## Fase 1 — Backend: definisi hierarki di katalog

**`tracer-study-backend/config/olap_catalog.php`**
- Tambah kunci `hierarchies` per cube, mis.
  ```php
  'hierarchies' => [
      'Program Studi' => ['DimProdi.jurusan', 'DimProdi.nama_prodi'],
      'Lokasi kerja'  => ['DimPerusahaan.nama_provinsi', 'DimPerusahaan.nama_kota'],
      'Lokasi usaha'  => ['DimWirausaha.nama_provinsi', 'DimWirausaha.nama_kota'],
  ],
  ```
- Tambah `'DimPerusahaan.nama_kota' => 'Kota tempat kerja'` ke grup "Perusahaan" (tabel yang
  sama → `maxDimensionsOf` tidak berubah).
- Perbarui docblock kepala file: jelaskan `hierarchies` dan kenapa DIM_WAKTU/DIM_UMP tidak ada.

**`app/Services/Analytical/ExplorerService.php` → `catalog()`**
- Kirim `hierarchies` per cube: `[{ name, levels: [key, ...] }]`. Cube tanpa hierarki → `[]`.

**Tes**
- `tests/Unit/Analytical/OlapCatalogConfigTest.php`: setiap level hierarki terdaftar di
  `dimension_groups` cube yang sama; ≥ 2 level; satu dimensi paling banyak di satu hierarki;
  tidak ada duplikat level.
- `tests/Unit/Services/ExplorerServiceTest.php`: `catalog()` memuat `hierarchies`.
- Verifikasi data (sekali, manual, dicatat di PR) — tiap anak punya satu induk:
  ```sql
  SELECT nama_prodi, COUNT(DISTINCT jurusan) FROM dim_prodi GROUP BY 1 HAVING COUNT(DISTINCT jurusan) > 1;
  SELECT nama_provinsi, nama_kota FROM dim_perusahaan GROUP BY 1,2;  -- cek kota kembar lintas provinsi
  ```
  Bila ada prodi pindah jurusan (SCD Type 2), angka per versi tetap benar karena fakta menunjuk
  versi masing-masing; cukup dicatat.
- Pastikan query Cube.js `DimPerusahaan.nama_kota` jalan di cube Terkini (pre-aggregation
  tidak wajib mencakupnya; Explorer boleh jatuh ke query mentah).

## Fase 2 — Frontend: logika murni (`fe-tracer-study/src/lib/olapExplorer.ts`)

**Tipe**
- `CatalogHierarchy { name: string; levels: string[] }`; `CatalogCube.hierarchies?: CatalogHierarchy[]`.
- `ExplorerFilter.origin?: "drill"` — hanya di sisi klien; `toRequestBody` sudah memetakan ke
  `member/operator/values` saja, jadi tidak bocor ke peladen.

**Fungsi baru**
- `levelOf(cube, dim) → { hierarchy, index } | null`
- `childOf(cube, dim)` / `parentOf(cube, dim)` → kunci level tetangga atau `null`.

**Fungsi diubah**
- `drillDownInput(input, cube, point, dim, limit)` *(baru, menggantikan cabang `drillDim` di
  `handleSlice`)*: tambah saringan `dim = nilai` berpenanda drill; sisipkan `childOf(dim)`
  tepat setelah `dim` di `rowDims` (atau ganti `colDim` bila `dim` adalah kolom); bila batas
  penuh, ganti `dim` dengan anaknya.
- `rollUpInput(input, cube)` — aturan berurutan, diterapkan pada dimensi baris terakhir
  (atau `colDim` bila baris kosong):
  1. dimensi = anak dan induknya ada tepat sebelumnya → lepas anak + lepas saringan
     **drill** pada induk (kebalikan persis drill-down);
  2. dimensi = anak tanpa induk di tampilan → ganti dengan induknya (prodi → jurusan);
  3. dimensi level teratas / tanpa hierarki → lepas dimensi (agregasi sampai total);
  4. tidak ada dimensi → `null`. **Saringan pengguna tidak pernah dilepas.**
- `sliceInput(input, dim, value)`: saring `dim = value`, lalu **keluarkan `dim`** dari
  `rowDims`/`colDim`.
- `diceInput`: tidak berubah (sudah benar).
- `drillFilters`: tidak berubah perilaku — dipakai drill-through.

**Tes (`olapExplorer.test.ts`, blok "slice, dice, roll-up")**
- Ganti dua kasus roll-up lama: kasus "lepas saringan aktif terakhir" **dihapus** (perilaku
  salah); tambah kasus aturan 1–4, termasuk "saringan pengguna pada induk tetap utuh".
- Drill-down: sisip setelah induk; ganti induk saat batas penuh; dimensi tanpa anak → tidak
  ditawarkan.
- Slice: satu dimensi terkunci dan hilang dari `rowDims`.
- Round-trip: `rollUpInput(drillDownInput(x)) ≡ x` untuk semua hierarki.

## Fase 3 — Frontend: sambungan UI (tanpa relayout)

**`pages/InsightPage.tsx`**
- `handleSlice(point, dim?)` dipecah: `handleSlice(dim, value)`, `handleDrillDown(point, dim)`.
- `drillDimensions` diganti `drillTargets`: untuk tiap dimensi di titik yang punya anak →
  `{ from: dim, to: child, label: "Jurusan Akuntansi → Program studi" }`.
- `rollUpInput(current, cube)`.

**`components/dashboard/insight/PointActionDialog.tsx`** (isi dialog, susunan sama)
- "Filter ke ini" → satu tombol per dimensi titik: **"Slice: hanya {Jurusan Akuntansi}"**.
  Bila titik punya ≥ 2 dimensi, tombol tambahan **"Dice: kunci semuanya"** (perilaku lama).
- Dropdown "Rinci per…" → tombol **"Drill-down ke {Program studi}"** per target hierarki;
  disembunyikan bila tak ada target.
- Dice: tambah satu kalimat kecil di bawah tombol: *"Hasil memuat semua kombinasi nilai yang
  dipilih."*
- Roll-up: label menyebut tujuan, mis. **"Roll-up ke Jurusan"** / **"Roll-up ke total"**.
- "Lihat daftar alumni" → **"Lihat daftar alumni (drill-through)"** (mode lanjutan saja).

**`components/dashboard/insight/ExplorerResultView.tsx` / `ExplorerControls.tsx`**
- Teruskan props baru; teks `hint` roll-up disesuaikan. Tidak ada komponen baru.

**Tes**: `ExplorerControls.test.tsx` & tes dialog — tombol muncul sesuai hierarki; tidak ada
tombol drill-down di dimensi satu level.

## Fase 4 — Istilah & dokumen

- Komentar kode: bagian "Drill-down: dari satu angka ke daftar alumninya" di `olapExplorer.ts`
  dan docblock `ExplorerDrillDown.tsx` → sebut drill-through. Endpoint
  `/dashboard/explorer/drill-down` **tidak** diganti (kompatibilitas); cukup dicatat.
- ERD/laporan: samakan nama kolom (DIM_WAKTU `*_snapshot`/`tanggal_refresh`, DIM_UMP `tahun`,
  `grup_gap`, `label_sumber_biaya_dipolban`, DIM_PRODI `nama_pt`/`akreditasi_prodi`); tabel
  hierarki diganti tabel di atas; DIM_WAKTU & DIM_UMP dijelaskan sebagai pemilih snapshot dan
  tabel acuan.
- `Katalog_Kebutuhan_TracerStudy.md`: perbarui FR Insight + test case slice/dice/roll-up/
  drill-down/drill-through.

## Verifikasi

1. `php artisan test --filter='OlapCatalogConfigTest|ExplorerServiceTest'`
2. `npm run test -- olapExplorer` dan tes komponen Insight; `npm run build` (tipe).
3. Di aplikasi (mode lanjutan), skenario demo:
   - Jumlah alumni per **Jurusan** → klik Akuntansi → Drill-down ke Program studi → Roll-up ke
     Jurusan (kembali persis, saringan pengguna utuh) → Roll-up ke total.
   - Wirausaha per **Provinsi** → drill-down ke Kota.
   - Kompetensi per **Kategori** → drill-down ke Pertanyaan.
   - Jurusan × Tahun lulus → klik sel → Slice tahun 2023 (kolom Tahun hilang) / Dice keduanya.
   - Pivot (tukar baris-kolom) dan drill-through daftar alumni.
4. Buka satu pertanyaan tersimpan lama → tetap jalan (field baru opsional).

## Status implementasi (2026-10-17)

- Fase 1 ✅ `olap_catalog.php` (`hierarchies`, `DimPerusahaan.nama_kota`), `ExplorerService::catalog()`,
  tes `OlapCatalogConfigTest` + `ExplorerServiceTest` (51 lulus).
  Cek data: prodi→jurusan & pertanyaan→kategori bersih; kota→provinsi **kotor di data dummy**
  (`ResponseSeeder` mengacak kota & provinsi terpisah) → seeder diperbaiki, data perlu di-seed ulang.
- Fase 2 ✅ `parentOf/childOf/drillTargets/drillDownInput/rollUpStep/rollUpInput/rollUpLabel`,
  `sliceInput(dim, value)`; tes unit (251 tes frontend lulus, dijalankan dengan Node 24 —
  Node 20 gagal memuat jsdom).
- Fase 3 ✅ `PointActionDialog` (Slice per dimensi, Dice, Drill-down, Roll-up ke …, drill-through),
  `InsightPage`, `ExplorerResultView`, `ExplorerControls` (keterangan tombol Naik),
  `ExplorerFilterRow` (saringan drill yang diedit jadi milik pengguna).
- Fase 4 ◐ istilah drill-through di kode. ERD (gambar) & katalog kebutuhan belum diubah.
- Verifikasi ✅ seed ulang (`migrate:fresh --seed`) + `etl:run`: kota→provinsi bersih.
  API: jumlah anak = induk (Administrasi Niaga 807 = Σprodi; Jawa Barat 263 = Bandung 129 + Bekasi 134;
  kategori 36.477 = Σpertanyaan; Σjurusan = total 5.211). UI (Playwright, Chromium): Jurusan × Tahun →
  Drill-down Akuntansi → Program studi → Roll-up ke Jurusan (kembali persis) → Slice Tahun lulus
  (kolom hilang) → Roll-up ke total; tanpa error halaman.

- Validasi ulang hierarki: nama prodi **tidak unik** antar-jenjang (7 prodi ada di D3 & D4, mis.
  Akuntansi) → D3 dan D4 tergabung. Diperbaiki dengan dimensi Cube `DimProdi.prodi_jenjang`
  ("D3 Akuntansi") sebagai "Program studi" di katalog & level anak Jurusan; `nama_prodi` tetap
  untuk dashboard lain. Provinsi→kota & kategori→pertanyaan bersih.

## Keputusan yang perlu dikonfirmasi

*Dipakai rekomendasi: dropdown dihapus, slice mengeluarkan dimensi.*

1. **Dropdown "Rinci per…" (tambah dimensi bebas)**: dihapus dari dialog (rekomendasi —
   menambah dimensi tetap bisa dari panel kiri), atau dipertahankan dengan label "Tambah
   rincian lain" (bukan drill-down)?
2. **Slice mengeluarkan dimensi dari tampilan**: setuju (sesuai materi), atau dimensi tetap
   ditampilkan satu nilai seperti sekarang?

## Di luar cakupan / fase opsional

- Level **fakultas** di DIM_PRODI — butuh cek `fakultas_jurusan_scopes` (many-to-many; layak
  hanya jika 1 jurusan = 1 fakultas) + perubahan ETL & skema OLAP.
- Kategori **Terserap/Belum** dan **Sesuai/Tidak** sebagai level dimensi turunan dari
  `kpi_category_mapping` (time-variant per snapshot).
- Atribut `urutan` untuk dimensi ordinal (Kesesuaian, Tingkat instansi).
- Perbaikan tahun minggu ISO di `OlapLoadRepository::insertNewSnapshot` (`format('o')`).
- Typo kunci `id_kesesuaian_level` di `DimKesesuaianBidang.js`.

## Urutan kerja & perkiraan

| Fase | Isi | Perkiraan |
|---|---|---|
| 1 | Katalog + `catalog()` + tes backend + cek data | ½ hari |
| 2 | Logika murni + tes unit | 1 hari |
| 3 | Sambungan UI dialog + tes komponen + uji manual | ½–1 hari |
| 4 | Istilah, ERD, katalog kebutuhan | ½ hari |
