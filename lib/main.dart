import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';
import 'screens/lock_route_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // When LockActivity launches this Flutter engine it sets the initial route
  // to "/lock" — detect that and run a minimal lock-only app instead of the
  // full MainScaffold to avoid unnecessary initialisation overhead.
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  if (initialRoute == '/lock') {
    runApp(const _LockModeApp());
  } else {
    runApp(const MathLockApp());
  }
}

// ── Normal app ────────────────────────────────────────────────────────────────

class MathLockApp extends StatelessWidget {
  const MathLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobalt Fortress',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}

// ── Lock-only app (runs inside LockActivity) ──────────────────────────────────

class _LockModeApp extends StatelessWidget {
  const _LockModeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/lock',
      routes: {
        '/lock': (context) => const LockRouteScreen(),
      },
    );
  }
}
