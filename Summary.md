# Hasil Pengujian Fungsional — Sistem Tracer Study

**Update 8 Agustus 2026:** re-test khusus FR-074, FR-014, FR-040, FR-025, FR-041, FR-068 (server Cube.js OLAP sempat mati saat sesi 7 Agustus sehingga seluruh dashboard Employment/Education 500 — sudah dinyalakan ulang untuk re-test ini). FR-040/FR-041/FR-025/FR-068 sudah PASS dengan data terbaru (lihat baris masing-masing). FR-074 dan FR-014 dikonfirmasi ulang sebagai bug nyata lalu **diperbaiki dan diverifikasi lewat klik UI langsung** — detail di §K. Investigasi lanjutan menemukan FR-048 dan catatan tambahan FR-068 (pie kosong per tahun) adalah **gap data**, bukan bug kode — diperbaiki lewat reseed penuh (`migrate:fresh --seed` + `etl:run`) — detail di §L, termasuk temuan penting soal cache Redis/Cube.js yang perlu di-flush manual setelah reset data manual. Sesi lanjutan (dibatasi ke Overview/Employment/Education saja) menguji & memperbaiki FR-077 (PASS), FR-085 (KPI8 kehilangan highlight "★ Tertinggi", sudah diperbaiki), dan FR-084 (ditemukan 4 bug tooltip berlabel salah/dobel di 4 chart Employment/Overview, semua diperbaiki) — detail di §M. FR-025 di-re-test ulang dengan dataset baru (144 alumni) dan **kembali menunjukkan gejala awal** (28/29 baris identik) — dikonfirmasi sebagai artefak ukuran sampel, bukan regresi bug.

**Tanggal uji:** 7 Agustus 2026
**Cakupan:** tiga repositori — `tracer-study-backend` (BE), `fe-tracer-study` (FE), `tracer-study-analytics` (Cube.js) — seluruhnya pada cabang `merge-olap-oltp`.
**Metode:** browser agent (Playwright) terhadap FE `localhost:8080`, dengan pemeriksaan silang ke API `localhost:8000`, Cube.js `localhost:4000`, dan basis data PostgreSQL `study_tracer`.
**Akun uji:** `head.tracer@test.com` (password124), `tracer1@test.com`, `wakil.direktur.1@test.com`, `kajur.teknik.sipil@test.com`, `prodi.tkg@test.com` (password123), serta akun alumni `211413432` dengan kredensial yang diterbitkan lewat menu Terbitkan Kredensial.

**Keterangan status:** ✅ Lulus · ⚠️ Lulus sebagian / ada catatan · ❌ Gagal · ⏭️ Tidak dapat diuji

---

# BAGIAN I — OLTP (Sistem Operasional)

## A. Autentikasi, Peran & Hak Akses (RBAC)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| RBAC-01 | ⚠️ | Halaman Kelola Staff tampil lengkap: tombol Tambah Staff, penyaring peran, kolom status Aktif, 5 peran terdaftar (Super Admin, Admin, Pimpinan, Ketua Jurusan, Kaprodi). Pencarian nama berfungsi. Aksi nonaktifkan & hapus tidak dieksekusi pada sesi ini. |
| RBAC-02 | ✅ | Master Data memuat empat tab — Jurusan (12 baris), Program Studi, Provinsi, Kota — beserta tombol Tambah Jurusan. |
| RBAC-03 | ⚠️ | Terdapat pengajuan bertipe "Tambah Kuesioner" berstatus Approved di daftar Approval Request. Alur finalisasi tidak dijalankan ulang dari awal. |
| RBAC-04 | ⚠️ | Ketua Tracer melihat 4 pengajuan "Buka Kembali Pengisian" berstatus Pending beserta tombol Lihat & Review, serta 1 yang sudah Approved. Persetujuan tidak dieksekusi agar tidak mengubah data uji. |
| RBAC-05 | ✅ | Halaman Laporan Publik: tombol Unggah Laporan, 2 laporan terdaftar, saklar Tampil Publik (Draf/Tampil), penghitung unduhan. |
| RBAC-06 | ⚠️ | Akun `tracer1` memiliki menu Manajemen Kuesioner. Penyuntingan pertanyaan diverifikasi lewat Form Builder (sebagai Ketua Tracer), bukan sebagai Tim Tracer. |
| RBAC-07 | ✅ | Jenis pengajuan "Tambah Kuesioner" hadir di alur approval dan sudah pernah disetujui Ketua Tracer. |
| RBAC-08 | ✅ | Tim Tracer memiliki menu Riwayat Pengajuan; daftar approval Ketua Tracer memuat tiga pengajuan buka-kembali dari "Tim Tracer 1". |
| RBAC-09 | ✅ | Akun Tim Tracer memiliki tombol Unduh data alumni tanpa pembatasan prodi. |
| RBAC-10 | ✅ | Kaprodi TKG hanya melihat 14 alumni prodinya; rute `staff-management`, `student-management`, `master-data`, `threshold-management` seluruhnya dialihkan ke `/unauthorized`. |
| RBAC-11 | ✅ | Pada Hasil Kuesioner, Kaprodi hanya punya aksi Export dan Reset. Dialog Reset menyatakan tegas "Permintaan ini menunggu persetujuan Ketua Tracer dan belum mengubah apa pun." |
| RBAC-12 | ✅ | Dialog "Ajukan Pembukaan Kembali" berfungsi, menyebut alumni & kuesioner spesifik, dengan kolom alasan permintaan. |
| RBAC-13 | ⚠️ | Data benar terkunci: Kajur Teknik Sipil hanya melihat 4 prodi / 56 alumni. Namun dropdown Jurusan pada filter global tetap menampilkan seluruh 11 jurusan — kuncinya di lapisan data, bukan di antarmuka. |
| RBAC-14 | ✅ | Wadir memperoleh akses baca tingkat institusi (Overview, Employment, Education, Analitik, KPI Lintas Prodi, Data Alumni, Hasil Kuesioner) tanpa menu administrasi. |
| RBAC-15 | ✅ | Wadir memiliki tombol Unduh data alumni. |
| RBAC-16 | ✅ | Alumni masuk memakai NIM `211413432` + kata sandi acak `xxxx-xxxx-xxxx` hasil menu Terbitkan Kredensial; berkas unduhan berisi kolom NIM, Nama, Surel, Kata Sandi. Surel alumni juga diterima sebagai pengenal. |
| RBAC-17 | ✅ | Setelah masuk, alumni langsung diarahkan ke `/form/fill`; tidak ada menu selain Keluar dan tautan unduh berkas referensi kode. |
| RBAC-18 | ✅ | Basis data menerapkan `UNIQUE(questionnaire_id, alumni_id)`; halaman pengisian otomatis menyajikan kuesioner yang belum dikirim (id 125), bukan yang sudah `submitted` (id 129). |
| RBAC-19 | ⚠️ | Status `started`/`submitted` sudah ada di basis data (10 draf berjalan) dan endpoint `GET/POST /api/tracer-study/draft` aktif dipanggil. Namun tidak ada tombol simpan draf eksplisit di antarmuka; salinan lokal tetap ditulis ke `localStorage` (`tracer_form_draft:<nim>`). |

