import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import '../config/app_config.dart';
import '../services/app_lock_native_service.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../services/supabase_service.dart';

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
  int    _difficultyLevel   = 1; // 0=SD, 1=SMP, 2=SMA, 3=PT
  int    _relockIntervalMinutes = 15; // default 15 mins
  bool   _biometricEnabled  = true;
  bool   _isDarkTheme       = true;
  bool   _isPremium         = false;
  int    _premiumExpiry     = 0; // 0 = lifetime / no expiry

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
    _relockIntervalMinutes = await _prefs.getRelockInterval();
    _biometricEnabled  = await _prefs.getBiometric();
    _isDarkTheme       = await _prefs.getDarkTheme();
    _isPremium         = await _prefs.getPremiumStatus();
    _premiumExpiry     = await _prefs.getPremiumExpiry();

    // Check expiry
    if (_isPremium && _premiumExpiry > 0 && DateTime.now().millisecondsSinceEpoch > _premiumExpiry) {
      _isPremium = false;
      await _prefs.setPremiumStatus(false);
    }

    AdService.instance.updatePremiumStatus(_isPremium);
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

      await _enforceFreeLimit();
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
  int  get relockIntervalMinutes => _relockIntervalMinutes;
  bool get biometricEnabled  => _biometricEnabled;
  bool get isDarkTheme       => _isDarkTheme;
  bool get initialized       => _initialized;
  bool get isPremium         => !AppConfig.enablePremiumRestrictions || _isPremium;
  int  get premiumExpiry     => _premiumExpiry;
  int  get actualLockedCount => apps.where((a) => a.isLocked).length;

  int get lockedCount =>
      _masterLockEnabled ? apps.where((a) => a.isLocked).length : 0;
  int get unlockedCount =>
      _masterLockEnabled ? apps.where((a) => !a.isLocked).length : apps.length;

  // Difficulty helpers
  static const List<String> difficultyLabels    = ['SD',              'SMP',            'SMA',            'PT'];
  static const List<String> difficultyNames     = ['DASAR',           'AKTIF',          'LANJUT',         'PAKAR'];
  static const List<String> complexityLabels    = ['BAS',             'MID',            'ADV',            'EXP'];
  static const List<String> complexitySubtitles = ['ELEMENTARY LEVEL','INTERMEDIATE LEVEL','CALCULUS-READY','EXPERT MODE'];
  static const List<double> complexityProgress  = [0.25,              0.5,              0.75,             1.0];

  void _checkPremiumExpiry() {
    if (_isPremium && _premiumExpiry > 0 && DateTime.now().millisecondsSinceEpoch > _premiumExpiry) {
      _isPremium = false;
      _premiumExpiry = 0;
      _prefs.setPremiumStatus(false);
      _prefs.setPremiumExpiry(0);
      AdService.instance.updatePremiumStatus(false);
      notifyListeners();
    }
  }

  Future<void> _enforceFreeLimit() async {
    if (isPremium) return;
    int count = 0;
    bool changed = false;
    for (var app in apps) {
      if (app.isLocked) {
        count++;
        if (count > 2) {
          app.isLocked = false;
          changed = true;
        }
      }
    }
    if (changed) {
      final lockedPackages = apps
          .where((a) => a.isLocked)
          .map((a) => a.packageName)
          .toSet();
      await _prefs.setLockedPackages(lockedPackages);
      if (_masterLockEnabled) _pushLockedAppsToNative();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Toggle master lock ON/OFF.
  /// Perbaikan: tidak lagi mengubah status lock individual tiap app.
  /// Lock individual tetap tersimpan, hanya enforcement-nya yang dihidupkan/matikan.
  void setMasterLock(bool value) {
    _masterLockEnabled = value;
    _prefs.setMasterLock(value);
    if (value && AppConfig.enableAppLock) {
      nativeService.startService();
      _pushLockedAppsToNative();
    } else {
      nativeService.stopService();
    }
    notifyListeners();
  }

  bool toggleApp(AppItem app) {
    _checkPremiumExpiry();
    if (!app.isLocked && !isPremium && actualLockedCount >= 2) {
      return false; // Limit reached for free users
    }
    app.isLocked = !app.isLocked;
    // Simpan state per-app ke Flutter SharedPrefs
    final lockedPackages = apps
        .where((a) => a.isLocked)
        .map((a) => a.packageName)
        .toSet();
    _prefs.setLockedPackages(lockedPackages);
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
    return true;
  }

  Future<void> upgradeToPremium(int months) async {
    _isPremium = true;
    if (months > 0) {
      final expiry = DateTime.now().add(Duration(days: months * 30)).millisecondsSinceEpoch;
      _premiumExpiry = expiry;
      await _prefs.setPremiumExpiry(expiry);
    } else {
      _premiumExpiry = 0; // Lifetime
      await _prefs.setPremiumExpiry(0);
    }
    await _prefs.setPremiumStatus(true);
    AdService.instance.updatePremiumStatus(true);
    notifyListeners();
  }

  Future<void> cancelPremium() async {
    _isPremium = false;
    _premiumExpiry = 0;
    await _prefs.setPremiumStatus(false);
    await _prefs.setPremiumExpiry(0);
    AdService.instance.updatePremiumStatus(false);
    
    await _enforceFreeLimit();
    notifyListeners();
  }

  void setDifficulty(int level) {
    assert(level >= 0 && level <= 3);
    _difficultyLevel = level;
    _prefs.setDifficulty(level);
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setRelockInterval(int minutes) {
    _relockIntervalMinutes = minutes;
    _prefs.setRelockInterval(minutes);
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setBiometric(bool value) {
    _biometricEnabled = value;
    _prefs.setBiometric(value);
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _prefs.setDarkTheme(_isDarkTheme);
    notifyListeners();
  }

  // ── Native sync ────────────────────────────────────────────────────────────

  void _pushLockedAppsToNative() {
    final lockedApps = apps
        .where((a) => a.isLocked)
        .map((a) => {'package': a.packageName, 'name': a.name})
        .toList();
    nativeService.updateLockedApps(
      lockedApps,
      _difficultyLevel,
      relockIntervalMinutes: _relockIntervalMinutes,
    );
  }

  /// Dipanggil dari [MainScaffold] saat startup untuk sync ke native.
  void syncWithNative() {
    if (_masterLockEnabled && AppConfig.enableAppLock) {
      nativeService.startService();
      _pushLockedAppsToNative();
    } else {
      nativeService.stopService();
    }
    restoreSettingsFromSupabase();
  }

  Future<void> restoreSettingsFromSupabase() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final remote = await authService.fetchSettings();
      if (remote != null) {
        _masterLockEnabled = remote['master_lock_enabled'] as bool? ?? _masterLockEnabled;
        _difficultyLevel = remote['difficulty_level'] as int? ?? _difficultyLevel;
        _biometricEnabled = remote['biometric_enabled'] as bool? ?? _biometricEnabled;
        _isDarkTheme = remote['is_dark_theme'] as bool? ?? _isDarkTheme;
        _isPremium = remote['is_premium'] as bool? ?? _isPremium;
        _premiumExpiry = remote['premium_expiry'] as int? ?? _premiumExpiry;

        // Persist locally
        await _prefs.setMasterLock(_masterLockEnabled);
        await _prefs.setDifficulty(_difficultyLevel);
        await _prefs.setBiometric(_biometricEnabled);
        await _prefs.setDarkTheme(_isDarkTheme);
        await _prefs.setPremiumStatus(_isPremium);
        await _prefs.setPremiumExpiry(_premiumExpiry);

        // Locked apps
        final List<dynamic>? lockedList = remote['locked_packages'] as List<dynamic>?;
        if (lockedList != null) {
          final lockedSet = lockedList.map((e) => e.toString()).toSet();
          await _prefs.setLockedPackages(lockedSet);
          // Sync with local apps list
          for (var app in apps) {
            app.isLocked = lockedSet.contains(app.packageName);
          }
        }

        AdService.instance.updatePremiumStatus(_isPremium);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring settings from Supabase: $e');
    }
  }
}
