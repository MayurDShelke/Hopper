import 'dart:async';
import 'package:flutter/foundation.dart';
import '../adb/adb_backend.dart';
import '../discovery/discovery_backend.dart';
import '../discovery/models/discovered_service.dart';
import 'connection_state.dart';
import 'reconnect_policy.dart';

class ConnectionManager {
  final AdbBackend adbBackend;
  final DiscoveryBackend discoveryBackend;
  final ReconnectPolicy reconnectPolicy;

  final Map<String, HopperConnectionState> _states = {};
  final StreamController<Map<String, HopperConnectionState>> _controller =
      StreamController<Map<String, HopperConnectionState>>.broadcast();

  final Map<String, Timer?> _reconnectTimers = {};

  ConnectionManager({
    required this.adbBackend,
    required this.discoveryBackend,
    this.reconnectPolicy = const ReconnectPolicy(),
  });

  Stream<Map<String, HopperConnectionState>> get statesStream =>
      _controller.stream;

  HopperConnectionState getState(String deviceId) {
    return _states[deviceId] ?? HopperConnectionState(deviceId: deviceId);
  }

  void updateState(HopperConnectionState newState) {
    _states[newState.deviceId] = newState;
    _controller.add(Map.unmodifiable(_states));
  }

  Future<bool> connectDevice(
    String deviceId,
    String ip,
    int port, {
    bool isAutoReconnect = false,
  }) async {
    var state = getState(deviceId).copyWith(
      status: DeviceStatus.connecting,
      ip: ip,
      port: port,
      errorMessage: null,
    );
    updateState(state);

    try {
      final success = await adbBackend.connect(ip, port);
      if (success) {
        state = state.copyWith(
          status: DeviceStatus.connected,
          retryCount: 0,
        );
        updateState(state);
        _reconnectTimers[deviceId]?.cancel();
        return true;
      } else {
        _handleConnectFailure(deviceId, ip, port, isAutoReconnect);
        return false;
      }
    } catch (e) {
      debugPrint('ConnectionManager connect error: $e');
      _handleConnectFailure(deviceId, ip, port, isAutoReconnect, e.toString());
      return false;
    }
  }

  void _handleConnectFailure(
    String deviceId,
    String ip,
    int port,
    bool isAutoReconnect, [
    String? error,
  ]) {
    final current = getState(deviceId);
    final nextAttempt = current.retryCount + 1;

    final newState = current.copyWith(
      status: DeviceStatus.offline,
      errorMessage: error ?? 'Failed to connect to $ip:$port',
      retryCount: nextAttempt,
    );
    updateState(newState);

    if (isAutoReconnect && reconnectPolicy.canRetry(nextAttempt)) {
      final delay = reconnectPolicy.getDelayForAttempt(nextAttempt);
      _reconnectTimers[deviceId]?.cancel();
      _reconnectTimers[deviceId] = Timer(delay, () {
        connectDevice(deviceId, ip, port, isAutoReconnect: true);
      });
    }
  }

  Future<bool> disconnectDevice(String deviceId, String ip, int port) async {
    _reconnectTimers[deviceId]?.cancel();
    final ok = await adbBackend.disconnect(ip, port);
    updateState(
      getState(deviceId).copyWith(
        status: DeviceStatus.offline,
        retryCount: 0,
      ),
    );
    return ok;
  }

  void onMdnsServiceDiscovered(DiscoveredService service) {
    if (service.type == DiscoveredServiceType.connect) {
      final current = getState(service.instanceName);
      if (current.status != DeviceStatus.connected &&
          current.status != DeviceStatus.connecting) {
        updateState(
          current.copyWith(
            status: DeviceStatus.discovered,
            ip: service.ip,
            port: service.port,
          ),
        );
      }
    }
  }

  void dispose() {
    for (final timer in _reconnectTimers.values) {
      timer?.cancel();
    }
    _reconnectTimers.clear();
  }
}
