import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../config/app_config.dart';

class AdService extends WidgetsBindingObserver {
  static final AdService instance = AdService._();
  AdService._();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _appOpenLoadTime;

  RewardedAd? _rewardedAd;
  bool _isLoadingRewardedAd = false;

  // ── Ad Unit IDs ────────────────────────────────────────────────────────────
  // Gunakan TEST ID saat debug, ID nyata saat release.
  // Test App Open Ad ID dari Google (selalu bekerja di debug mode):
  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/9257395921'; // App Open Ad test ID
  static const String _productionAdUnitId =
      'ca-app-pub-2527505225464124/2361710116';

  static String get appOpenAdUnitId =>
      kDebugMode ? _testAdUnitId : _productionAdUnitId;

  // Test Rewarded Ad ID dari Google (selalu bekerja di debug mode):
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Rewarded Ad test ID
  static const String _productionRewardedAdUnitId =
      'ca-app-pub-2527505225464124/8032157974';

  static String get rewardedAdUnitId =>
      kDebugMode ? _testRewardedAdUnitId : _productionRewardedAdUnitId;

  bool _isPremiumUser = false;
  bool _initialized = false;

  // Callback list yang menunggu iklan siap
  final List<VoidCallback> _pendingCallbacks = [];

  // Callback list yang menunggu iklan rewarded siap
  final List<VoidCallback> _pendingRewardedCallbacks = [];
  Timer? _rewardedTimeoutTimer;