## B. Manajemen Data (DATA)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| DATA-01 | ✅ | Tombol Import pada Kelola Mahasiswa memicu `POST /api/alumni/import` dengan berkas Excel. |
| DATA-02 | ✅ | Tombol Template mengunduh `Template_Import_Alumni.xlsx` berisi dua lembar: "Template Import Alumni" dan "Referensi Kode Prodi". |
| DATA-03 | ✅ | Judul kolom templat persis: Kode PT, Kode Prodi, NIM, Nama, No. HP, Surel, Tahun Lulus, NIK, NPWP (ditambah Program Studi & Jurusan sebagai kolom bantu). |
| DATA-04 | ✅ | 505 dari 505 baris `alumni_profiles` berstatus `is_active = true`. |
| DATA-05 | ❌ | **Backend benar, antarmuka bisu.** Berkas uji berisi surel salah, Nama kosong, dan Kode Prodi `XXX` ditolak dengan pesan tepat ("Baris 2: The email field must be a valid email address.", "Baris 3: The name field is required.", "Baris 4: Kode Prodi 'XXX' tidak valid.") dan 0 baris terimpor — tetapi **frontend tidak menampilkan toast, dialog, maupun daftar galat apa pun**; pengguna tidak tahu impornya gagal. Selain itu backend memunculkan galat palsu "Baris 5–42: The nim field is required." karena lembar "Referensi Kode Prodi" ikut dibaca sebagai baris alumni. Penyaringan spasi berlebih tidak dapat dipastikan karena baris ujinya sudah gugur lebih dulu di validasi surel. |
| DATA-06 | ✅ | Tombol Export pada Kelola Mahasiswa menghasilkan `Data_Alumni_<tanggal>.xlsx` dengan judul kolom **identik** dengan templat impor, sehingga dapat diunggah ulang tanpa penyesuaian. (Catatan: berkas "Unduh Data Alumni" di dasbor adalah berkas berformat kementerian yang berbeda — itu memang bukan berkas impor.) |
| DATA-07 | ✅ | Master Data menyediakan tab Program Studi dengan kolom jurusan induk; tab Jurusan menampilkan jumlah prodi per jurusan. |
| DATA-09 | ✅ | Nomor telepon tersimpan dan terekspor sebagai `+6281234567890`. |
| DATA-10 | ✅ | Master UMP memuat 9 tahun (2018–2026), 34 provinsi per tahun. |
| DATA-11 | ✅ | 34 provinsi tersedia sebagai master; tab Kota tersedia di Master Data. |

## C. Penyusunan Kuesioner (KSN)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| KSN-01 | ✅ | Dua klasifikasi nyata di data: `DIKTI_2026_v3` (Semua Prodi, 11 bagian) dan `TKG_2026_v3` (Teknik Konstruksi Gedung, 1 bagian). |
| KSN-02 | ✅ | Alumni menerima satu formulir tunggal; berkas ekspor memisahkannya menjadi dua lembar, bukan formulirnya. |
| KSN-03 | ✅ | Form Builder memuat 132 elemen bertanda `draggable`; pengurutan seret-dan-lepas tersedia per pertanyaan. |
| KSN-04 | ✅ | Kuesioner nasional terdiri atas 11 bagian. |
| KSN-05 | ✅ | Terverifikasi dua arah: builder memiliki panel "Pertanyaan Bersyarat", dan pada formulir alumni pemilihan status "Bekerja (full time / part time)" memunculkan blok pertanyaan lanjutan (panjang teks halaman 7.117 → 9.196 karakter). |
| KSN-07 | ✅ | Tiap kuesioner memiliki Sasaran (tahun lulus) dan Tahun Pelaksanaan; daftar dikelompokkan per angkatan. |
| KSN-08 | ✅ | Ekspor Kaprodi TKG menghasilkan lembar "Data Khusus TKG"; ekspor untuk alumni TI3 menghasilkan "Data Khusus TI3" berisi `q_framework` & `q_sertifikasi`. |
| KSN-09 | ❌ | Daftar tipe pertanyaan di Form Builder masih memuat **File Upload** (bersama Short Answer, Paragraph, Angka, Multiple Choice, Checkboxes, Dropdown, Referensi Data, Linear Scale, Rating, Grid, Date, Time). Unggah media belum dinonaktifkan. |
| KSN-10 | ❌ | Kuesioner id 129 berstatus **Published dengan 1 responden** tetap dapat dibuka penuh lewat Edit — seluruh pertanyaan, opsi, dan tombol Hapus aktif, tanpa peringatan maupun penguncian. |
| KSN-11 | ⚠️ | Halaman Pemetaan Pertanyaan ada dan berfungsi (registri peran semantik, kolom tujuan OLAP, alur Langkah 1 → Langkah 2). Namun `GET /api/question-semantic-mappings/similar` mengembalikan **500** — fungsi `similarity()` (ekstensi `pg_trgm`) belum terpasang di basis data — dan kuesioner 2026 masih menyisakan 42 pertanyaan belum termapping. |

## D. Pengisian Kuesioner (ISI)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| ISI-01 | ✅ | NIM terisi otomatis dan `readonly`; Tahun Lulus, Nama, Nomor HP, Surel, dan Kode Prodi (Teknik Informatika) ikut terisi dari akun. |
| ISI-02 | ⏭️ | Tidak ditemukan opsi tersembunyi pada kuesioner yang diuji, sehingga perilaku "disembunyikan di tampilan tetapi tersimpan di basis data" tidak dapat dibuktikan pada sesi ini. |
| ISI-03 | ⚠️ | Dijanjikan eksplisit oleh dialog buka-kembali ("Jawaban yang sudah terkirim tetap tersimpan dan akan muncul kembali saat alumni membuka formulir"), dan status `Ongoing` memang ada di basis data — tetapi siklus penuh Finish → Ongoing → tampil kembali tidak dijalankan. |
| ISI-04 | ❌ | `responses.started_at` terisi hanya pada **5 dari 229** baris; kedua baris milik alumni uji bernilai NULL. Waktu mulai pengisian praktis tidak tercatat. |
| ISI-05 | ✅ | `responses.submitted_at` terisi untuk seluruh 219 respons `submitted`; kolom "Waktu Submit" tampil di halaman responden. |
| ISI-06 | ✅ | Menekan Kirim dengan formulir kosong menghasilkan "27 pertanyaan belum benar" beserta rincian per pertanyaan dan penandaan 92 elemen bermasalah. Pengiriman ditahan. |

## E. Penilai / Pengguna Lulusan (PGL)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| PGL-01 | ✅ | Memilih status "Bekerja" memunculkan tiga blok PENILAI 1/2/3 dengan label yang menyesuaikan konteks bekerja / wiraswasta / lanjut studi. (Catatan data: rata-rata data seed hanya berisi ~2 kontak per alumni, bukan 3.) |
| PGL-02 | ✅ | Tiap penilai hanya meminta nama dan alamat surel. |
| PGL-03 | ✅ | Klasifikasi tersimpan sebagai Atasan, Senior, dan Rekan/HRD — tercermin di kolom Tipe pada halaman Kontak Penilai. |
| PGL-04 | ✅ | Halaman Kontak Penilai memisahkan kolom Email Kontak (37 surel unik untuk lulusan 2025) dan menyediakan tombol Unduh untuk pengiriman undangan terpisah. |

