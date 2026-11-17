import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/core/adb/adb_client.dart';
import 'package:hopper/core/adb/models/adb_device.dart';
import '../../fakes/fake_adb_backend.dart';

void main() {
  group('AdbClient & Protocol Parser', () {
    test('formatRequest prepends 4-digit hex length', () {
      expect(AdbClient.formatRequest('host:version'), '000chost:version');
      expect(AdbClient.formatRequest('host:track-devices'),
          '0012host:track-devices');
    });

    test('AdbDevice parses standard adb track line with model & product', () {
      const line =
          '192.168.1.150:41235\tdevice product:panther model:Pixel_7 device:panther transport_id:12';
      final dev = AdbDevice.fromTrackLine(line);

      expect(dev.serial, '192.168.1.150:41235');
      expect(dev.state, 'device');
      expect(dev.model, 'Pixel_7');
      expect(dev.displayName, 'Pixel 7');
      expect(dev.isWireless, isTrue);
      expect(dev.ip, '192.168.1.150');
      expect(dev.port, 41235);
      expect(dev.isConnected, isTrue);
    });

    test('AdbDevice parses unauthorized USB device', () {
      const line = 'RFCW81234AB\tunauthorized transport_id:5';
      final dev = AdbDevice.fromTrackLine(line);

      expect(dev.serial, 'RFCW81234AB');
      expect(dev.isUnauthorized, isTrue);
      expect(dev.isConnected, isFalse);
      expect(dev.isWireless, isFalse);
    });

    test('FakeAdbBackend records commands correctly', () async {
      final fake = FakeAdbBackend();
      expect(await fake.pair('192.168.1.5', 38291, '123456'), isTrue);
      expect(await fake.connect('192.168.1.5', 41234), isTrue);

      expect(fake.executedCommands, [
        'pair 192.168.1.5:38291 123456',
        'connect 192.168.1.5:41234',
      ]);
    });
  });
}
