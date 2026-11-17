enum DeviceConnectionState {
  connected,
  connecting,
  discovered,
  needsApproval,
  offline,
  unreachable,
}

class AdbDevice {
  final String serial;
  final String state; // 'device', 'unauthorized', 'offline', etc.
  final String? model;
  final String? product;
  final String? device;
  final String? transportId;
  final String? ip;
  final int? port;
  final bool isWireless;

  const AdbDevice({
    required this.serial,
    required this.state,
    this.model,
    this.product,
    this.device,
    this.transportId,
    this.ip,
    this.port,
    this.isWireless = false,
  });

  bool get isConnected => state == 'device';
  bool get isUnauthorized => state == 'unauthorized';
  bool get isOffline => state == 'offline';

  String get displayName {
    if (model != null && model!.isNotEmpty) {
      return model!.replaceAll('_', ' ');
    }
    return serial;
  }

  factory AdbDevice.fromTrackLine(String line) {
    // Format: serial\tstate [product:X model:Y device:Z transport_id:W]
    final parts = line.trim().split(RegExp(r'\s+'));
    final serial = parts.isNotEmpty ? parts[0] : '';
    final state = parts.length > 1 ? parts[1] : 'unknown';

    String? model;
    String? product;
    String? device;
    String? transportId;

    for (var i = 2; i < parts.length; i++) {
      final part = parts[i];
      if (part.startsWith('model:')) {
        model = part.substring(6);
      } else if (part.startsWith('product:')) {
        product = part.substring(8);
      } else if (part.startsWith('device:')) {
        device = part.substring(7);
      } else if (part.startsWith('transport_id:')) {
        transportId = part.substring(13);
      }
    }

    final isWireless = serial.contains(':');
    String? ip;
    int? port;
    if (isWireless) {
      final ipPort = serial.split(':');
      ip = ipPort[0];
      if (ipPort.length > 1) {
        port = int.tryParse(ipPort[1]);
      }
    }

    return AdbDevice(
      serial: serial,
      state: state,
      model: model,
      product: product,
      device: device,
      transportId: transportId,
      ip: ip,
      port: port,
      isWireless: isWireless,
    );
  }

  AdbDevice copyWith({
    String? serial,
    String? state,
    String? model,
    String? product,
    String? device,
    String? transportId,
    String? ip,
    int? port,
    bool? isWireless,
  }) {
    return AdbDevice(
      serial: serial ?? this.serial,
      state: state ?? this.state,
      model: model ?? this.model,
      product: product ?? this.product,
      device: device ?? this.device,
      transportId: transportId ?? this.transportId,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isWireless: isWireless ?? this.isWireless,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdbDevice &&
          runtimeType == other.runtimeType &&
          serial == other.serial &&
          state == other.state;

  @override
  int get hashCode => serial.hashCode ^ state.hashCode;
}
