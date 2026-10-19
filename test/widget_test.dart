import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlockv2/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppState initializes with default values', () async {
    SharedPreferences.setMockInitialValues({});

    final appState = AppState();
    await appState.ready;

    expect(appState.masterLockEnabled, true);
    expect(appState.difficultyLevel, 1);
    expect(appState.isDarkTheme, true);
    // AppConfig.enablePremiumRestrictions = false → fitur premium terbuka.
    expect(appState.isPremium, true);
  });
}
