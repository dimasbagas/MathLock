import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'math_lock_screen.dart';

/// Flutter screen rendered inside [LockActivity].
///
/// On [initState] it calls native `getLockData` to retrieve the name of the
/// blocked app and the active difficulty level, then hands off to
/// [MathLockScreen].  The only way to dismiss this screen is by solving the
/// math challenge correctly — [onDismiss] is intentionally `null`.
class LockRouteScreen extends StatefulWidget {
  const LockRouteScreen({super.key});

  @override
  State<LockRouteScreen> createState() => _LockRouteScreenState();
}

class _LockRouteScreenState extends State<LockRouteScreen> {
  static const _channel = MethodChannel('com.example.mathlockv2/lock');

  String _appName   = '';
  int    _difficulty = 1;
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
          _appName    = data['appName']    as String? ?? 'App';
          _difficulty = data['difficulty'] as int?    ?? 1;
          _loaded     = true;
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF060C17),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return MathLockScreen(
      appName:         _appName,
      appIcon:         Icons.shield_rounded,
      appColor:        const Color(0xFF3B82F6),
      difficultyLevel: _difficulty,
      onUnlocked:      _onUnlocked,
      onDismiss:       null,  // Cannot bypass the lock
    );
  }
}