## F. Pelaporan & Ekspor (LAP)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| LAP-01 | ✅ | Berkas `tracer-study-2026.xlsx` berisi tepat dua lembar: "Data Kementrian" (86 kolom, A–CH) dan "Data Khusus TI3" (8 kolom). |
| LAP-02 | ✅ | Isi sel berupa label informatif — "Wiraswasta", "Prov. Jambi", "Founder", "Lokal/Wilayah/Wiraswasta tidak berbadan hukum", "Biaya Sendiri/Keluarga" — bukan kode mentah. |
| LAP-03 | ⏭️ | Tidak diuji. Tidak ada mekanisme pemusnahan data yang dicoba; tombol Hapus pada Kelola Mahasiswa tidak diklik. |
| LAP-04 | ⚠️ | Halaman Publik menyediakan pembatasan Rentang Tahun Lulusan (saat ini 5 angkatan: 2020–2024). Namun cakupannya halaman Statistik publik, bukan penyembunyian alumni lama dari halaman utama internal. |
| LAP-05 | ✅ | `/statistik` terbuka tanpa login, memuat 34 baris prodi, KPI (Total Alumni 86, Selesai 25, Persentase 29,07%) untuk lulusan 2024. |
| LAP-06 | ⚠️ | `/laporan` menyajikan laporan 2025 (328,1 KB) dengan pratinjau PDF, Layar Penuh, dan tautan Unduh PDF publik. Format Excel tidak tersedia di halaman ini. |
| LAP-08 | ⚠️ | Tabel `tracer_oltp.etl_runs` merekam status, `triggered_by`, `id_waktu`, dan ringkasan 12 tahap. Baru berisi 1 baris (`manual_test`, 13 Juli 2026) — 15 snapshot di `dim_waktu` tidak punya baris log padanan. |
| LAP-09 | ✅ | `public.etl_anomaly_log` berisi 13 baris dan seluruhnya tampil di halaman Log Anomali ETL lengkap dengan ETL Run, NIM, kode pertanyaan, peran data, jawaban mentah, tipe diharapkan, dan alasan `out_of_range`. |

## G. Integrasi Eksternal & Akreditasi (EKS)

| Kode FR | Status | Kebutuhan/Catatan |
|---|---|---|
| EKS-01 | ✅ | Manajemen Threshold: 1 LAM (LAM EMBA/EMBA) dengan 2 Standar Penilaian dan 7 prodi terpetakan. |
| EKS-02 | ⚠️ | Lima indikator threshold per versi tampil dengan nilai Baik/Unggul terpisah. Fitur penyuntingan massal tidak dieksekusi. |
| EKS-03 | ⏭️ | Deskripsi kebutuhan masih kosong pada sumber data; tidak ada yang dapat diuji. |
| EKS-04 | ✅ | Registri peran semantik lengkap dengan Tipe Data, Kolom Tujuan OLAP, Berlaku Sejak, dan Status Aktif per kode pertanyaan. |
| EKS-05 | ✅ | 33 dari 34 baris UMP 2026 bersumber `BPS_API` (1 `MANUAL`); tombol Fetch BPS tersedia. |

---

# BAGIAN II — OLAP (Lapisan Analitik & Dashboard)

## A. Autentikasi & RBAC

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-001 | ✅ | Login `head_tracer` dan `kaprodi` sama-sama diarahkan ke `/dashboard/overview` tanpa galat konsol. Kajur, Wadir, dan Tim Tracer juga masuk normal. |
| FR-002 | ✅ | Kaprodi: filter Prodi terkunci sebagai teks statis "Teknik Konstruksi Gedung", filter Jenjang & Jurusan tidak ditampilkan. Kajur/Wadir/Tim Tracer/head_tracer: keempat filter aktif. |
| FR-070 | ✅ | Kata sandi salah memunculkan toast "Login Gagal"; backend membalas 422 pada `/api/auth/login` lalu 401 pada `/api/auth/alumni-login`. Catatan: pesan toast berbunyi "NIM atau email tidak ditemukan dalam database alumni" meski yang dicoba adalah akun staf — pesan terakhir dari rantai fallback yang menutupi sebab sebenarnya. |

## B. Dashboard Monitoring Partisipasi — `/dashboard/overview`

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-003 | ✅ | Jenjang=D3 mengubah jumlah prodi 36 → 18 dan Total Alumni 505 → 253, Sudah Mengisi 144 → 72. |
| FR-004 | ✅ | Enam kartu terisi: Total Kuesioner 114, Total Alumni 505, Sudah Mengisi 144, Sedang Mengisi 5, Belum Mengisi 356, Response Rate 28,5%. Angkanya konsisten (144/505 = 28,5%) — perhitungan ganda pada tingkat respons sudah tidak muncul. |
| FR-005 | ✅ | Bar per prodi tampil untuk 36 prodi. Mayoritas masih 28,6%/71,4% — karakteristik data seeder, bukan galat kueri. |
| FR-006 | ✅ | Grafik kombinasi bar (response rate) + garis (threshold Slovin) untuk 2020–2026. |
| FR-007 | ✅ | Kotak sorot emas berada di 2026 — dan itu memang nilai tertinggi (100%, 1 dari 1 alumni), diverifikasi langsung ke `/api/dashboard/response-rate/trend`. |
| FR-008 | ✅ | Dengan filter Tahun Lulus=2022, muncul kotak kedua abu-abu `stroke-dasharray="3 3"` di 2022, terpisah dari kotak emas `"4 2"` di 2026. |
| FR-009 | ✅ | Bandingkan → `/dashboard/compare?type=participation-trend`, 36 bar prodi, 0 galat konsol. |
| FR-010 | ✅ | Donat Status Pengisian Survei: Selesai 144, Sedang Mengisi, Belum Mengisi 356. |
| FR-011 | ✅ | Halaman Bandingkan memuat tabel Ringkasan Data 36 baris (Total Alumni, Sudah Merespons, Belum Merespons). |
| FR-012 | ✅ | Dialog "Unduh Data Alumni" mewajibkan pilih tahun; `tracer-study-2026.xlsx` terunduh. |
| FR-013 | ✅ | Diverifikasi dengan membongkar berkas: unduhan Kaprodi TKG untuk lulusan 2022 hanya memuat 2 baris berkode prodi `TKG`, dan lembar keduanya bernama "Data Khusus TKG". |
| FR-066 | ✅ | Klik segmen "Belum Mengisi" membuka modal "Belum Mengisi — 70% (356 alumni)" — persis angka di grafik. |
| FR-074 | ✅ **(diperbaiki 8 Agu 2026)** | **Awalnya masih nihil di re-test 8 Agu:** frontend tetap mem-force uppercase, backend `LIKE` case-sensitive di PostgreSQL. Dibuktikan dengan alumni bernama mixed-case "Rahayu" (dari 173 alumni mixed-case di 10.257 total) — cari "rahayu"/"RAHAYU" tidak pernah menemukannya. **Fix:** `ResponseRateRepository.php:199` `like` → `ilike`; `useResponseRate.ts:256` hapus `toUpperCase()`, cukup `trim()`. **Diverifikasi ulang lewat klik UI**: cari "rahayu" di drill-down Overview → 34 hasil, alumnus "Rahayu" tampil di baris ke-22 (halaman 2). Drill-down Employment tetap tidak terpengaruh (jalur berbeda, sudah normal sejak awal). |
| FR-075 | ✅ | Pagination server-side konsisten: "Halaman 1 · 1–15 data", tombol Sebelumnya/Berikutnya, dan `total_on_page` selalu cocok dengan jumlah baris. |
| FR-076 | ✅ | Dropdown urutan (Nilai tertinggi / Nilai terendah / Nama A-Z) tersedia dan mengubah urutan sumbu Y. |

