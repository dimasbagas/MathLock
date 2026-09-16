
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/supabase_config.dart';

import 'database_service.dart';

class AuthService {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Future<String> signUpWithEmailPassword(String email, String password, String fullName, String username) async {
    try {
      final AuthResponse response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
        },
      );
      final User? user = response.user;
      if (user != null) {
        return 'Check your email for verification';
      } else {
        return 'Sign up failed, please try again.';
      }
    } on AuthException catch (e) {
      debugPrint('AuthException signing up: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return 'An error occurred during sign up.';
    }
  }

  Future<String> signInWithEmailPassword(String email, String password) async {
    try {
      final AuthResponse response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final User? user = response.user;
      if (user != null) {
        return 'Login successful';
      } else {
        return 'Login failed, please try again.';
      }
    } on AuthException catch (e) {
      debugPrint('AuthException signing in: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return 'Invalid email or password.';
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb || (defaultTargetPlatform == TargetPlatform.iOS) ? SupabaseConfig.googleWebClientId : null,
        serverClientId: SupabaseConfig.googleWebClientId,
      );

      // Force account selection by disconnecting first on the same client config
      try {
        await googleSignIn.disconnect();
      } catch (_) {}
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return 'Sign in cancelled';
      }

      // 2. Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return 'Could not obtain Google ID Token';
      }

      // 3. Authenticate with Supabase using ID Token
      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final User? user = response.user;
      if (user != null) {
        return 'Login successful';
      } else {
        return 'Login failed, please try again.';
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return 'Google Sign-In Error: $e';
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    try {
      await GoogleSignIn(
        clientId: SupabaseConfig.googleWebClientId,
        serverClientId: SupabaseConfig.googleWebClientId,
      ).signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  // ── Sync Statistics ────────────────────────────────────────────────────────
  Future<void> syncUnlockEvents(List<UnlockEvent> localEvents) async {
    final user = currentUser;
    if (user == null) return;
    if (localEvents.isEmpty) return;

    final data = localEvents.map((e) => {
      'user_id': user.id,
      'package_name': e.packageName,
      'app_name': e.appName,
      'timestamp': e.timestamp,
      'success': e.success,
      'attempts': e.attempts,
      'duration_ms': e.durationMs,
      'formula': e.formula,
      'answer': e.answer,
    }).toList();

    await client.from('unlock_events').upsert(
      data,
      onConflict: 'user_id,timestamp,package_name',
    );
  }

  // ── Sync Settings ─────────────────────────────────────────────────────────
  Future<void> syncSettings({
    required bool masterLockEnabled,
    required int difficultyLevel,
    required bool biometricEnabled,
    required bool isDarkTheme,
    required bool isPremium,
    required int premiumExpiry,
    required List<String> lockedPackages,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('user_settings').upsert({
      'user_id': user.id,
      'master_lock_enabled': masterLockEnabled,
      'difficulty_level': difficultyLevel,
      'biometric_enabled': biometricEnabled,
      'is_dark_theme': isDarkTheme,
      'is_premium': isPremium,
      'premium_expiry': premiumExpiry,
      'locked_packages': lockedPackages,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> fetchSettings() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return null;
    }
  }
}
