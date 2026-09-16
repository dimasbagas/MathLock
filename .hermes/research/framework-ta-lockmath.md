# KERANGKA (FRAMEWORK) PENELITIAN — TUGAS AKHIR
**Topik: LockMath — Aplikasi Penguncian Berbasis Tantangan Kognitif (Progressive Intra-Session Cognitive Friction) untuk Menekan Perilaku Brainrot / Problematic Smartphone Use**

*(Semua referensi di daftar pustaka terverifikasi live via Crossref API, September 2026, kecuali dicatat.)*

---

## 0. BEDANYA JUDUL vs FRAMEWORK (catatan buat mahasiswa)
- **Judul** = satu baris nama penelitian.
- **Framework/kerangka penelitian** = bagan alur logika: MASALAH → TEORI → INPUT → PROSES/PENELITIAN → OUTPUT → OUTCOME, plus penjelasan tiap panah. Biasanya digambar (diagrams.net/draw.io) dan diletakkan di BAB 2 akhir atau BAB 3 awal.

---

## 1. JUDUL (FINAL — menunggu persetujuan dosen)
> **"LockMath: Aplikasi Anti-Brainrot Berbasis Friksi Kognitif dengan Mekanisme Re-Lock Intra-Sesi untuk Menekan Problematic Smartphone Use pada Mahasiswa"**
**Cadangan jika dosen minta gaya lain:**
- "Pengaruh Aplikasi Penguncian Berbasis Tantangan Aritmatika terhadap Durasi Sesi Scrolling dan Skor Kecanduan Smartphone (Studi Quasi-Eksperimen pada Mahasiswa)"
- Versi Inggris (publikasi internasional): "LockMath: Progressive Intra-Session Cognitive Friction as a Just-in-Time Intervention Against Problematic Smartphone Use — A Quasi-Experimental Study"

## 2. RUMUSAN MASALAH
- RM1: Bagaimana merancang dan membangun aplikasi LockMath dengan mekanisme *progressive intra-session cognitive friction*?
- RM2: Bagaimana pengaruh LockMath terhadap **durasi sesi** penggunaan aplikasi pemicu brainrot (short-video/social media)?
- RM3: Bagaimana pengaruh LockMath terhadap **skor kecanduan smartphone** (BSMAS/SAS) dan **perilaku doomscrolling**?
- RM4: Bagaimana *retention behavior* pengguna pasca forced-exit (indikator habit extinction)?

## 3. TEORI FONDASI (payung teoritis — 3 lapis)
| Lapis | Teori | Sumber kunci | Peran di LockMath |
|---|---|---|---|
| Psikologis | **Dual-process / inhibitory control**: perilaku scroll = proses otomatis (System 1); interupsi yang menuntut effort mengaktifkan System 2 | Johannes et al. (2021), *J Experimental Psychology: General* | Soal aritmatika = pengungkit System 2 |
| Desain intervensi | **Just-in-Time Adaptive Interventions (JITAIs)**: interupsi pada *moment* yang tepat dengan *dosis* yang tepat | Nahum-Shani et al. (2017), *Annals of Behavioral Medicine* | Re-lock 30 menit = JITAI dengan trigger berbasis durasi |
| Ekonomi perilaku | **Response effort / friction**: menambah biaya kecil pada perilaku otomatis menurunkan frekuensinya secara signifikan | Grüning et al. (2023) *PNAS* (one sec); Radtke et al. (2021) *MM&C* | Eskalasi durasi + forced-exit = friksi yang naik bertahap |

## 4. KERANGKA KONSEPTUAL (bagan — salin ke draw.io)

```
┌─────────────────── INPUT ────────────────────┐
│ Problematic Smartphone Use / "brainrot":     │
│  • durasi sesi scrolling tinggi              │
│  • skor BSMAS/SAS tinggi                     │
│  • doomscrolling (Hou et al., 2024)          │
│  teori: proses otomatis System-1 (Johannes    │
│  et al., 2021)                               │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────── INTERVENSI: LockMath (quasi-experimen, 4 minggu) ────────┐
│ M1. Cognitive Gate     : kunci app dibuka dgn soal aritmatika   │
│ M2. Intra-session      : timer N menit → RE-LOCK di tengah sesi │
│     re-lock  ← NOVELTY (tidak ada di one sec/Forest/AppBlock)   │
│ M3. Progressive dose   : durasi antar-lock meningkat bertahap   │
│     (prinsip JITAI, Nahum-Shani et al., 2017)                   │
│ M4. Consequence        : gagal soal → FORCE-EXIT                │
└──────────────────────┬───────────────────────────────────────────┘
                       ▼
┌──────────────── PENGUKURAN (OUT) ────────────────┐
│ Primer  : durasi sesi harian & mingguan          │
│           (log objektif device)                  │
│ Sekunder: Δ skor BSMAS/SAS (pre-post)            │
│           Δ doomscrolling scale                  │
│ Unik    : retry-after-forced-exit curve          │
│           = indikator habit extinction           │
│ Kualitas: MARS (Stoyanov et al., 2015) + SUS     │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────── OUTCOME ────────────────┐
│ Penurunan problematic smartphone use &  │
│ waktu brainrot; model friksi kognitif   │
│ intra-sesi yang teruji → publikasi      │
│ internasional                           │
└─────────────────────────────────────────┘
```

## 5. HIPOTESIS
- H1: Kelompok LockMath mengalami penurunan durasi sesi aplikasi target lebih besar daripada kelompok kontrol (Screen Time bawaan).
- H2: Skor BSMAS/SAS menurun signifikan pada kelompok LockMath (pre vs post, paired t-test/Wilcoxon).
- H3: Jumlah retry-after-forced-exit menurun sepanjang 4 minggu (trend → habit extinction).
- H4: Perceived friction positively correlates dengan engagement (tidak membuat pengguna uninstall) → uji toleransi, bandingkan temuan "gradual delays" (2026, PsyArXiv).