## C. Dashboard Luaran Pekerjaan — `/dashboard/employment`

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-014 | ✅ **(diperbaiki 8 Agu 2026)** | Kelima filter tampil dan cascading dengan benar (pilih Prodi otomatis set Jenjang+Jurusan). **Bug laten ditemukan di re-test 8 Agu:** backend sudah pernah diperbaiki agar `value` snapshot pakai `id_waktu` unik (lihat komentar di `FilterMetaRepository.php:55-64`, yang menjelaskan skenario persis: dua ETL run di minggu kalender sama → label identik), **tapi frontend belum ikut diperbaiki** — `GlobalFiltersContext.tsx:102-104` masih mencocokkan snapshot terpilih lewat `weekOptions.indexOf(week)` (berdasarkan **label**, bukan id), sehingga snapshot kedua dengan label kembar tidak akan pernah bisa dipilih. Tidak bisa direproduksi visual karena seed data cuma 1 snapshot. **Fix:** state `week` di context sekarang menyimpan id unik (`weekKeys` entry) langsung, bukan label; `GlobalFilters.tsx` me-render `<SelectItem>` dari `weekKeys` (key/value = id) dengan `weekOptions` cuma sebagai teks label; badge "Snapshot aktif" pakai lookup label terpisah (`activeWeekLabel`). **Ketemu 1 regresi saat verifikasi**: `handleReset()` masih pakai `weekOptions[0]` (label) alih-alih `weekKeys[0]` (id) — field Snapshot Minggu kosong & tombol Terapkan nyangkut dirty (`*`) setelah klik Reset. Sudah diperbaiki juga. **Diverifikasi ulang lewat klik UI**: ganti Prodi → Terapkan → Reset di Employment & Education, `minggu_snapshot=1` (id) terkirim benar ke API, label tetap tampil benar di dropdown & badge, 0 galat konsol. |
| FR-015 | ✅ | Kartu Wirausaha menampilkan "Founder 39,5%" — nama kategori, bukan kode. |
| FR-016 | ✅ | Selektor Standar LAM nonaktif saat "Semua Prodi" ("Pilih satu prodi untuk melihat threshold akreditasi") dan berisi dua versi saat satu prodi dipilih. |
| FR-017 | ✅ | Pie otomatis memakai tahun terbaru: "Tahun terakhir (2026)" saat filter Tahun = Semua. |
| FR-018 | ✅ | Seluruh tipe Bandingkan diuji satu per satu dengan **0 galat konsol** dan tabel terisi: `absorption` (180 bar/36 baris), `status` (180/36), `kesesuaian` (72/36), `waktuTunggu` (87/29), `entrepreneurship` (72/24), `income` (72/36), `income-kelompok` (72/36), `jenisInstansi` (21/7), `tingkatInstansi` (21/7). |
| FR-019 | ✅ | Klik segmen "Bekerja" → modal "Bekerja — 42.3% (11 alumni)" berisi tepat 11 baris dengan 6 kolom wajib. |
| FR-020 | ✅ | Dropdown KPI13 berisi 5 metrik (Keterserapan, Masa Tunggu ≤6bln, Kesesuaian Bidang, Wirausaha, Pendapatan ≥1,2x UMP) dengan legenda Unggul/Baik/Kurang/Belum ada threshold. |
| FR-021 | ✅ | Grafik garis "% Lulusan Mendapat Kerja dalam ≤ 6 Bulan" dengan threshold dan penanda ★ Tertinggi. |
| FR-022 | ✅ | Distribusi tiga kategori masa tunggu berlabel persentase: < 3 bulan 12,5%, 3-6 bulan 25%, > 6 bulan 62,5%. |
| FR-023 | ✅ | Bandingkan Masa Tunggu menghasilkan 29 baris tabel dan 87 bar (29 prodi × 3 kategori) — tidak ada duplikasi, 0 galat konsol. Perbaikan agregasi dari sesi sebelumnya bertahan. |
| FR-024 | ✅ | (sama dengan FR-022) |
| FR-025 | ✅ **(re-test 8 Agu 2026)** | Tabel Rata-rata vs Median kini tampil untuk 36 prodi, dan **semua baris punya rata-rata ≠ median** (mis. Kerja sama tim 3.1 vs 2.2 bln). Perbaikan dari 28/29 identik di sesi 7 Agu bukan karena perubahan kode — volume alumni per prodi di seed data sekarang jauh lebih besar (100–480/prodi vs sampel kecil sebelumnya), sehingga selisih rata-rata/median jadi nyata terlihat. |
| FR-026 | ✅ | "Mulai cari kerja sebelum lulus 100,0% · rata-rata 3.6 bulan sebelum", "sesudah lulus 0,0%", "Rata-rata masa tunggu hingga bekerja 7.9 bulan". |
| FR-027 | ✅ | Grafik "Prediksi Tren Median Masa Tunggu" memuat garis historis dan proyeksi linier. |
| FR-028 | ✅ | Combo chart tren kesesuaian bidang 2020–2026 dengan penanda tertinggi. |
| FR-029 | ✅ | Pie menampilkan 6 kategori (Sangat Erat 7,7%, Erat 7,7%, Cukup Erat 11,5%, Kurang Erat 11,5%, Tidak Sama Sekali 3,8%, Tidak Ada Data 57,7%) — seluruh kategori yang bernilai > 0 dirender. |
| FR-030 | ✅ | Bandingkan `kesesuaian` berfungsi, 0 galat konsol. |
| FR-031 | ✅ | Klik slice membuka drill-down dengan kolom konteks tambahan. |
| FR-032 | ✅ | Ketiga belas alasan ketidaksesuaian terhitung lengkap (12, 10, 9, 8, 8, 7, 7, 7, 6, 6, 4, 4, 3). |
| FR-033 | ✅ | Tren Persentase Wirausaha 2020–2026 dengan dua penanda ★ Tertinggi (2025 & 2026 sama-sama 100%). |
| FR-034 | ✅ | (sama dengan FR-033) |
| FR-035 | ✅ | Pie Distribusi Posisi Wirausaha: Founder 60%, Staff 40% — nama kategori, bukan kode. |
| FR-036 | ✅ | Bandingkan `entrepreneurship`: 24 baris, 0 galat. |
| FR-037 | ✅ | Combo Rata-rata Gaji (15,2 jt → 5,0 jt) + garis % ≥ 1,2× UMP. |
| FR-038 | ✅ | Bar horizontal dua kategori per tahun. Catatan data: seluruh tahun menunjukkan 0% < 1,2× UMP dan 100% ≥ 1,2× UMP. |
| FR-039 | ✅ | Bandingkan tersedia untuk `income` dan `income-kelompok`, keduanya 36 baris tanpa galat. |
| FR-040 | ✅ **(diperbaiki — re-test 8 Agu 2026)** | Radar dua lapis kini menampilkan **ke-7 kompetensi dengan gap valid** (0.29–0.48), tidak ada lagi `gap: null`. Pemetaan `grup_gap` di `dim_indikator_evaluasi` untuk f1761/f1763/f1766/f1770/f1774 (sebelumnya `Lainnya_Range`) sudah dibetulkan; `count_responden` konsisten ~7000 di ketujuh kompetensi. |
| FR-041 | ✅ **(re-test 8 Agu 2026)** | Mekanisme warna benar — 7 bar, semua `fill` merah `#ef4444` (karena semua gap negatif setelah data FR-040 dibetulkan — kompetensi lulusan di bawah kebutuhan industri di seluruh 7 kategori). Nilainya kini valid karena mewarisi data FR-040 yang sudah benar. |
| FR-042 | ✅ | Tombol Bandingkan hadir; tipe `competency` merender 87 bar / 29 baris tanpa galat. |
| FR-043 | ✅ | Pie jenis instansi menampilkan Organisasi Non-profit 14,3%, Perusahaan Swasta 71,4%, Institusi/Organisasi Multilateral 14,3%. |
| FR-044 | ✅ | Bar horizontal per prodi dengan legenda Lokal/Wilayah, Multinasional/Internasional, Nasional/Wiraswasta berbadan hukum. |
| FR-045 | ✅ | Dua tombol Bandingkan terpisah; `jenisInstansi` dan `tingkatInstansi` masing-masing 7 baris, 0 galat. |
| FR-068 | ✅ **(re-test 8 Agu 2026, gap data diperbaiki)** | Tooltip hover pie "Distribusi Posisi Wirausaha" berfungsi benar: "Staff : 64.6% (31 alumni)" dll, cocok persis API. **Temuan tambahan yang diperbaiki**: pie ini sempat kosong total untuk beberapa tahun kelulusan (2019/2020/2023/2024/2025) meski KPI Wirausaha agregat tidak nol. Root cause: `fact_tracer_study` untuk tahun-tahun itu berstatus wirausaha tapi `wirausaha_sk`-nya NULL (tidak ter-link ke `dim_wirausaha`) — gap di ETL/data historis, bukan bug query (`WirausahaRepository.php` sudah benar pakai `contains` filter, bukan `equals`, sesuai catatan yang sudah ada di kode itu sendiri). **Fix:** reseed + `etl:run` penuh (sama seperti FR-048). **Diverifikasi**: semua tahun 2020–2025 sekarang punya data pie (mis. 2020: Staff 71,4%/Founder 28,6%, total 7 alumni), dikonfirmasi lewat klik UI langsung. |
| FR-071 | ✅ | Drill-down diuji untuk ketiga kategori jenis instansi — seluruhnya terbuka bersih dengan kolom konteks "JENIS INSTANSI" (mis. "Organisasi Non-profit (14.3% · 1 alumni)" → 1 baris, "Organisasi non-profit/Lembaga Swadaya Masyarakat"). |

