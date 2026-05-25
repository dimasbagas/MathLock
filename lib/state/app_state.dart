import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/app_lock_native_service.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';

class AppItem {
  final String    name;
  final String    packageName;
  final Uint8List? iconBytes;
  bool            isLocked;

  AppItem({
    required this.name,
    required this.packageName,
    this.iconBytes,
    this.isLocked = false,
  });
}

class AppState extends ChangeNotifier {
  bool   _masterLockEnabled = true;
  int    _difficultyLevel   = 1; // 0=SD, 1=SMP, 2=SMA
  bool   _biometricEnabled  = true;

  final AppLockNativeService  nativeService  = AppLockNativeService();
  final PreferencesService    _prefs         = PreferencesService();
  final DatabaseService       database       = DatabaseService();

  List<AppItem> apps         = [];
  bool          isLoadingApps = true;
  bool          _initialized  = false;

  AppState() {
    _init();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    // Load persisted settings terlebih dahulu
    _masterLockEnabled = await _prefs.getMasterLock();
    _difficultyLevel   = await _prefs.getDifficulty();
    _biometricEnabled  = await _prefs.getBiometric();
    _initialized       = true;
    notifyListeners();

    await _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    try {
      final installedApps = await InstalledApps.getInstalledApps(
          excludeSystemApps: false, withIcon: true);

      // Gabungkan state lock dari dua sumber:
      // 1. Native SharedPrefs (yang dipakai AppLockService)
      // 2. Flutter SharedPrefs (per-app individual state)
      final lockedPackageNames = await nativeService.getLockedApps();
      final savedLocked        = await _prefs.getLockedPackages();
      // Union keduanya — konsisten
      final allLocked = {...lockedPackageNames, ...savedLocked};

      apps = installedApps.map((info) {
        return AppItem(
          name:        info.name,
          packageName: info.packageName,
          iconBytes:   info.icon,
          isLocked:    allLocked.contains(info.packageName),
        );
      }).toList();

      apps.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Failed to load apps: $e');
    } finally {
      isLoadingApps = false;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get masterLockEnabled => _masterLockEnabled;
  int  get difficultyLevel   => _difficultyLevel;
  bool get biometricEnabled  => _biometricEnabled;
  bool get initialized       => _initialized;

  int get lockedCount =>
      _masterLockEnabled ? apps.where((a) => a.isLocked).length : 0;
  int get unlockedCount =>
      _masterLockEnabled ? apps.where((a) => !a.isLocked).length : apps.length;

  // Difficulty helpers
  static const List<String> difficultyLabels    = ['SD',              'SMP',            'SMA'];
  static const List<String> difficultyNames     = ['DASAR',           'AKTIF',          'LANJUT'];
  static const List<String> complexityLabels    = ['BAS',             'ADV',            'EXP'];
  static const List<String> complexitySubtitles = ['ELEMENTARY LEVEL','CALCULUS-READY', 'EXPERT MODE'];
  static const List<double> complexityProgress  = [0.33,              0.66,             1.0];

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Toggle master lock ON/OFF.
  /// Perbaikan: tidak lagi mengubah status lock individual tiap app.
  /// Lock individual tetap tersimpan, hanya enforcement-nya yang dihidupkan/matikan.
  void setMasterLock(bool value) {
    _masterLockEnabled = value;
    _prefs.setMasterLock(value);
    if (value) {
      nativeService.startService();
      _pushLockedAppsToNative();
    } else {
      nativeService.stopService();
    }
    notifyListeners();
  }

  void toggleApp(AppItem app) {
    app.isLocked = !app.isLocked;
    // Simpan state per-app ke Flutter SharedPrefs
    final lockedPackages = apps
        .where((a) => a.isLocked)
        .map((a) => a.packageName)
        .toSet();
    _prefs.setLockedPackages(lockedPackages);
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setDifficulty(int level) {
    assert(level >= 0 && level <= 2);
    _difficultyLevel = level;
    _prefs.setDifficulty(level);
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setBiometric(bool value) {
    _biometricEnabled = value;
    _prefs.setBiometric(value);
    notifyListeners();
  }

  // ── Native sync ────────────────────────────────────────────────────────────

  void _pushLockedAppsToNative() {
    final lockedApps = apps
        .where((a) => a.isLocked)
        .map((a) => {'package': a.packageName, 'name': a.name})
        .toList();
    nativeService.updateLockedApps(lockedApps, _difficultyLevel);
  }

  /// Dipanggil dari [MainScaffold] saat startup untuk sync ke native.
  void syncWithNative() {
    if (_masterLockEnabled) {
      nativeService.startService();
      _pushLockedAppsToNative();
    }
  }
}
