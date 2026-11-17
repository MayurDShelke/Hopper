import 'dart:async';
import '../adb/adb_backend.dart';
import '../discovery/discovery_backend.dart';
import '../discovery/models/discovered_service.dart';
import 'qr_payload.dart';

enum PairingStepState {
  ready,
  waitingForDevice,
  pairing,
  connecting,
  success,
  failed,
}

class PairingService {
  final AdbBackend adbBackend;
  final DiscoveryBackend discoveryBackend;

  PairingService({
    required this.adbBackend,
    required this.discoveryBackend,
  });

  /// Starts QR pairing flow, yielding state updates.
  Stream<PairingStepState> pairWithQr(QrPayload payload) async* {
    yield PairingStepState.waitingForDevice;

    await discoveryBackend.startDiscovery();

    DiscoveredService? pairingService;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < const Duration(seconds: 45)) {
      final services = discoveryBackend.currentServices;
      // 1. Look for matching service name first
      for (final s in services) {
        if (s.type == DiscoveredServiceType.pairing &&
            (s.instanceName.contains(payload.serviceName) ||
                payload.serviceName.contains(s.instanceName))) {
          pairingService = s;
          break;
        }
      }

      // 2. If no name match yet after 4 seconds, accept any discovered pairing service
      if (pairingService == null && stopwatch.elapsed.inSeconds > 4) {
        for (final s in services) {
          if (s.type == DiscoveredServiceType.pairing) {
            pairingService = s;
            break;
          }
        }
      }

      if (pairingService != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (pairingService == null) {
      yield PairingStepState.failed;
      return;
    }

    yield PairingStepState.pairing;
    final pairOk = await adbBackend.pair(
      pairingService.ip,
      pairingService.port,
      payload.password,
    );

    if (!pairOk) {
      yield PairingStepState.failed;
      return;
    }

    yield PairingStepState.connecting;
    // Await connect service on the same IP
    DiscoveredService? connectService;
    stopwatch.reset();

    while (stopwatch.elapsed < const Duration(seconds: 15)) {
      final services = discoveryBackend.currentServices;
      for (final s in services) {
        if (s.type == DiscoveredServiceType.connect &&
            s.ip == pairingService.ip) {
          connectService = s;
          break;
        }
      }
      if (connectService != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (connectService != null) {
      final connectOk = await adbBackend.connect(
        connectService.ip,
        connectService.port,
      );
      yield connectOk ? PairingStepState.success : PairingStepState.failed;
    } else {
      // Connect service wasn't auto-detected within 15s, but pairing succeeded
      yield PairingStepState.success;
    }
  }

  /// Pairs using a 6-digit code entered by user.
  Future<bool> pairWithCode(String ip, int port, String code) async {
    return await adbBackend.pair(ip, port, code);
  }
}
