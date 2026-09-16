import 'package:flutter_test/flutter_test.dart';

import 'package:mathlockv2/state/app_state.dart';

void main() {
  test('AppState initializes with default values', () async {
    final appState = AppState();
    expect(appState.masterLockEnabled, true);
    expect(appState.difficultyLevel, 1);
    expect(appState.isDarkTheme, true);
    expect(appState.isPremium, false);
  });
}

