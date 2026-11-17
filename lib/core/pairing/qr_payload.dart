import 'dart:math';

class QrPayload {
  final String serviceName;
  final String password;

  QrPayload({
    required this.serviceName,
    required this.password,
  });

  /// Generates the standard Android 11+ Wireless Debugging QR string:
  /// `WIFI:T:ADB;S:<serviceName>;P:<password>;;`
  String get payloadString => 'WIFI:T:ADB;S:$serviceName;P:$password;;';

  factory QrPayload.generate() {
    final random = Random.secure();
    final serviceId = (100000 + random.nextInt(900000)).toString();
    final serviceName = 'hopper-$serviceId';

    // 6-digit random password
    final password = (100000 + random.nextInt(900000)).toString();

    return QrPayload(
      serviceName: serviceName,
      password: password,
    );
  }
}
