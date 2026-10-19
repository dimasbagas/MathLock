import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlockv2/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installedAppsChannel = MethodChannel('installed_apps');
  const appLockChannel = MethodChannel('com.example.mathlockv2/applock');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'master_lock_enabled': true,
      'individually_locked_packages': ['com.example.locked'],
      'difficulty_level': 1,
      'relock_interval_minutes': 15,
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(installedAppsChannel, null);
    messenger.setMockMethodCallHandler(appLockChannel, null);
  });

  test('startup mengirim daftar lock gabungan ke native, bukan list kosong',
      () async {
    final updateCalls = <MethodCall>[];

    messenger.setMockMethodCallHandler(installedAppsChannel, (call) async {
      if (call.method == 'getInstalledApps') {
        return [
          {'name': 'Locked App', 'package_name': 'com.example.locked'},
          {'name': 'Other App', 'package_name': 'com.example.other'},
        ];
      }
      return null;
    });

    messenger.setMockMethodCallHandler(appLockChannel, (call) async {
      switch (call.method) {
        case 'getLockedApps':
          // Simulasikan daftar native yang kosong setelah app dibuka ulang.
          return <String>[];
        case 'updateLockedApps':
          updateCalls.add(call);
          return null;
        default:
          return null;
      }
    });

    final appState = AppState();
    await appState.ready;

    expect(updateCalls, isNotEmpty);

    final packages = updateCalls.last.arguments is Map
        ? ((updateCalls.last.arguments as Map)['apps'] as List)
            .map((app) => (app as Map)['package'])
            .toList()
        : <Object?>[];

    expect(packages, contains('com.example.locked'));
    expect(packages, isNot(contains('com.example.other')));

    final pushedEmptyList = updateCalls.any((call) {
      final args = call.arguments;
      return args is Map && (args['apps'] as List).isEmpty;
    });
    expect(
      pushedEmptyList,
      isFalse,
      reason: 'Daftar native tidak boleh ditimpa kosong saat startup.',
    );
  });
}
