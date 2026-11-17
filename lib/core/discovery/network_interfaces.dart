import 'dart:io';

class NetworkInterfacesHelper {
  NetworkInterfacesHelper._();

  /// Returns the most suitable local network interface for Wi-Fi / LAN mDNS.
  static Future<NetworkInterface?> getPreferredInterface() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      if (interfaces.isEmpty) return null;

      // Filter out virtual/tunnel adapters
      final filtered = interfaces.where((it) {
        final name = it.name.toLowerCase();
        return !name.contains('wsl') &&
            !name.contains('vEthernet') &&
            !name.contains('vethernet') &&
            !name.contains('hyper-v') &&
            !name.contains('virtual') &&
            !name.contains('tailscale') &&
            !name.contains('zerotier') &&
            !name.contains('docker') &&
            !name.contains('tap') &&
            !name.contains('tun');
      }).toList();

      if (filtered.isNotEmpty) {
        // Prefer Wi-Fi or Wireless names
        final wifi = filtered.firstWhere(
          (it) {
            final name = it.name.toLowerCase();
            return name.contains('wi-fi') ||
                name.contains('wireless') ||
                name.contains('wlan');
          },
          orElse: () => filtered.first,
        );
        return wifi;
      }

      return interfaces.first;
    } catch (e) {
      return null;
    }
  }
}
