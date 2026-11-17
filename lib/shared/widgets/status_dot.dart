import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../core/connection/connection_state.dart';

class StatusDot extends StatelessWidget {
  final DeviceStatus status;
  final double size;
  final bool showLabel;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 8.0,
    this.showLabel = true,
  });

  Color get color {
    switch (status) {
      case DeviceStatus.connected:
        return AppTokens.success;
      case DeviceStatus.discovered:
        return AppTokens.info;
      case DeviceStatus.connecting:
        return AppTokens.warning;
      case DeviceStatus.unauthorized:
        return AppTokens.warning;
      case DeviceStatus.offline:
        return AppTokens.error;
      case DeviceStatus.unreachable:
        return AppTokens.textMuted;
    }
  }

  String get label {
    switch (status) {
      case DeviceStatus.connected:
        return 'connected';
      case DeviceStatus.discovered:
        return 'found nearby';
      case DeviceStatus.connecting:
        return 'connecting';
      case DeviceStatus.unauthorized:
        return 'needs approval';
      case DeviceStatus.offline:
        return 'offline';
      case DeviceStatus.unreachable:
        return 'not found';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    if (!showLabel) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: AppTokens.space8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
