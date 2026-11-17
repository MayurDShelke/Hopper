enum DiscoveredServiceType {
  pairing, // _adb-tls-pairing._tcp
  connect, // _adb-tls-connect._tcp
}

class DiscoveredService {
  final DiscoveredServiceType type;
  final String instanceName;
  final String ip;
  final int port;
  final DateTime lastSeen;

  DiscoveredService({
    required this.type,
    required this.instanceName,
    required this.ip,
    required this.port,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  String get serviceAddress => '$ip:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredService &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          instanceName == other.instanceName &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode =>
      type.hashCode ^ instanceName.hashCode ^ ip.hashCode ^ port.hashCode;

  @override
  String toString() =>
      'DiscoveredService(type: $type, instanceName: $instanceName, $ip:$port)';
}
