# NASKAH PRESENTASI KE DOSEN — LockMath (10 menit)
*Prinsip: dosen sudah bilang "idenya bagus" — tugasmu cuma menjawab 2 kecemasannya: (1) emang belum ada yang bikin? (2) mana dampak/implikasinya?*

## URUTAN SLIDE (7 slide cukup)

**Slide 1 — Pembuka personal (60 detik)**
> "Izin menyampaikan, Pak/Bu. Latar belakang TA saya masalah pribadi: saya kecanduan scrolling
> short video sampai lupa waktu, dan ternyata ada istilah untuk dampaknya — brainrot, yang
> sudah saya rasakan sendiri. Saat mencari cara berhenti, saya pakai logika sederhana:
> saya malas kalau disuruh mikir. Maka saya rancang aplikasi yang membuat orang harus
> MIKIR dulu sebelum bisa buka aplikasi pemicunya. Lahirlah LockMath."

*Kamu-fluencer story → langsung relevan sama topik. Dosen suka masalah nyata.*

**Slide 2 — Masalah & gap solusi yang ada (90 detik) ⭐ SLIDE KUNCI**
Tampilkan tabel:

| Aplikasi | Cara friksi | Kelemahan |
|---|---|---|
| one sec (PNAS, 2023) | napas 8 detik **saat buka app** | sekali lolos, bebas scroll selamanya |
| Forest | timer sukarela | bisa dicabut kapan saja |
| AppBlock/Freedom | blokir terjadwal | tanpa tantangan kognitif |
| Screen Time / Digital Wellbeing | limit harian + notifikasi | peringatan lembek, mudah di-ignore |

> "Jadi jawabannya Pak/Bu: aplikasi serupa ADA, dan sudah saya telusuri di jurnal
> (Crossref, OpenAlex, Scopus-indexed). Tapi semuanya memberi friksi hanya SAAT MEMBUKA.
> Belum ada yang mengunci ulang DI TENGAH sesi scrolling. Itu gap penelitian saya."

**Slide 3 — Kebaruan / novelty (90 detik)**
> "Fitur kunci saya: Progressive Intra-Session Cognitive Friction.
> 1. Buka app → wajib jawab soal aritmatika.
> 2. Sudah masuk? Setelah 15 menit scroll, app TERKUNCI LAGI di tengah sesi.
> 3. Mau lanjut? Jawab soal lagi. GAGAL? Dikeluar-paksa dari aplikasi.
> 4. Interval kunci bisa naik bertahap sesuai progres pengguna.
> Kombinasi 4 hal ini tidak ditemukan pada aplikasi manapun, sejauh penelusuran
> literatur 2018–2026 saya."

**Slide 4 — Kerangka penelitian (90 detik)**
→ tampilkan PNG `kerangka-penelitian-lockmath.png`.
> "Kerangka penelitian saya: masalah → tiga teori fondasi → intervensi → pengukuran → dampak."

Jelaskan teori dengan bahasa simpel (kalau dosen tanya "teori apa?"):
- Dual-process (Johannes et al., 2021): scroll itu refleks tanpa pikir; soal matematika memaksa otak pindah ke mode mikir.
- JITAI (Nahum-Shani et al., 2017): intervensi kesehatan paling efektif kalau diberikan TEPAT WAKTUnya — bukan pagi-pagiReminder, tapi pas lagi kecanduan-nya terjadi.
- Response friction (Grüning et al., 2023, PNAS): menambah "biaya" kecil ke kebiasaan otomatis terbukti menurunkannya.

**Slide 5 — Metode: ini bagian "berdampak" (90 detik) ⭐ JAWABAN SOAL DAMPAK**
> "Dampak yang Bapak/Ibu maksud saya operational-kan jadi penelitian quasi-eksperimen
> 4 minggu, dua kelompok: LockMath vs Screen Time bawaan, 30–40 mahasiswa.
> Pengukuran OBJEKTIF dari log device: durasi sesi harian, plus kuesioner tervalidasi —
> BSMAS/SAS untuk kecanduan, doomscrolling scale, MARS untuk kualitas aplikasi."

