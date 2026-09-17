# LockMath — Anti-Brainrot App Lock dengan Friksi Kognitif Intra-Sesi

**LockMath** adalah aplikasi pengunci aplikasi Android berbasis Flutter yang memaksa
pengguna menyelesaikan soal aritmatika sebelum dapat membuka aplikasi yang dikunci —
sebuah *cognitive friction* untuk menekan *problematic smartphone use* / brainrot.

Berbeda dari aplikasi serupa (one sec, Forest, AppBlock) yang hanya memberi friksi
**saat membuka aplikasi**, LockMath mengunci **kembali di tengah sesi pemakaian**
(*intra-session re-lock*). Ini adalah kebaruan yang diteliti dalam Tugas Akhir
"LockMath: Aplikasi Anti-Brainrot Berbasis Friksi Kognitif dengan Mekanisme
Re-Lock Intra-Sesi untuk Menekan Problematic Smartphone Use pada Mahasiswa".

> Repository ini berisi **aplikasi produksi** (bukan prototis penelitian):
> Flutter + native Kotlin foreground service + Supabase auth & sync.

---

## Arsitektur

```
┌────────────── Flutter (Dart) ──────────────┐    ┌──── Native Kotlin ────┐
│ main.dart                                   │    │ AppLockService.kt     │
│  ├─ AuthWrapper (login gate)                │◄───┤  polling UsageStats   │
│  ├─ MainScaffold (home/app list/settings)   │    │  setiap 500ms         │
│  └─ MathLockScreen (soal + number pad)      │    │  re-lock intra-sesi   │
│                                             │    │                       │
│ services/                                   │    │ MathChallengeActivity │
│  ├─ database_service.dart (SQLite lokal)    │    │  FlutterActivity      │
│  ├─ supabase_service.dart (auth + sync)     │◄───┤  MethodChannel        │
│  ├─ app_lock_native_service.dart            │    │  FLAG_SECURE, no-back │
│  └─ ad_service.dart (AdMob/IAP)             │    │                       │
│                                             │    │ MainActivity.kt      │
│ state/app_state.dart (ChangeNotifier)       │    │  prefs sync           │
└─────────────────────────────────────────────┘    └───────────────────────┘
```

Aliran kunci: `AppLockService` mendeteksi app terkunci di foreground → tulis
`pending_lock_*` ke SharedPreferences → buka `MathChallengeActivity` (route `/lock`)
→ Flutter engine terpisah merender `MathLockScreen` → user jawab soal →
`dismissLock` via MethodChannel → kembali ke app.

---

## Fitur yang sudah ada

| Fitur | Status | Catatan |
|---|---|---|
| Kunci app dengan soal aritmatika | ✅ production | 3 soal, timer 10 detik, 3 nyawa per soal |
| 4 level kesulitan | ✅ production | 0=SD, 1=SMP, 2=SMA, 3=PT (aljabar linear) |
| **Re-lock intra-sesi (M2)** | ✅ production | `SESSION_LIMIT_MS` = 15 menit di `AppLockService.kt` |
| **Forced-exit (M4)** | ✅ production | Gagal 3 soal → ditendang ke home launcher |
| Refresh soal berpenalti | ✅ production | Makan 1 nyawa; nyawa terakhir tidak bisa dipakai refresh |
| Tombol darurat / bypass | ❌ dihapus | Satu-satunya jalan keluar = selesaikan soal |
| Deteksi retry setelah force-exit | ✅ production | `is_retry` + `session_id` di log |
| Service foreground anti-kill | ✅ production | Notifikasi ongoing "Cobalt Fortress Aktif" |
| Anti-bypass (back, screenshot, recents) | ✅ production | `FLAG_SECURE` + `onBackPressed` diblok |
| Login email/password + Google | ✅ production | Supabase Auth |
| Sync settings & events ke cloud | ✅ production | Supabase `user_settings`, `unlock_events` |
| Iklan AdMob (app open + rewarded) | ✅ production | `AppConfig.enableAds = false` saat dev |
| IAP premium | ✅ production | `premium_3_months`, `premium_6_months`, `premium_1_year` |
| UI immersive (glassmorphism, glow) | ✅ production | `lib/theme/`, `lib/widgets/ambient_glow.dart` |

### Yang BELUM ada (jangan klaim di presentasi!)

- **Interval re-lock progresif (M3)** — saat ini interval **konstan 15 menit**.
  Mekanisme "durasi antar-lock meningkat bertahap" masih berupa rencana
  penelitian, belum diimplementasikan. Lihat `SESSION_LIMIT_MS`.
- **Eskalasi tingkat kesulitan otomatis** — tingkat kesulitan manual via settings.
- **Integrasi kuesioner BSMAS/SAS/doomscrolling scale** — masih eksternal.
- **Dashboard analitik retry curve** — data tersimpan, UI-nya belum.
- **Biometric unlock** — ada setting-nya, implementasi `local_auth` belum.
- **Boot receiver / WorkManager** — service tidak auto-restart setelah reboot.

---

## Struktur project

