class Validators {
  Validators._();

  static final RegExp _ipv4Regex = RegExp(
    r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$',
  );

  static final RegExp _serialRegex = RegExp(r'^[a-zA-Z0-9.:_-]+$');

  static final RegExp _packageRegex = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  static bool isValidIp(String? ip) {
    if (ip == null || ip.isEmpty) return false;
    return _ipv4Regex.hasMatch(ip.trim());
  }

  static bool isValidPort(int? port) {
    if (port == null) return false;
    return port > 0 && port <= 65535;
  }

  static bool isValidPortString(String? portStr) {
    if (portStr == null || portStr.isEmpty) return false;
    final p = int.tryParse(portStr.trim());
    return isValidPort(p);
  }

  static bool isValidSerial(String? serial) {
    if (serial == null || serial.isEmpty) return false;
    return _serialRegex.hasMatch(serial.trim());
  }

  static bool isValidPackageName(String? pkg) {
    if (pkg == null || pkg.isEmpty) return false;
    return _packageRegex.hasMatch(pkg.trim());
  }

  static bool isValidPairingCode(String? code) {
    if (code == null) return false;
    final trimmed = code.trim();
    return trimmed.length == 6 && RegExp(r'^\d{6}$').hasMatch(trimmed);
  }
}
