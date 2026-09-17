import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'math_lock_screen.dart';
import '../services/database_service.dart';
import '../state/app_state.dart';

/// Flutter screen rendered inside [LockActivity].
///
/// On [initState] it calls native `getLockData` to retrieve the name of the
/// blocked app and the active difficulty level, then hands off to
/// [MathLockScreen].  The only way to dismiss this screen is by solving the
/// math challenge correctly — [onDismiss] is intentionally `null`.
class LockRouteScreen extends StatefulWidget {
  final AppState appState;
  const LockRouteScreen({super.key, required this.appState});

  @override
  State<LockRouteScreen> createState() => _LockRouteScreenState();
}

class _LockRouteScreenState extends State<LockRouteScreen> {
  static const _channel = MethodChannel('com.example.mathlockv2/lock');

  String _appName   = '';
  int    _difficulty = 1;
  String _packageName = '';
  String _sessionId   = '';
  bool   _loaded    = false;

  @override
  void initState() {
    super.initState();
    _loadLockData();
  }

  Future<void> _loadLockData() async {
    try {
      final data = await _channel.invokeMethod<Map<Object?, Object?>>('getLockData');
      if (data != null && mounted) {
        setState(() {
          _appName     = data['appName']     as String? ?? 'App';
          _difficulty  = data['difficulty']  as int?    ?? 1;
          _packageName = data['packageName'] as String? ?? '';
          _sessionId   = data['sessionId']   as String? ?? '';
          _loaded      = true;
        });
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() { _appName = 'App'; _loaded = true; });
    }
  }

  Future<void> _onUnlocked() async {
    try {
      await _channel.invokeMethod<void>('dismissLock');
    } on PlatformException catch (_) {}
  }

  /// M2: catat sesi yang berakhir karena user keluar/force-exit (retry detection).
  Future<void> _onSessionEnded({bool forced = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await DatabaseService().insertEvent(UnlockEvent(
      packageName:    _packageName,
      appName:        _appName,
      timestamp:      now,
      success:        false,
      attempts:       0,
      durationMs:     0,
      formula:        '',
      answer:         0,
      sessionId:      _sessionId,
      sessionEndMs:   now,
      forcedExit:     forced,
      lockReason:     forced ? 'forced_exit' : 'screen_off',
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return MathLockScreen(
      appState:        widget.appState,
      appName:         _appName,
      appIcon:         Icons.shield_rounded,
      appColor:        const Color(0xFF3B82F6),
      packageName:     _packageName,
      sessionId:       _sessionId,
      difficultyLevel: _difficulty,
      onUnlocked:      _onUnlocked,
      onDismiss:       null,  // Cannot bypass the lock
    );
  }
}
