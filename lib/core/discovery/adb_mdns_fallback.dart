import 'models/discovered_service.dart';

class AdbMdnsFallback {
  AdbMdnsFallback._();

  /// Parses the raw output of `adb mdns services`.
  static List<DiscoveredService> parseServices(String output) {
    final services = <DiscoveredService>[];
    final lines = output.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of discovered')) {
        continue;
      }

      // Expected line pattern: <instance>._adb-tls-(pairing|connect)._tcp. <ip>:<port>
      // Or separated by tabs/spaces
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final serviceFull = parts[0];
      final addressPart = parts[1];

      final isPairing = serviceFull.contains('_adb-tls-pairing._tcp');
      final isConnect = serviceFull.contains('_adb-tls-connect._tcp');

      if (!isPairing && !isConnect) continue;

      final type = isPairing
          ? DiscoveredServiceType.pairing
          : DiscoveredServiceType.connect;

      // Extract instance name
      final dotIdx = serviceFull.indexOf('._adb-tls');
      final instanceName = dotIdx != -1
          ? serviceFull.substring(0, dotIdx)
          : serviceFull;

      // Extract IP and port
      final addrSplit = addressPart.split(':');
      if (addrSplit.length != 2) continue;

      final ip = addrSplit[0];
      final port = int.tryParse(addrSplit[1]);
      if (port == null) continue;

      services.add(
        DiscoveredService(
          type: type,
          instanceName: instanceName,
          ip: ip,
          port: port,
        ),
      );
    }

    return services;
  }
}
