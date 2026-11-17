import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/core/discovery/adb_mdns_fallback.dart';
import 'package:hopper/core/discovery/models/discovered_service.dart';

void main() {
  group('Discovery & MDNS Fallback Parser', () {
    test('parseServices parses adb mdns services output correctly', () {
      const output = '''
List of discovered mdns services
adb-38291-pairing._adb-tls-pairing._tcp.\t192.168.1.100:38291
adb-41234-connect._adb-tls-connect._tcp.\t192.168.1.100:41234
''';

      final services = AdbMdnsFallback.parseServices(output);
      expect(services.length, 2);

      final pairing = services.firstWhere((s) => s.type == DiscoveredServiceType.pairing);
      expect(pairing.ip, '192.168.1.100');
      expect(pairing.port, 38291);
      expect(pairing.instanceName, 'adb-38291-pairing');

      final connect = services.firstWhere((s) => s.type == DiscoveredServiceType.connect);
      expect(connect.ip, '192.168.1.100');
      expect(connect.port, 41234);
      expect(connect.instanceName, 'adb-41234-connect');
    });

    test('DiscoveredService equality works as expected', () {
      final s1 = DiscoveredService(
        type: DiscoveredServiceType.connect,
        instanceName: 'phone1',
        ip: '192.168.1.20',
        port: 5555,
      );
      final s2 = DiscoveredService(
        type: DiscoveredServiceType.connect,
        instanceName: 'phone1',
        ip: '192.168.1.20',
        port: 5555,
      );

      expect(s1, equals(s2));
    });
  });
}
