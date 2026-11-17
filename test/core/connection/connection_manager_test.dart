import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/core/connection/connection_manager.dart';
import 'package:hopper/core/connection/connection_state.dart';
import 'package:hopper/core/connection/reconnect_policy.dart';
import '../../fakes/fake_adb_backend.dart';
import '../../fakes/fake_discovery_backend.dart';

void main() {
  group('ReconnectPolicy & ConnectionManager', () {
    test('ReconnectPolicy computes exponential backoff delays', () {
      const policy = ReconnectPolicy();
      expect(policy.getDelayForAttempt(0), Duration.zero);
      expect(policy.getDelayForAttempt(1), const Duration(seconds: 1));
      expect(policy.getDelayForAttempt(2), const Duration(seconds: 2));
      expect(policy.getDelayForAttempt(3), const Duration(seconds: 4));
      expect(policy.getDelayForAttempt(4), const Duration(seconds: 8));
      expect(policy.getDelayForAttempt(5), const Duration(seconds: 30));
    });

    test('ConnectionManager updates state on successful connect', () async {
      final fakeAdb = FakeAdbBackend();
      final fakeDiscovery = FakeDiscoveryBackend();
      final manager = ConnectionManager(
        adbBackend: fakeAdb,
        discoveryBackend: fakeDiscovery,
      );

      final ok = await manager.connectDevice('device-1', '192.168.1.50', 5555);
      expect(ok, isTrue);

      final state = manager.getState('device-1');
      expect(state.status, DeviceStatus.connected);
      expect(state.ip, '192.168.1.50');
      expect(state.port, 5555);
    });

    test('ConnectionManager updates state on failed connect', () async {
      final fakeAdb = FakeAdbBackend()..connectResult = false;
      final fakeDiscovery = FakeDiscoveryBackend();
      final manager = ConnectionManager(
        adbBackend: fakeAdb,
        discoveryBackend: fakeDiscovery,
      );

      final ok = await manager.connectDevice('device-2', '192.168.1.51', 5555);
      expect(ok, isFalse);

      final state = manager.getState('device-2');
      expect(state.status, DeviceStatus.offline);
      expect(state.retryCount, 1);
    });
  });
}