```
lib/
├── main.dart                    # entry; detect route /lock untuk mode lock-only
├── config/
│   ├── app_config.dart          # feature flags (enableAds, enableAppLock, premium)
│   └── supabase_config.dart     # URL + anon key dari .env
├── screens/                     # 11 layar (login, home, app list, settings, stats…)
│   ├── math_lock_screen.dart    # UI kunci + generateQuestion() + timer
│   └── lock_route_screen.dart   # bridge native → MathLockScreen
├── services/
│   ├── database_service.dart    # SQLite cobalt_fortress.db (unlock_events)
│   ├── supabase_service.dart    # auth + upsert/sync
│   ├── app_lock_native_service.dart
│   └── ad_service.dart
├── state/app_state.dart         # ChangeNotifier pusat
├── theme/app_theme.dart
└── widgets/                     # 10 widget (ad banner, premium sheet, glow…)

android/app/src/main/kotlin/com/danibaret014/mathlock/
├── AppLockService.kt            # foreground service + polling + re-lock
├── MathChallengeActivity.kt     # FlutterActivity untuk /lock
└── MainActivity.kt              # MethodChannel + prefs sync
```

---

## Setup

```bash
flutter pub get
cp .env.example .env   # isi SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_WEB_CLIENT_ID
flutter run
```

### Prasyarat

- Flutter SDK ^3.11.4
- Android SDK (compileSdk dari `flutter.compileSdkVersion`, minSdk default)
- Supabase project dengan tabel `user_settings` dan `unlock_events`
- Google Cloud OAuth client Android dengan SHA-1 keystore yang dipakai build

---

## Mode kunci: cara kerjanya

1. User memilih app yang akan dikunci (lihat daftar via `installed_apps`).
2. `AppLockService` polling `UsageStatsManager` tiap 500ms.
3. Saat app terkunci masuk foreground:
   - Tulis `pending_lock_name`, `pending_lock_difficulty`,
     `pending_lock_package`, `pending_session_id` ke prefs.
   - Buka `MathChallengeActivity` dengan `FLAG_ACTIVITY_NEW_TASK`.
4. User harus selesaikan 3 soal dalam waktu 10 detik per soal, 3 nyawa per soal.
5. Gagal total → forced-exit ke home launcher, event gagal dicatat (`forced_exit=1`).
6. Berhasil → `dismissLock` → prefs `is_unlocked=true` + broadcast
   `ACTION_SESSION_ARM` dengan deadline = now + 15 menit.
7. Setelah 15 menit app yang sama masih di foreground → **re-lock**:
   deadline terlampaui → ulang langkah 3 dengan `lock_reason=relock`.

---

## Logika soal (`generateQuestion`)

| Level | Rumus | Contoh |
|---|---|---|
| 0 (SD) | `a op b`, op ∈ {+, −, ×}, a,b ∈ [1,20] | `7 × 8` |
| 1 (SMP) | `a × b ± c` | `12 × 5 + 7` |
| 2 (SMA) | `a²`, `√n`, `a × b + c` | `√144`, `9 × 7 + 3` |
| 3 (PT) | `a(x + b) + c = d(x + e)` | `Cari x: 3(x + 2) + 4 = 5(x − 1)` |

Level PT pakai loop yang menjamin `x ∉ {0, 1, −1}` dan koefisien non-trivial.

---

## Data model

### SQLite `unlock_events` (lokal, v3)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | autoincrement |
| packageName | TEXT | mis. `com.instagram.android` |
| appName | TEXT | label yang ditampilkan |
| timestamp | INTEGER | unix ms |
| success | INTEGER | 1 = berhasil, 0 = gagal |
| attempts | INTEGER | jumlah submit |
| durationMs | INTEGER | soal muncul → selesai |
| formula | TEXT | teks soal |
| answer | INTEGER | jawaban benar |
| isSynced | INTEGER | 1 = sudah ke Supabase |
| **sessionId** | TEXT | `<package>-<startMs>`, unik per sesi |
| **sessionStartMs** | INTEGER | app masuk foreground |
| **sessionEndMs** | INTEGER | sesi berakhir |
| **lockReason** | TEXT | `initial` \| `relock` \| `screen_off` \| `forced_exit` |
| **forcedExit** | INTEGER | 1 = ditendang ke home |
| **isRetry** | INTEGER | 1 = user buka app lagi setelah forced-exit |

### Supabase

- `user_settings`: `user_id`, `master_lock_enabled`, `difficulty_level`,
  `biometric_enabled`, `is_dark_theme`, `is_premium`, `premium_expiry`,
  `locked_packages[]`, `updated_at`
- `unlock_events`: kolom sama dengan SQLite (snake_case), conflict target
  `user_id,timestamp,package_name`

**RLS**: tabel di-shared project ini **mengaktifkan RLS**. Insert anonymous
ditolak (42501). Hanya user terautentikasi yang bisa baca/tulis row miliknya.
Detail dan temuan celah → lihat `docs/RLS_AUDIT.md`.

---

## Config flag

`lib/config/app_config.dart`:

| Flag | Default | Efek |
|---|---|---|
| `enableAds` | `false` | matikan AdMob saat dev |
| `enableAppLock` | `true` | nyalakan service penguncian |
| `enablePremiumRestrictions` | `false` | matikan gating fitur premium |

---

## Penelitian

Dokumen TA (kerangka, daftar pustaka DOI-verified, naskah presentasi) ada di
`.hermes/research/`. Framework penelitian: quasi-experimental pretest–posttest
control group, 4 minggu, LockMath vs Screen Time, metrik primer = durasi sesi,
metrik unik = **retry-after-force-exit curve** (habit extinction proxy).

---

## Lisensi

Private — bagian dari Tugas Akhir. `publish_to: 'none'`.
