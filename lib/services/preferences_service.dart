import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper untuk menyimpan & membaca pengaturan aplikasi ke SharedPreferences.
///
/// Semua nilai settings (master lock, difficulty, biometric) disimpan secara
/// persisten sehingga tidak hilang saat aplikasi di-restart.
class PreferencesService {
  static const _keyMasterLock    = 'master_lock_enabled';
  static const _keyDifficulty    = 'difficulty_level';
  static const _keyBiometric     = 'biometric_enabled';

  // ── Singleton ─────────────────────────────────────────────────────────────

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Master Lock ────────────────────────────────────────────────────────────

  Future<bool> getMasterLock() async =>
      (await _p).getBool(_keyMasterLock) ?? true;

  Future<void> setMasterLock(bool value) async =>
      (await _p).setBool(_keyMasterLock, value);

  // ── Difficulty ─────────────────────────────────────────────────────────────

  Future<int> getDifficulty() async =>
      (await _p).getInt(_keyDifficulty) ?? 1;

  Future<void> setDifficulty(int value) async =>
      (await _p).setInt(_keyDifficulty, value);

  // ── Biometric ─────────────────────────────────────────────────────────────

  Future<bool> getBiometric() async =>
      (await _p).getBool(_keyBiometric) ?? true;

  Future<void> setBiometric(bool value) async =>
      (await _p).setBool(_keyBiometric, value);

  // ── Locked apps (per-app state) ────────────────────────────────────────────
  // Menyimpan Set<String> packageName yang dikunci secara individual,
  // terpisah dari native SharedPrefs (yang dipakai AppLockService).
  // Ini memungkinkan lock per-app tetap tersimpan meski master lock di-off/on.

  static const _keyLockedPackages = 'individually_locked_packages';

  Future<Set<String>> getLockedPackages() async {
    final list = (await _p).getStringList(_keyLockedPackages) ?? [];
    return list.toSet();
  }

  Future<void> setLockedPackages(Set<String> packages) async =>
      (await _p).setStringList(_keyLockedPackages, packages.toList());
}
