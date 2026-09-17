import 'package:flutter/services.dart';

/// Flutter-side wrapper for the native Android app-lock MethodChannel.
///
/// All methods are fire-and-forget with graceful error handling.
/// Both [PlatformException] and [MissingPluginException] are caught so the
/// app runs safely on iOS / desktop without crashing.
class AppLockNativeService {
  static const _channel = MethodChannel('com.example.mathlockv2/applock');

  static Future<T?> _invoke<T>(String method, [dynamic args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      // Channel not registered — running on a non-Android platform or the
      // native code hasn't been installed yet (hot-restart after native change).
      return null;
    } on PlatformException catch (_) {
      return null;
    }
  }

  Future<void> startService() => _invoke('startService');

  Future<void> stopService() => _invoke('stopService');

  Future<void> updateLockedApps(
    List<Map<String, String>> apps,
    int difficulty, {
    int relockIntervalMinutes = 15,
  }) =>
      _invoke('updateLockedApps', {
        'apps': apps,
        'difficulty': difficulty,
        'relockIntervalMinutes': relockIntervalMinutes,
      });

  Future<List<String>> getLockedApps() async {
    final list = await _invoke<List<dynamic>>('getLockedApps');
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  Future<bool> checkUsagePermission() async =>
      (await _invoke<bool>('checkUsagePermission')) ?? false;

  Future<bool> checkOverlayPermission() async =>
      (await _invoke<bool>('checkOverlayPermission')) ?? false;

  Future<void> requestUsagePermission() => _invoke('requestUsagePermission');

  Future<void> requestOverlayPermission() => _invoke('requestOverlayPermission');
}
