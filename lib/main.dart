import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';
import 'screens/lock_route_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'state/app_state.dart';
import 'services/ad_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Silence logs in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Initialize AdMob
  await AdService.instance.initialize();

  final appState = AppState();

  // When LockActivity launches this Flutter engine it sets the initial route
  // to "/lock" — detect that and run a minimal lock-only app instead of the
  // full MainScaffold to avoid unnecessary initialisation overhead.
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  if (initialRoute == '/lock') {
    runApp(_LockModeApp(appState: appState));
  } else {
    runApp(MathLockApp(appState: appState));
  }
}

// ── Normal app ────────────────────────────────────────────────────────────────

class MathLockApp extends StatelessWidget {
  final AppState appState;
  const MathLockApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'MathLock',
          debugShowCheckedModeBanner: false,
          theme: appState.isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: AuthWrapper(appState: appState),
          routes: {
            '/home': (context) => MainScaffold(appState: appState),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}

// ── Lock-only app (runs inside LockActivity) ──────────────────────────────────

class _LockModeApp extends StatelessWidget {
  final AppState appState;
  const _LockModeApp({required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appState.isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme,
          initialRoute: '/lock',
          routes: {
            '/lock': (context) => LockRouteScreen(appState: appState),
          },
        );
      },
    );
  }
}