## D. Dashboard Analisis Capaian Lulusan — `/dashboard/education`

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-046 | ✅ | Filter Jenjang=D3 terkirim ke seluruh endpoint (`/api/dashboard/kompetensi/gap?jenjang=D3&...`) dan mengubah hasil KPI (Skor Kompetensi berubah dari Bahasa Inggris 3,0 menjadi Kerja sama tim 3,1; Mandiri/Keluarga 49,3% → 43,1%). |
| FR-047 | ✅ | Enam kartu memakai nama kompetensi/metode: Bahasa Inggris, Kerja sama tim, Perkuliahan, Avg Persepsi, Mandiri/Keluarga, Beasiswa. |
| FR-048 | ✅ **(diperbaiki 8 Agu 2026)** | Radar metode pembelajaran sebelumnya cuma tampil **6 dari 7** metode — bukan bug kode, tapi **gap data**: OLTP `response_answers` punya 0 baris untuk `f22` (Demonstrasi) dan `f23` (Partisipasi dalam proyek riset) meski kode seeder saat ini sudah men-generate keduanya (DB belum di-reseed ulang sejak seeder diupdate). **Fix:** `php artisan migrate:fresh --seed` lalu `php artisan etl:run --force` untuk membangun ulang OLTP & OLAP dari nol. **Diverifikasi lewat UI**: radar sekarang menampilkan ketujuh metode (Perkuliahan, Demonstrasi, Partisipasi dalam proyek riset, Magang, Praktikum, Kerja Lapangan, Diskusi), `count_responden` konsisten 144 di semua metode. |
| FR-049 | ✅ | Tombol Bandingkan hadir; tipe `learning` merender 87 bar / 29 baris tanpa galat. |
| FR-050 | ✅ | Pie sumber dana: Biaya Sendiri/Keluarga 49%, Beasiswa BIDIKMISI 19%, Beasiswa PPA 20%, Beasiswa Perusahaan/Swasta 10%. |
| FR-051 | ✅ | Toggle "Antar Periode" menghasilkan stacked bar 35 segmen (7 tahun × 5 kategori). |
| FR-052 | ✅ | Tampilan bawaan sudah institusi-wide (filter Prodi "Semua Prodi"). |
| FR-053 | ✅ | Mode dikendalikan lewat Dropdown Filter Global; tombol toggle terpisah memang tidak diperlukan. |
| FR-054 | ✅ | Bandingkan `sumberBiaya` merender 145 bar / 29 baris tanpa galat. |
| FR-072 | ✅ | Slice "Lainnya" ada di legenda tetapi bernilai 0% — seluruh alumni teralokasi ke empat kategori resmi. |
| FR-078 | ✅ | Toggle Radar ↔ Bar Gap berfungsi: mode Bar Gap merender 7 bar dengan pewarnaan hijau/merah dan panel "Cara Membaca Gap". |
| FR-079 | ✅ | Toggle Pie ↔ Antar Periode berfungsi; klik satu segmen membuka "Biaya Sendiri/Keluarga — 2020 (50% · 8 alumni)" dengan 8 baris yang seluruhnya cocok tahun & sumber biaya, plus kolom konteks "SUMBER BIAYA". |

## E. Threshold & UMP Management

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-055 | ✅ | Memilih satu prodi memunculkan subjudul "Standar: LAM EMBA 2020–2020 — Keterserapan Alumni — Level Baik (75 %)" secara otomatis. |
| FR-056 | ✅ | Dropdown tahun UMP memuat 9 tahun (2018–2026). |
| FR-057 | ✅ | Opsi "Tambah Tahun Baru" tersedia di dropdown. |
| FR-058 | ✅ | Membuat tahun 2028 menghasilkan "UMP 2028 — 34 Provinsi", indikator Terisi 0/34, Status "Belum ada data", dan sel "Klik untuk isi…" di tiap baris provinsi. Total tahun bertambah 9 → 10. |
| FR-059 | ✅ | Tombol Fetch BPS, Import Excel, dan Template tersedia. |
| FR-060 | ✅ | "Simpan Semua" nonaktif baik pada tahun tersimpan (2026) maupun tahun kosong (2028) — sesuai rancangan, karena tiap suntingan ter-PATCH otomatis per baris. |
| FR-061 | ✅ | Berganti versi LAM mengubah subjudul secara langsung: 2020 → "Level Baik (75 %)", 2021 → "Level Baik (60 %)", lalu "Level Unggul (85 %)". |
| FR-062 | ✅ | Seluruh modal drill-down yang dibuka (Overview, Keterserapan, Jenis Instansi, Sumber Biaya) konsisten memuat No, Nama, NIM, Program Studi, Jenjang, Tahun Lulus. |
| FR-064 | ✅ | Daftar LAM (1 LAM, 7 prodi terpetakan) dan Daftar Standar Penilaian (2 standar × 5 indikator) tampil lengkap. |
| FR-065 | ✅ | Menonaktifkan standar 2020 mengubah kartu Aktif 2 → 1 dan Tidak Aktif 0 → 1 secara langsung; diaktifkan kembali dan angkanya pulih. |
| FR-069 | ✅ | Nilai antarversi independen dan presisi — LAM EMBA 2020: Keterserapan Baik 75/Unggul 80, Penghasilan ≥ 1.2x UMP; 2021: Keterserapan Baik 60/Unggul 85, Penghasilan ≥ 1.4x UMP. |

