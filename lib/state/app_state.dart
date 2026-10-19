import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import '../config/app_config.dart';
import '../services/app_lock_native_service.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../services/supabase_service.dart';

/// Cloud settings hanya boleh menimpa state lokal kalau cloud lebih baru.
/// Kalau cloud tidak punya timestamp, hanya terapkan pada instalasi yang
/// belum punya perubahan lokal (`localUpdatedAt == 0`).
bool shouldApplyRemoteSettings({
  required int localUpdatedAt,
  required int remoteUpdatedAt,
}) {
  if (remoteUpdatedAt <= 0) return localUpdatedAt <= 0;
  return localUpdatedAt <= remoteUpdatedAt;
}

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
  int    _settingsUpdatedAt = 0; // epoch ms, untuk konflik sync Supabase

  final AppLockNativeService  nativeService  = AppLockNativeService();
  final PreferencesService    _prefs         = PreferencesService();
  final DatabaseService       database       = DatabaseService();

  List<AppItem> apps         = [];
  bool          isLoadingApps = true;
  bool          _appsLoadSucceeded = false;
  bool          _initialized  = false;

  late final Future<void> _initFuture;

  AppState() {
    _initFuture = _init();
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
    _settingsUpdatedAt = await _prefs.getSettingsUpdatedAt();

    // Migrasi untuk instalasi lama: kalau sudah ada lock individual tapi
    // belum punya timestamp, anggap state lokal lebih baru daripada cloud.
    // Ini mencegah cloud lama (mis. locked_packages kosong) menghapus pilihan
    // user saat aplikasi dibuka ulang.
    if (_settingsUpdatedAt == 0) {
      final localLockedPackages = await _prefs.getLockedPackages();
      if (localLockedPackages.isNotEmpty) {
        _settingsUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        await _prefs.setSettingsUpdatedAt(_settingsUpdatedAt);
      }
    }

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
      _appsLoadSucceeded = true;

      await _enforceFreeLimit();
    } catch (e) {
      debugPrint('Failed to load apps: $e');
      return;
    } finally {
      isLoadingApps = false;
      notifyListeners();
    }

    // Setelah daftar app selesai dimuat, dorong gabungan state lock
    // (native + Flutter prefs) kembali ke native. Ini mencegah daftar
    // native tertimpa kosong saat startup sebelum app list siap.
    if (_masterLockEnabled && AppConfig.enableAppLock) {
      await _pushLockedAppsToNative();
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  /// Selesai setelah settings dan daftar aplikasi selesai dimuat.
  Future<void> get ready => _initFuture;

  bool get masterLockEnabled => _masterLockEnabled;
  int  get difficultyLevel   => _difficultyLevel;
  int  get relockIntervalMinutes => _relockIntervalMinutes;
  bool get biometricEnabled  => _biometricEnabled;
  bool get isDarkTheme       => _isDarkTheme;
  bool get initialized       => _initialized;
  int  get settingsUpdatedAt => _settingsUpdatedAt;
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
      _markSettingsChanged();
      if (_masterLockEnabled) _pushLockedAppsToNative();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Catat bahwa setting lokal berubah, supaya restore cloud yang lebih lama
  /// tidak menimpa pilihan user saat startup berikutnya.
  void _markSettingsChanged() {
    _settingsUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    _prefs.setSettingsUpdatedAt(_settingsUpdatedAt);
  }

  /// Dipanggil setelah sync manual ke Supabase berhasil.
  void markSettingsSynced() {
    _markSettingsChanged();
    debugPrint('[AppState] Settings ditandai sudah tersinkron');
  }

  /// Toggle master lock ON/OFF.
  /// Perbaikan: tidak lagi mengubah status lock individual tiap app.
  /// Lock individual tetap tersimpan, hanya enforcement-nya yang dihidupkan/matikan.
  void setMasterLock(bool value) {
    _masterLockEnabled = value;
    _prefs.setMasterLock(value);
    _markSettingsChanged();
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
    _markSettingsChanged();
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
    _markSettingsChanged();
    AdService.instance.updatePremiumStatus(true);
    notifyListeners();
  }

  Future<void> cancelPremium() async {
    _isPremium = false;
    _premiumExpiry = 0;
    await _prefs.setPremiumStatus(false);
    await _prefs.setPremiumExpiry(0);
    _markSettingsChanged();
    AdService.instance.updatePremiumStatus(false);
    
    await _enforceFreeLimit();
    notifyListeners();
  }

  void setDifficulty(int level) {
    assert(level >= 0 && level <= 3);
    _difficultyLevel = level;
    _prefs.setDifficulty(level);
    _markSettingsChanged();
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setRelockInterval(int minutes) {
    _relockIntervalMinutes = minutes;
    _prefs.setRelockInterval(minutes);
    _markSettingsChanged();
    if (_masterLockEnabled) _pushLockedAppsToNative();
    notifyListeners();
  }

  void setBiometric(bool value) {
    _biometricEnabled = value;
    _prefs.setBiometric(value);
    _markSettingsChanged();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _prefs.setDarkTheme(_isDarkTheme);
    _markSettingsChanged();
    notifyListeners();
  }

  // ── Native sync ────────────────────────────────────────────────────────────

  Future<void> _pushLockedAppsToNative() async {
    // Jangan menimpa daftar native selama app list belum selesai dimuat
    // atau gagal dimuat (race condition saat aplikasi dibuka ulang).
    if (isLoadingApps || !_appsLoadSucceeded) return;

    final lockedApps = apps
        .where((a) => a.isLocked)
        .map((a) => {'package': a.packageName, 'name': a.name})
        .toList();
    debugPrint('[AppState] Sync ${lockedApps.length} aplikasi terkunci ke native');
    await nativeService.updateLockedApps(
      lockedApps,
      _difficultyLevel,
      relockIntervalMinutes: _relockIntervalMinutes,
    );
  }

  /// Dipanggil dari [MainScaffold] saat startup untuk sync ke native.
  /// Tunggu inisialisasi selesai supaya status master lock dan daftar app
  /// yang dipakai sudah benar (bukan nilai default sementara).
  Future<void> syncWithNative() async {
    try {
      await _initFuture;
    } catch (e) {
      debugPrint('Error waiting for AppState init: $e');
    }

    if (_masterLockEnabled && AppConfig.enableAppLock) {
      nativeService.startService();
      await _pushLockedAppsToNative();
    } else {
      nativeService.stopService();
    }
    await restoreSettingsFromSupabase();
  }

  int _remoteUpdatedAtMs(Map<String, dynamic> remote) {
    final raw = remote['updated_at'];
    if (raw is String) {
      return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    }
    if (raw is DateTime) return raw.millisecondsSinceEpoch;
    if (raw is int) return raw;
    return 0;
  }

  Future<void> restoreSettingsFromSupabase() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final remote = await authService.fetchSettings();
      if (remote != null) {
        final remoteUpdatedAt = _remoteUpdatedAtMs(remote);

        // Konflik sync: jangan timpa perubahan lokal yang lebih baru dengan
        // data cloud lama. Ini penyebab lock yang baru dipilih bisa hilang
        // saat aplikasi dibuka ulang.
        if (!shouldApplyRemoteSettings(
          localUpdatedAt: _settingsUpdatedAt,
          remoteUpdatedAt: remoteUpdatedAt,
        )) {
          debugPrint(
            '[AppState] Local settings lebih baru '
            '(local=$_settingsUpdatedAt, remote=$remoteUpdatedAt). '
            'Skip restore cloud.',
          );
          return;
        }

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

        // Tandai bahwa state lokal sekarang mengikuti cloud, supaya perubahan
        // lokal berikutnya dibandingkan terhadap timestamp ini.
        _settingsUpdatedAt =
            remoteUpdatedAt > 0 ? remoteUpdatedAt : DateTime.now().millisecondsSinceEpoch;
        await _prefs.setSettingsUpdatedAt(_settingsUpdatedAt);

        AdService.instance.updatePremiumStatus(_isPremium);
        notifyListeners();

        // Terapkan juga hasil restore ke layer native. Tanpa ini, setting
        // dari cloud hanya berubah di UI/prefs Flutter, sementara service
        // masih memakai daftar & difficulty lama.
        if (AppConfig.enableAppLock) {
          if (_masterLockEnabled) {
            nativeService.startService();
            await _pushLockedAppsToNative();
          } else {
            nativeService.stopService();
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring settings from Supabase: $e');
    }
  }
}