  void updatePremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
    if (_isPremiumUser) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _rewardedAd?.dispose();
      _rewardedAd = null;
    } else {
      if (_initialized) {
        loadAd();
        loadRewardedAd();
      }
    }
  }

  Future<void> initialize() async {
    if (!AppConfig.enableAds) {
      debugPrint('[AdService] Ads dimatikan via AppConfig.enableAds = false');
      return;
    }
    if (_initialized) return;
    try {
      // Daftarkan device ID fisik sebagai test device agar iklan test selalu tampil.
      // ID ini didapat dari logcat: "Use RequestConfiguration.Builder()..."
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['023F7636ADF0793DAF355E1C8142BB69'],
        ),
      );
      debugPrint('[AdService] Test device registered: 023F7636ADF0793DAF355E1C8142BB69');

      final initStatus = await MobileAds.instance.initialize();
      debugPrint('[AdService] MobileAds initialized. Adapter statuses:');
      initStatus.adapterStatuses.forEach((adapter, status) {
        debugPrint('[AdService]   $adapter: ${status.state} – ${status.description}');
      });
      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
      loadAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Error initializing AdMob: $e');
    }
  }

  /// Load an AppOpenAd.
  void loadAd() {
    if (!AppConfig.enableAds || _isPremiumUser || !_initialized || _isLoadingAd) return;
    // Jangan load ulang jika iklan masih valid
    if (_isAdAvailable) return;

    _isLoadingAd = true;
    debugPrint('[AdService] Loading App Open Ad (unit: $appOpenAdUnitId)...');

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAd = false;
          debugPrint('[AdService] ✅ App Open Ad loaded successfully!');
          // Tampilkan iklan ke semua callback yang sedang menunggu
          _flushPendingCallbacks();
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          debugPrint('[AdService] ❌ AppOpenAd failed to load: '
              'code=${error.code}, message=${error.message}, domain=${error.domain}');
          // Panggil semua pending callback tanpa iklan
          for (final cb in _pendingCallbacks) {
            cb();
          }
          _pendingCallbacks.clear();
        },
      ),
    );
  }

  /// Load a RewardedAd.
  void loadRewardedAd() {
    if (_isPremiumUser || !_initialized || _isLoadingRewardedAd) return;
    if (_rewardedAd != null) return; // already loaded

    _isLoadingRewardedAd = true;
    debugPrint('[AdService] Loading Rewarded Ad (unit: $rewardedAdUnitId)...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
          debugPrint('[AdService] ✅ Rewarded Ad loaded successfully!');
          _flushPendingRewardedCallbacks(failed: false);
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedAd = false;
          debugPrint('[AdService] ❌ RewardedAd failed to load: '
              'code=${error.code}, message=${error.message}, domain=${error.domain}');
          _rewardedAd = null;
          _flushPendingRewardedCallbacks(failed: true);
        },
      ),
    );
  }

  /// Check if ad is still valid (loaded less than 4 hours ago).
  bool get _isAdAvailable {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  /// Show the ad if available (used on app resume lifecycle).
  void showAdIfAvailable() {
    if (_isPremiumUser || !_initialized) return;
    if (_isShowingAd) return;
    if (!_isAdAvailable) {
      loadAd();
      return;
    }
    _showAd(onComplete: null);
  }

  /// Show Rewarded Ad, then call [onComplete] when ad is dismissed or unavailable.
  /// If no rewarded ad is loaded yet, triggers load and proceeds immediately.
  void showAdWithCallback(VoidCallback onComplete) {
    if (_isPremiumUser || !_initialized) {
      debugPrint('[AdService] Skipping ad: premium=$_isPremiumUser, initialized=$_initialized');
      onComplete();
      return;
    }

    if (_rewardedAd != null) {
      debugPrint('[AdService] Rewarded Ad available, showing now...');
      _showRewardedAd(onComplete);
    } else if (_isLoadingRewardedAd) {
      debugPrint('[AdService] Rewarded Ad is loading, waiting for it...');
      _pendingRewardedCallbacks.add(onComplete);
      _rewardedTimeoutTimer?.cancel();
      _rewardedTimeoutTimer = Timer(const Duration(seconds: 4), () {
        if (_pendingRewardedCallbacks.contains(onComplete)) {
          debugPrint('[AdService] Rewarded Ad load timed out (4s), bypassing.');
          _pendingRewardedCallbacks.remove(onComplete);
          onComplete();
        }
      });
    } else {
      debugPrint('[AdService] Rewarded Ad not ready, starting load and calling onComplete immediately.');
      loadRewardedAd();
      onComplete();
    }
  }

  void _flushPendingRewardedCallbacks({bool failed = false}) {
    _rewardedTimeoutTimer?.cancel();
    if (_pendingRewardedCallbacks.isEmpty) return;
    final callbacks = List<VoidCallback>.from(_pendingRewardedCallbacks);
    _pendingRewardedCallbacks.clear();

    if (failed || _rewardedAd == null) {
      for (final cb in callbacks) {
        cb();
      }
    } else {
      _showRewardedAd(() {
        for (final cb in callbacks) {
          cb();
        }
      });
    }
  }

  void _showRewardedAd(VoidCallback onComplete) {
    if (_rewardedAd == null) {
      onComplete();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[AdService] Rewarded Ad is showing full screen.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Rewarded Ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        onComplete();
        loadRewardedAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded Ad dismissed by user.');
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        onComplete();
        loadRewardedAd();
      },
    );

    debugPrint('[AdService] Calling _rewardedAd!.show()...');
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
      },
    );
  }

  void _flushPendingCallbacks() {
    if (_pendingCallbacks.isEmpty) return;
    final callbacks = List<VoidCallback>.from(_pendingCallbacks);
    _pendingCallbacks.clear();

    _showAd(onComplete: () {
      for (final cb in callbacks) {
        cb();
      }
    });
  }

  void _showAd({VoidCallback? onComplete}) {
    if (_appOpenAd == null) {
      debugPrint('[AdService] _showAd called but _appOpenAd is null!');
      onComplete?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[AdService] Ad is showing full screen.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onComplete?.call();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed by user.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onComplete?.call();
        loadAd();
      },
    );

    debugPrint('[AdService] Calling _appOpenAd!.show()...');
    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAdIfAvailable();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _rewardedAd?.dispose();
  }
}