## 6. METODE SINGKAT (BAB 3)
- Desain: **quasi-experimental pretest–posttest control group**, 2 kelompok × 15–20 mahasiswa (total 30–40), 4 minggu.
- Instrumen: BSMAS (dewanti/versi Indonesia tersedia) atau SAS (Vally & Alowais, 2020), doomscrolling scale (Yang et al., 2024), MARS (Stoyanov et al., 2015), log screen-time dari aplikasi/UsageStats API.
- Analisis: normalitas → paired t-test / Wilcoxon (dalam grup), independent t / Mann-Whitney (antar grup); effect size Cohen's d (reviewer internasional wajib minta ini).
- Etika: informed consent, hak keluar kapanpun, data anonym (kaji dulu di prodi).

---

## DAFTAR PUSTAKA (APA 7 — 13 entri, DOI diverifikasi Crossref 15 Sep 2026)

Cheng, H. (2025). Unplug to thrive: A PERMA-based intervention program for reducing smartphone addiction. *Psychology & Psychological Research International Journal, 10*(3), 1–8. https://doi.org/10.23880/pprij-16000459

Chateau, L. (2026). Italian brainrot as a GenAI meme: The evolution of slop and brainrot aesthetics in the digital cultural economy. *Convergence: The International Journal of Research into New Media Technologies*. Advance online publication. https://doi.org/10.1177/13548565261464434

Grüning, D., Riedel, F., & Lorenz-Spreen, P. (2023). Directing smartphone use through the self-nudge app one sec. *Proceedings of the National Academy of Sciences, 120*(8). https://doi.org/10.1073/pnas.2213114120

Hidayah, N., Reranta, R., & Nasrulloh, M. (2026). Neologisme absurd dan fungsi fatis dalam bahasa brainrot di budaya digital TikTok Indonesia. *JBSI: Jurnal Bahasa dan Sastra Indonesia, 6*(1), 227–236. https://doi.org/10.47709/jbsi.v6i01.8553

Johannes, N., Buijsen, I., & Veling, P. (2021). Beyond inhibitory control training: Inactions and actions influence smartphone app use through changes in explicit liking. *Journal of Experimental Psychology: General*. https://doi.org/10.1037/xge0000888

Maior, H. A., Wilson, M. L., Locke, C., Swann, D., Zhang, J., & Sharples, S. (2018). Smartphone use and inhibitory control: Exploring interruption techniques [Paper presented at CHI 2018]. *Proceedings of the 2018 CHI Conference on Human Factors in Computing Systems*. https://doi.org/10.1145/3173574 ⚠️ *DOI ini proceedings-nya; DOI per-paper cek manual di dl.acm.org (API rate-limited saat verifikasi).*

Nahum-Shani, I., Smith, S. J., Spring, B., Collins, L. M., Witkiewitz, K., Tewari, A., & Murphy, S. A. (2017). Just-in-time adaptive interventions (JITAIs) in mobile health: Key components and design principles for ongoing health behavior support. *Annals of Behavioral Medicine, 52*(6), 446–462. https://doi.org/10.1007/s12160-016-9830-8

Qin, Y., Omar, B., & Musetti, A. (2022). The addiction behavior of short-form video app TikTok: The information quality and system quality perspective. *Frontiers in Psychology, 13*, 932805. https://doi.org/10.3389/fpsyg.2022.932805

Radtke, T., Apel, T., Schenkel, K., Keller, J., & von Lindern, E. C. (2021). Digital detox: An effective solution in the smartphone era? A systematic literature review. *Mobile Media & Communication, 10*(2), 190–215. https://doi.org/10.1177/20501579211028647

Stoyanov, S. R., Hides, L., Kavanagh, D. J., Zelenko, O., Tjondronegoro, D., & Mani, M. (2015). Mobile App Rating Scale: A new tool for assessing the quality of health mobile apps. *JMIR mHealth and uHealth, 3*(1), e27. https://doi.org/10.2196/mhealth.3422

Vally, Z., & Alowais, A. (2020). Assessing risk for smartphone addiction: Validation of an Arabic version of the Smartphone Application-Based Addiction Scale (Sabas). *International Journal of Mental Health and Addiction, 20*(2), 691–703. https://doi.org/10.1007/s11469-020-00395-w

Yang, L., Tan, X., Lang, R., Wang, T., & Li, K. (2024). Reliability and validity of the Chinese version of the doomscrolling scale... *BMC Psychiatry, 24*. https://doi.org/10.1186/s12888-024-06006-5

Zimmermann, L. (2020). An app to control app usage: Does screen time tracking affect user behavior? *Academy of Management Proceedings, 2020*(1), 14848. https://doi.org/10.5465/ambpp.2020.14848abstract

(+1 pra-cetak untuk ditelusuri kalau dosen tanya "terbaru": *Gradual delays do not affect the tolerability of a smartphone friction intervention* (2026), PsyArXiv. https://doi.org/10.31234/osf.io/9eq3x — cek status publikasi resminya sebelum dikutip.)

---
*Catatan integritas (ARS): sitasi di atas dibuat dari metadata resmi penerbit, bukan memori model. Tetap wajib: (1) unduh full-text tiap paper (portal kampus / Sci-Hub utk pratinjau), (2) baca abstrak & metode sebelum mengutip, (3) cek versi final paper CHI yang benar di ACM DL.*