**Slide 6 — Metrik unik: retry-after-force-exit (60 detik) — "senjata rahasia"**
> "Yang membuat penelitian ini bisa naik ke level internasional: saya ukur kurva retry.
> Berapa kali pengguna gagal menjawab, keluar paksa, lalu mencoba lagi? Kalau angka retry
> turun selama 4 minggu, itu bukti empiris habit extinction — penghapusan kebiasaan.
> Sejauh penelusuran saya, belum ada paper digital wellbeing yang punya metrik ini."

**Slide 7 — Status & rencana (30 detik)**
> "Aplikasi sudah jadi dan berjalan: Flutter, login Google, mekanisme kunci sudah berfungsi.
> Rencana: uji coba kecil → eksperimen 4 minggu → skripsi + target publikasi
> (JMIR mHealth / ACM CHI LBW)."
*Tunjukkan demo live/handphone kalau bisa — 15 detik demo soal terkunci lebih kuat dari 5 menit bicara.*

---

## CHEAT SHEET: PERTANYAAN DOSEN YANG PAKAL MUNCUL

**T: "Kata kamu mirip one sec — apa bedanya, seriusan?"**
J: "One sec hanya saat membuka, dan friksinya napas — sekali terbiasa, gratis selamanya.
LockMath mengunci ULANG di tengah sesi, dengan effort kognitif (berhitung) dan konsekuensi
berjenjang (gagal = keluar). Justru one sec & PNAS-nya adalah bukti friksi bekerja —
saya kembangkan ke ranah intra-sesi yang belum tersentuh."

**T: "Kenapa matematika? Kenapa bukan kuis atau captcha?"**
J: "Captcha terlalu gampang dilewati otak (masih System 1). Matematika dasar memaksa
frontal cortex kerja — ada literatur inhibitory control-nya (Johannes 2021). Plus
sasaran pengguna saya mahasiswa — soal aritmatika skalable dari SD-SMA."

**T: "User pasti uninstall dong, kesel."**
J: "Itu justru variabel penelitian saya: toleransi & retensi (MARS + log uninstall).
Ada studi terbaru 2026 soal gradual delay — eskalasi pelan-pelan terbukti dapat
ditoleransi pengguna. LockMath pakai skema itu."

**T: "Sampel 30 orang cukup?"**
J: "Untuk quasi-experiment within-subject (pre-post tiap orang) dengan effect size
friksi satu sec ~0.2-0.3, power analysis memungkinan n≈34 per grup pada power 0.8.
Saya akan hitung formal pakai G*Power di BAB 3."

**T: "Kontribusi ilmiahnya apa? Kan cuma bikin aplikasi."**
J: "Tiga: (1) mengusulkan mekanisme PISCF yang belum ada di literatur, (2) bukti
eksperimental intra-session cognitive friction terhadap durasi sesi, (3) metrik retry-
after-force-exit sebagai proxy habit extinction. Bukan sekadar engineering."

**T: "Brainrot itu istilah ilmiah ya?"**
J: "Belum — itu istilah budaya populer. Dalam penelitian saya operasionalkan sebagai
*Problematic Smartphone Use* / *doomscrolling* yang punya skala tervalidasi
(Yang et al., 2024, BMC Psychiatry)." ← *jawaban ini bikin dosen terkesan kamu ngerti batas istilah*

**T: "Etika penelitian? Kan manipulatif."**
J: "Informed consent penuh, partisipan boleh uninstall kapanpun, data anonim, dan
saya akanurus ethical clearance/-surat persetujuan prodi sebelum eksperimen."

---

## PAKET SERAH (cetak / kirim PDF)
1. `kerangka-penelitian-lockmath.png` (bagan)
2. `framework-ta-lockmath.md` (narasi + daftar pustaka APA 13 entri ber-DOI)
3. `brief-brainrot-gap-2026-09-15.md` (tabel aplikasi serupa + gap — bukti kamu sudah kerja)
4. (opsional) 1 slide demo 15 detik dari HP/emulator

## TIPS PENYAMPAIAN
- Jangan baca slide. Story kamu kuat karena NYATA: mulai dari "saya kecanduan".
- Kalau dosen potong di tengah: jawab, catat, lanjut — catatannya jadi bahan bimbingan berikutnya.
- Kalimat penutup: "Mohon arahan Bapak/Ibu untuk melangkah ke BAB 1 dan pengurusan etik."
- Semua angka di presentasi HARUS bisa kamu pertanggungjawabkan dari jurnalnya —
  itu sebabnya daftar pustaka DOI-verified ada di tanganmu.
