import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathlockv2/screens/login_screen.dart';
import 'package:mathlockv2/screens/main_scaffold.dart';
import 'package:mathlockv2/state/app_state.dart'; // Import AppState

class AuthWrapper extends StatelessWidget {
  final AppState appState; // Terima appState
  const AuthWrapper({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is logged in
        final session = snapshot.data?.session;
        final user = session?.user;

        if (user != null) {
          // User is logged in, show home/app list screen (scaffold with tabs)
          return MainScaffold(appState: appState); // Pass appState
        } else {
          // User is not logged in, show login screen
          return const LoginScreen();
        }
      },
    );
  }
}