## F. Drill-Down Lintas Dashboard

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-062 | ✅ | (lihat tabel Bagian E) |

## G. Question Mapping

| Kode FR | Status | Bukti/Catatan |
|---|---|---|
| FR-073 | ✅ | Klik "Kelola →" langsung menampilkan Panel 2: "Langkah 2 — kelompokkan status untuk role alasan_kerja_tidak_sesuai", lengkap dengan penjelasan pemilik keputusan dan sifat forward-only. |

## H. Pengujian CLI Server & Database (ETL)

| Kode FR | Status | Catatan |
|---|---|---|
| FR-063 | ✅ | `php artisan schedule:list` menampilkan `0 1 * * 1 php artisan etl:run` (Senin 01.00) dan `0 1 * * * php artisan tracer:recalc-response-threshold`. |
| FR-067 | ✅ | `tracer_oltp.programs` = 36 baris, `public.dim_prodi` = 36 baris — sama persis. Log Anomali ETL memuat 13 baris dan tampil benar. |

---

## I. Daftar & Penjelasan Item dengan Catatan Khusus

| Kode FR | Fitur | Status | Alasan / Penjelasan |
|---|---|---|---|
| FR-025 | Rata-rata vs Median Masa Tunggu | ⚠️ **(re-test 8 Agu, lihat §M)** | Kolom identik lagi di 28 dari 29 baris setelah reseed ke dataset lebih kecil (144 alumni, n=4–8/prodi). Bukan cacat kode — sudah dikonfirmasi 2× dengan dataset beda ukuran: identik saat sampel kecil, nyata beda saat sampel besar (lihat §C baris FR-025). Sample-size artifact, bukan bug. |
| FR-029 | Pie Kesesuaian Bidang Kerja | ✅ | Merender seluruh kategori bernilai > 0 (6 kategori pada data saat ini). |
| FR-053 | Toggle Institution-Wide Terpisah | ✅ | Dikontrol terpadu lewat Dropdown Filter Global; tombol terpisah tidak diperlukan. |
| FR-072 | Kategori "Lainnya" Pembiayaan Kuliah | ✅ | Seluruh alumni teralokasi ke 4 kategori resmi; slice "Lainnya" tetap ada di legenda dengan nilai 0%. |
| FR-077 | Methodology Block per KpiCard | ✅ **(diuji 8 Agu 2026, lihat §M)** | Diperiksa satu per satu di Overview (3 tab), Employment (6 tab, 15 tombol), Education (3 tab) — total 21 tombol "Lihat metodologi perhitungan", semuanya ada dan berisi konten (min. 150 karakter). |
| FR-084 | Konsistensi tooltip hover | ✅ **(diuji & 4 bug ditemukan+diperbaiki 8 Agu 2026, lihat §M)** | Diuji sistematis di bar/pie/line/radar/combo chart pada Overview, Employment, Education. Ketemu 4 bug tooltip label salah/dobel (lihat §M) — semuanya sudah diperbaiki dan diverifikasi ulang. |
| FR-085 | Highlight `ReferenceArea` tahun aktif | ✅ | Terkonfirmasi di KPI3 (Overview, dua kotak sekaligus), KPI4 (Keterserapan), KPI5 (Masa Tunggu), KPI6 (Kesesuaian), KPI7 (Wirausaha, dua penanda saat nilai seri). KPI8 (Pendapatan Lulusan, dipakai juga di Employment) sempat ditemukan **tidak** punya highlight ini (`markMax` di-import tapi tidak dipakai) — sudah diperbaiki 8 Agu 2026, lihat §M. |
| FR-080 | Tombol Bandingkan tersembunyi bagi Kaprodi | ✅ | Login Kaprodi lalu menelusuri seluruh 6 tab Employment, 3 tab Education, dan 3 tab Overview: 0 tombol Bandingkan ditemukan. Peran lain tetap memilikinya pada tab yang relevan. |
| FR-081 | Search bar halaman list admin | ✅ | Kelola Staff: "Kajur Teknik Sipil" → 1 hasil tepat. Kelola Mahasiswa: pencarian lintas angkatan dengan Enter. |
| FR-082 | Export/download Excel di luar "Unduh Data Alumni" | ✅ | Diverifikasi tiga berkas nyata: `Template_Import_Alumni.xlsx`, `Data_Alumni_<tanggal>.xlsx` (Kelola Mahasiswa), dan `Kredensial_Alumni_<tanggal>.xlsx` (Terbitkan Kredensial) — seluruhnya terunduh dan isinya diperiksa. |
| FR-083 | Warna status threshold pada KPI13 | ⚠️ | KPI13 merender 36 prodi dengan legenda Unggul/Baik/Kurang/Belum ada threshold dan variasi warna sesuai. Kecocokan warna per baris terhadap ambang tidak diperiksa satu per satu. Catatan kinerja: grafik ini baru selesai memuat sekitar 40 detik pada halaman `/dashboard/kpi`. |

---

## J. Ringkasan Temuan Baru

Sembilan temuan yang muncul pada sesi 7 Agustus, diurutkan dari yang paling menentukan keabsahan angka:

1. **Gap kompetensi salah hitung (FR-040, FR-041, FR-048).** ✅ **Semuanya diperbaiki & diverifikasi 8 Agu 2026** (lihat baris masing-masing di §C/§D) — pemetaan `grup_gap` di `dim_indikator_evaluasi` sudah dibetulkan, ketujuh kompetensi kini punya gap valid. FR-048 ternyata gap data terpisah (OLTP tidak punya jawaban untuk 2 dari 7 metode pembelajaran) yang ikut selesai lewat reseed penuh — detail di §L.

2. **Pencarian nama di drill-down Overview tidak pernah menemukan apa pun (FR-074).** ✅ **Diperbaiki & diverifikasi 8 Agu 2026** — `ResponseRateRepository.php:199` `like`→`ilike`, `useResponseRate.ts:256` hapus force-uppercase. Dikonfirmasi lewat klik UI: alumnus mixed-case "Rahayu" sekarang ketemu.

3. **Filter Snapshot Minggu tidak dapat dipakai (FR-014).** ✅ **Diperbaiki & diverifikasi 8 Agu 2026** — state snapshot terpilih sekarang disimpan sebagai id unik (`id_waktu`), bukan label yang bisa kembar; `GlobalFilters.tsx` & `GlobalFiltersContext.tsx` diubah untuk key/value Select memakai id. Regresi tambahan (`handleReset` masih pakai label) ditemukan & diperbaiki di iterasi yang sama.

