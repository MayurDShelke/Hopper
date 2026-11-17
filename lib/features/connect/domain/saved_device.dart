import 'dart:convert';

class SavedDevice {
  final String instanceName;
  final String label;
  final String lastIp;
  final int lastPort;
  final bool autoReconnect;
  final DateTime? lastConnected;

  const SavedDevice({
    required this.instanceName,
    required this.label,
    required this.lastIp,
    required this.lastPort,
    this.autoReconnect = true,
    this.lastConnected,
  });

  SavedDevice copyWith({
    String? instanceName,
    String? label,
    String? lastIp,
    int? lastPort,
    bool? autoReconnect,
    DateTime? lastConnected,
  }) {
    return SavedDevice(
      instanceName: instanceName ?? this.instanceName,
      label: label ?? this.label,
      lastIp: lastIp ?? this.lastIp,
      lastPort: lastPort ?? this.lastPort,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instanceName': instanceName,
      'label': label,
      'lastIp': lastIp,
      'lastPort': lastPort,
      'autoReconnect': autoReconnect,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  factory SavedDevice.fromMap(Map<String, dynamic> map) {
    return SavedDevice(
      instanceName: map['instanceName'] as String? ?? '',
      label: map['label'] as String? ?? '',
      lastIp: map['lastIp'] as String? ?? '',
      lastPort: map['lastPort'] as int? ?? 5555,
      autoReconnect: map['autoReconnect'] as bool? ?? true,
      lastConnected: map['lastConnected'] != null
          ? DateTime.tryParse(map['lastConnected'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedDevice.fromJson(String source) =>
      SavedDevice.fromMap(json.decode(source) as Map<String, dynamic>);
}
