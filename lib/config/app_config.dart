/// Konfigurasi Global Aplikasi MathLock
/// 
/// Gunakan saklar (flag) `true` / `false` di bawah ini untuk mematikan/menghidupkan
/// fitur saat pengembangan, pengujian, atau update aplikasi.
class AppConfig {
  /// Saklar Iklan AdMob
  /// - `false`: Iklan dimatikan sepenuhnya (cocok saat update/pengerjaan fitur).
  /// - `true` : Iklan aktif normal.
  static const bool enableAds = false;

  /// Saklar Background App Lock Service
  /// - `false`: Penguncian aplikasi dimatikan sementara.
  /// - `true` : Penguncian aplikasi berjalan normal.
  static const bool enableAppLock = true;

  /// Saklar Pembatasan Fitur Premium
  /// - `false`: Pembatasan Premium dimatikan (pengguna umum/non-premium dapat melihat Statistik & fitur premium).
  /// - `true` : Mengunci fitur statistik & fitur terbatas khusus untuk akun Premium.
  static const bool enablePremiumRestrictions = false;
}
