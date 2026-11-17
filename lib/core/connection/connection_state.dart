enum DeviceStatus {
  unreachable,
  discovered,
  connecting,
  connected,
  unauthorized,
  offline,
}

class HopperConnectionState {
  final String deviceId;
  final DeviceStatus status;
  final String? ip;
  final int? port;
  final String? errorMessage;
  final int retryCount;

  const HopperConnectionState({
    required this.deviceId,
    this.status = DeviceStatus.unreachable,
    this.ip,
    this.port,
    this.errorMessage,
    this.retryCount = 0,
  });

  HopperConnectionState copyWith({
    String? deviceId,
    DeviceStatus? status,
    String? ip,
    int? port,
    String? errorMessage,
    int? retryCount,
  }) {
    return HopperConnectionState(
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
