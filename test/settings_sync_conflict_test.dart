import 'package:flutter_test/flutter_test.dart';
import 'package:mathlockv2/state/app_state.dart';

void main() {
  group('shouldApplyRemoteSettings', () {
    test('cloud yang lebih lama tidak boleh menimpa lokal', () {
      expect(
        shouldApplyRemoteSettings(
          localUpdatedAt: 200,
          remoteUpdatedAt: 100,
        ),
        isFalse,
      );
    });

    test('cloud yang lebih baru boleh menimpa lokal', () {
      expect(
        shouldApplyRemoteSettings(
          localUpdatedAt: 100,
          remoteUpdatedAt: 200,
        ),
        isTrue,
      );
    });

    test('cloud tanpa timestamp tidak menimpa lokal yang sudah berubah', () {
      expect(
        shouldApplyRemoteSettings(
          localUpdatedAt: 200,
          remoteUpdatedAt: 0,
        ),
        isFalse,
      );
    });

    test('cloud tanpa timestamp tetap dipakai untuk instalasi baru', () {
      expect(
        shouldApplyRemoteSettings(
          localUpdatedAt: 0,
          remoteUpdatedAt: 0,
        ),
        isTrue,
      );
    });

    test('timestamp sama tetap diterapkan', () {
      expect(
        shouldApplyRemoteSettings(
          localUpdatedAt: 100,
          remoteUpdatedAt: 100,
        ),
        isTrue,
      );
    });
  });
}