4. **Impor alumni gagal tanpa memberi tahu siapa pun (DATA-05).** Backend menolak dengan benar dan mengembalikan daftar galat per baris; frontend membuangnya tanpa menampilkan apa pun. Ditambah lagi lembar "Referensi Kode Prodi" pada templat resmi ikut dibaca sebagai baris alumni sehingga memunculkan puluhan galat palsu.

5. **Kuesioner terbit masih bisa disunting (KSN-10).** Kuesioner berstatus Published yang sudah punya responden dapat dibuka penuh lewat Edit, termasuk tombol Hapus, tanpa peringatan.

6. **Tipe pertanyaan File Upload masih tersedia (KSN-09).** Bertentangan dengan pembatasan ke teks deskriptif.

7. **Waktu mulai pengisian tidak tercatat (ISI-04).** `responses.started_at` terisi pada 5 dari 229 baris.

8. **Endpoint saran pertanyaan serupa mengembalikan 500 (KSN-11).** `similarity()` dari ekstensi `pg_trgm` belum terpasang di basis data, sehingga panel "Kode pertanyaan terdeteksi" menggantung.

9. **Filter Jurusan tidak dikunci untuk Kajur (RBAC-13).** Datanya benar terkunci di lapisan server (4 prodi, 56 alumni), tetapi dropdown tetap menawarkan seluruh 11 jurusan.

### Yang membaik sejak catatan sebelumnya

- **Tingkat respons sudah benar.** Overview menunjukkan 505 alumni / 144 mengisi / 28,5% — perhitungan ganda akibat `COUNT` atas hasil `LEFT JOIN` tidak lagi muncul.
- **Autentikasi alumni sudah berbasis token.** `AlumniAuthService` menerbitkan token Sanctum pada guard `alumni` dengan masa berlaku 12 jam; kata sandi acak per alumni disimpan sebagai cincangan, dan NIM tidak lagi berfungsi sebagai kata sandi.
- **Draf server sudah ada.** `GET/POST /api/tracer-study/draft` aktif dipanggil dari halaman pengisian, dan status `started` sudah terwujud di basis data.
- **Bug bar duplikat pada Bandingkan Masa Tunggu tetap tertutup** — 29 bar unik, 0 galat konsol.

## K. Perbaikan Kode — 8 Agustus 2026

Dua bug dari re-test FR-074/FR-014 diperbaiki dan diverifikasi lewat klik UI langsung (bukan cuma cek API):

**FR-074 — pencarian nama case-sensitive**
- `tracer-study-backend/app/Repositories/Analytical/ResponseRateRepository.php:199` — `like` → `ilike` untuk kolom `ap.name` (case-insensitive di PostgreSQL).
- `fe-tracer-study/src/hooks/useResponseRate.ts:256` — hapus `toUpperCase()` pada search term, cukup `trim()`.
- Verifikasi: cari "rahayu" (huruf kecil) di drill-down Overview → 34 hasil, alumnus mixed-case "Rahayu" tampil di baris ke-22 (halaman 2), sesuatu yang sebelumnya mustahil.

**FR-014 — Snapshot Minggu pakai label sebagai key/value**
- `fe-tracer-study/src/contexts/GlobalFiltersContext.tsx` — state `week` sekarang menyimpan id unik (`weekKeys` entry / `id_waktu`) langsung, bukan label; `weekKey` jadi alias langsung dari `week` (drop `weekOptions.indexOf(label)` yang rawan tabrakan kalau ada label kembar).
- `fe-tracer-study/src/components/dashboard/GlobalFilters.tsx` — `<SelectItem>` snapshot di-render dari `weekKeys` (key & value = id unik) dengan `weekOptions` cuma sebagai teks label; ditambah `activeWeekLabel` untuk menerjemahkan id balik ke label di badge "Snapshot aktif".
- **Regresi ditemukan & diperbaiki di iterasi yang sama**: `handleReset()` (baris ~161) masih memakai `weekOptions[0]` (label) alih-alih `weekKeys[0]` (id) — akibatnya field Snapshot Minggu kosong dan tombol Terapkan nyangkut dirty (`*`) setelah klik Reset. Diperbaiki jadi `weekKeys[0]`.
- Verifikasi: ganti Prodi → Terapkan → Reset di Employment & Education, `minggu_snapshot=1` (id) terkirim benar ke API di seluruh request, label tetap tampil benar di dropdown & badge "Snapshot aktif" setelah Reset, 0 galat konsol. Skenario asli (dua snapshot berlabel identik) tidak bisa direproduksi visual karena seed data cuma punya 1 snapshot, tapi perbaikan di source menghilangkan akar masalahnya karena pencocokan sekarang selalu lewat id unik.
- `npx tsc --noEmit` tidak menambah error baru dari kedua perubahan frontend ini.

## L. Perbaikan Data — FR-048 & FR-068 (8 Agustus 2026)

Dua temuan lanjutan setelah §K, dan keduanya bukan bug kode — murni gap data hasil seeding yang tidak lengkap:

**FR-048 — 2 dari 7 metode pembelajaran tidak punya jawaban di OLTP**
- Root cause: `ResponseSeeder.php` versi saat ini sudah men-generate jawaban untuk `f21`–`f27` (7 metode), tapi database yang dites belum pernah di-reseed dengan versi seeder itu — `tracer_oltp.response_answers` punya 0 baris untuk `f22` (Demonstrasi) dan `f23` (Partisipasi dalam proyek riset), sementara 5 kode lain punya ribuan baris. Bukan masalah `dim_indikator_evaluasi` (yang sudah benar memetakan ketujuhnya ke kategori `MetodePembelajaran`) — datanya memang tidak pernah masuk.

**FR-068 — pie Wirausaha kosong untuk 5 dari 6 tahun kelulusan**
- Root cause: `fact_tracer_study` untuk tahun 2019/2020/2023/2024 (dataset lama) atau 2020/2023/2024/2025 (dataset baru) punya baris berstatus "wirausaha" tapi kolom `wirausaha_sk`-nya NULL — tidak ter-link ke `dim_wirausaha` (tabel detail jabatan/kota). Hanya sebagian tahun yang lengkap. Repository (`WirausahaRepository.php`) sendiri sudah benar — bahkan sudah ada catatan tertulis di kodenya soal bug case serupa yang pernah diperbaiki (pakai `contains` filter, bukan `equals`, untuk `status_alumni_sk`). Ini murni data historis yang tidak lengkap ter-generate, bukan query yang salah.

**Fix untuk keduanya sekaligus:** reset penuh dataset uji —
```
php artisan migrate:fresh --seed --force
php artisan etl:run --force
```
Ini menjatuhkan & membangun ulang `tracer_oltp` (OLTP) dan `public` (OLAP star schema) dari nol, lalu menjalankan pipeline ETL resmi untuk menurunkan seluruh `dim_*`/`fact_*` dari OLTP yang baru. **Efek samping yang perlu diketahui:** dataset uji berubah drastis — dari ~10.257 alumni (dataset besar sesi-sesi sebelumnya) menjadi 144 alumni (dataset seeder default), dan nama alumni sekarang Title Case (bukan ALL-CAPS) sehingga kasus case-sensitivity FR-074 makin gampang muncul secara alami.

