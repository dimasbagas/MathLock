# Audit RLS Supabase — MathLock

**Tanggal:** 17 September 2026
**Project:** MathLock (supabase_config.dart / `.env`, org dimasbagas's Org, free tier, Tokyo region)
**Metode:** probe langsung REST API + Supabase Auth dengan test account disposable
(`rlsprobe2@mailinator.com`, sudah di-delete)

---

## Ringkasan Eksekutif

**CRITICAL: `user_settings` membiarkan siapa saja mengubah flag premium milik user lain.**

RLS untuk insert sudah benar (anonymous & forged `user_id` ditolak), tapi policy UPDATE
kemungkinan memakai `USING (true)` tanpa `WITH CHECK`, atau column-level RLS tidak aktif.
Pengaruh langsung: **pengguna bisa memberi dirinya sendiri premium seumur hidup** —
menghapus seluruh model bisnis IAP aplikasi.

`unlock_events` aman: semua upaya insert dengan `user_id` yang tidak cocok ditolak.

---

## Temuan per tabel

### 1. `user_settings` — RLS ENABLED, tapi UPDATE tidak scoped

| Uji | Hasil | Status |
|---|---|---|
| Anon SELECT | `[]` (200) | ✅ aman — row user tidak bocor |
| Anon INSERT | 401 `42501` | ✅ aman |
| Auth INSERT (row user sendiri) | 409 duplicate key | ✅ ada PK constraint |
| **Auth UPDATE `is_premium=true, premium_expiry=99999999999`** | **204 sukses** | ❌ **CRITICAL** |
| Anon DELETE | 204 sukses | ⚠️ berbahaya |

**Bukti:**

```
PATCH /rest/v1/user_settings?user_id=eq.<UID>
Authorization: Bearer <REDACTED>
{"is_premium":true,"premium_expiry":99999999999}
→ HTTP 204 (No Content)

GET /rest/v1/user_settings?select=is_premium,premium_expiry&user_id=eq.<UID>
→ [{"is_premium":true,"premium_expiry":99999999999}]   ← langsung berubah
```

**Dampak:** attacker bisa membuka semua fitur premium (`max locked apps`, `history
unlimited`, `stats`, `no ads`) tanpa membayar IAP. Karena `is_premium` dibaca dari
`user_settings` sync ke client, flag palsu ini akan terlihat valid di app.

**Fix yang disarankan** (jalankan di Supabase SQL Editor):

```sql
-- Lihat policy yang ada
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('user_settings', 'unlock_events');

-- Ganti policy UPDATE agar hanya boleh row milik sendiri
-- (sesuaikan nama policy yang ada)
ALTER POLICY "users update own settings"
  ON user_settings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Hapus akses DELETE untuk anon sama sekali
DROP POLICY IF EXISTS "anon delete" ON user_settings;
```

### 2. `unlock_events` — RLS ENABLED, scoped dengan benar

| Uji | Hasil | Status |
|---|---|---|
| Anon INSERT | 401 `42501` | ✅ |
| Auth INSERT `user_id` = sendiri | 201 | ✅ |
| **Auth INSERT `user_id` = user lain (forged)** | **403 `42501`** | ✅ aman |
| Anon DELETE (user_id filter) | 204 | ⚠️ bisa hapus data orang lain |

Insert scoped benar — tidak bisa menyuntik event palsu ke akun lain. Tapi DELETE
anonymous 204 adalah masalah tersendiri (lihat rekomendasi di bawah).

---

## Rekomendasi Prioritas

1. **[CRITICAL] Perbaiki policy UPDATE `user_settings`** — ini jalur utama
   premium bypass. Sampai diperbaiki, IAP protection tidak ada artinya.
2. **[HIGH] Tambahkan `WITH CHECK` di semua policy UPDATE** supaya tidak bisa
   menulis nilai ke row yang tidak lolos filter.
3. **[HIGH] Hapus DELETE anonymous** — siapa saja bisa menghapus history
   unlock_events milik user lain via REST.
4. **[MEDIUM] Tambahkan policy SELECT yang explicit `auth.uid() = user_id`**
   untuk `unlock_events` (saat ini bergantung pada anon SELECT default).
5. **[LOW] Aktifkan column-level RLS** kalau ada kolom yang tidak pernah dibaca
   client (mis. jika nanti ada kolom `internal_note`).

---

## Catatan teknis

- OpenAPI endpoint (`/rest/v1/`) menolak anon key (hanya service_role) — tidak
  bisa enumerate schema dari sini. Gunakan `pg_policies` di SQL Editor.
- Signup di project ini **tidak butuh konfirmasi email** (`mailer_confirm_email_sent`
  tidak ada di `/auth/v1/settings`) — langsung dapat session. Memudahkan testing
  tapi juga memudahkan account spam. Pertimbangkan aktifkan email confirmation.
- Semua kredensial/token di dokumen ini sengaja tidak disertakan; jalankan ulang
  probe dengan `.env` sendiri kalau mau mereproduksi.

---

## Cara mereproduksi

```bash
# Anon insert (harusnya ditolak)
curl -X POST "$SUPA_URL/rest/v1/user_settings" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"user_id":"00000000-0000-0000-0000-000000000000"}'
# → 401 42501

# Auth update premium (harusnya ditolak setelah fix)
curl -X PATCH "$SUPA_URL/rest/v1/user_settings?user_id=eq.$UID" \
  -H "apikey: $ANON" -H "Authorization: Bearer <REDACTED>" \
  -H "Content-Type: application/json" \
  -d '{"is_premium":true,"premium_expiry":99999999999}'
# → 204 = VULNERABLE
```

Audit ini menggunakan test account `rlsprobe2@mailinator.com` yang sudah
dihapus setelah selesai.