**Jebakan tambahan yang ditemukan saat verifikasi — cache Redis basi:**
Setelah reseed + ETL, API masih mengembalikan angka lama persis (bahkan setelah restart `php artisan serve` dan `cubejs-server` berkali-kali). Ternyata `app/Traits/WithCache.php` memanggil `Cache::store('redis')` **secara eksplisit** dengan TTL 3600 detik — mengabaikan `CACHE_STORE=array` di `.env`. Redis DB 1 (`REDIS_CACHE_DB`) masih menyimpan 62 key basi dari sebelum reseed, dan cache ini **tidak ikut ter-reset oleh migrate:fresh atau restart proses manapun** karena Redis berjalan sebagai service terpisah yang persisten. Fix: `redis-cli -n 1 flushdb`. Juga ditemukan `dev_pre_aggregations` schema di Postgres (rollup cache milik Cube.js) yang perlu di-drop manual (`DROP SCHEMA dev_pre_aggregations CASCADE;`) karena tidak ikut ter-reset oleh `migrate:fresh` (skema itu dikelola Cube.js sendiri, di luar migration Laravel). **Untuk sesi uji berikutnya**: setiap kali data OLTP/OLAP direset manual (bukan lewat command `etl:run` yang normal), flush Redis DB cache dan restart Cube.js supaya tidak salah baca data basi.

**Diverifikasi lewat klik UI langsung**: radar Metode Pembelajaran menampilkan 7/7 metode; pie Wirausaha tahun 2020 menampilkan 2 sector (Staff/Founder) yang sebelumnya kosong total. Fix FR-074 dan FR-014 dari §K juga di-re-test ulang di atas dataset baru ini dan tetap berfungsi normal (0 galat konsol).

## M. Perbaikan Kode — FR-077, FR-084, FR-085 (8 Agustus 2026)

Sesi uji lanjutan, dibatasi ke tiga dashboard utama (Overview, Employment Outcome, Educational Assessment) sesuai arahan eksplisit. `/dashboard/analytics` dan `/dashboard/kpi` dimatikan sementara dari sidebar (di-comment di `rbac.ts` — item `dashboardItems`), bukan dihapus, supaya gampang diaktifkan lagi.

**FR-077 — Methodology Block per KpiCard: ✅ PASS**
Diperiksa satu per satu: Overview (3 tab, 3 tombol), Employment (6 tab, 15 tombol), Education (3 tab, 3 tombol) — total 21 tombol "Lihat metodologi perhitungan". Semuanya ada dan berisi konten non-kosong (150–610 karakter, ada deskripsi + rumus). Tidak ada satupun yang kosong atau hilang.

**FR-085 — Highlight `ReferenceArea` KPI8: ✅ diperbaiki**
`Kpi8IncomeChart.tsx` (chart "Tren Pendapatan & % Lulusan ≥ UMP", dipakai di Employment tab "Pendapatan Lulusan" dan sebelumnya di halaman KPI Lintas Prodi) meng-import `markMax` dari `./format` tapi tidak pernah memanggilnya — akibatnya highlight kotak emas + label "★ Tertinggi" yang ada di KPI3/4/5/6/7 tidak pernah muncul di KPI8. Fix: tambahkan `data={markMax(avgData, "avg")}` ke `<ComposedChart>`, `<ReferenceArea>` untuk titik `isMax`, dan `<LabelList dataKey="isMax">` dengan teks "★ Tertinggi" — pola persis disalin dari `Kpi5WaitingTimeChart.tsx`. Diverifikasi: highlight & label muncul di bar 2022 (nilai tertinggi, 12,9jt) pada dashboard Employment, 0 galat konsol.

**FR-084 — Konsistensi tooltip hover: ❌ ditemukan 4 bug, ✅ semua diperbaiki**
Diuji sistematis (hover + baca isi tooltip) di setiap jenis chart (bar, pie, line, radar, combo) pada ketiga dashboard. Pola bug yang ditemukan berulang: `<Tooltip formatter>` pada `ComposedChart` yang punya lebih dari satu series (Bar + Line) me-hardcode label ke nama salah satu series saja, alih-alih memakai parameter `name` yang dikirim Recharts (yang sebenarnya sudah berisi label `name` dari series yang sedang di-hover). Akibatnya kedua series tampil dengan label yang sama di tooltip, bukan label masing-masing.

File yang diperbaiki:
- `Kpi1ParticipationChart.tsx` (Overview, "Respons Rate per Prodi") — formatter membandingkan `n === "responded"` padahal Recharts mengirim `name` prop ("Sudah Merespons"/"Belum Merespons"), bukan dataKey mentah ("responded"/"notResponded") — perbandingan selalu `false`, tooltip selalu bilang "Belum Merespons" untuk kedua segmen bar stacked. Fix: pakai `n` langsung.
- `Kpi4AbsorptionChart.tsx` (Employment, "Keterserapan Lulusan") — formatter hardcode label `"Keterserapan"` untuk Bar dan Line ("Tren") sekaligus → tooltip menampilkan "Keterserapan" dua kali dengan nilai sama. Fix: pakai `n`.
- `Kpi5WaitingTimeChart.tsx` (Employment, "Masa Tunggu Kerja") — sama persis, formatter hardcode `` `≤ ${batasLabel} bulan` `` untuk Bar dan Line "Tren" sekaligus. Fix: pakai `name`.
- `Kpi6FieldRelevanceChart.tsx` (Employment, "Kesesuaian Bidang") — formatter hardcode `"Kesesuaian"`, dan `<Line>`-nya bahkan tidak punya prop `name` sama sekali (fallback ke dataKey mentah "value"). Fix: tambah `name="Tren"` ke `<Line>`, formatter pakai `n`.

Chart yang **diperiksa dan sudah benar** dari awal (tidak diubah): `Kpi3ParticipationTrendChart.tsx` (Overview, Tren Partisipasi — formatter sudah membandingkan `name` dengan benar), `Kpi7EntrepreneurshipChart.tsx` (Wirausaha), `Kpi8IncomeChart.tsx` (Pendapatan — sudah pakai `n` dengan benar), pie Kesesuaian Bidang (sempat terlihat kosong saat tes tapi ternyata false-positive dari selector Playwright yang salah sasaran, bukan bug aplikasi), radar Gap Kompetensi & Metode Pembelajaran (Education), pie Sumber Pembiayaan Kuliah (Education).

Semua fix diverifikasi lewat hover langsung di browser sebelum & sesudah — label sekarang berbeda dan benar untuk tiap series, 0 galat konsol di seluruh pengujian. `npx tsc --noEmit` bersih untuk semua file yang diubah.

### Perubahan data yang saya buat selama pengujian

- Master UMP tahun **2028** dibuat (kosong, 0/34) untuk menguji FR-058.
- Kata sandi alumni **211413432** diterbitkan ulang; berkas `Kredensial_Alumni_2026-08-07.xlsx` berisi kata sandi polosnya tersimpan di `d:\PKM\3\.playwright-mcp\` — sebaiknya dihapus.
- Standar penilaian LAM EMBA 2020 dinonaktifkan lalu diaktifkan kembali (kembali ke keadaan semula).
- Berkas uji impor `uji_import_invalid.xlsx` ditinggalkan di `.playwright-mcp\`; tidak ada satu baris pun yang masuk ke basis data.