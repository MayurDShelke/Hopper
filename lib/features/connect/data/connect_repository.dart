import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/adb/adb_backend.dart';
import '../../../core/adb/adb_runner.dart';
import '../../../core/adb/models/adb_device.dart';
import '../../../core/discovery/discovery_backend.dart';
import '../../../core/discovery/discovery_service.dart';
import '../../../core/discovery/models/discovered_service.dart';
import '../../../core/pairing/pairing_service.dart';
import '../../../core/connection/connection_manager.dart';
import '../../../core/storage/saved_devices_repo.dart';
import '../../../core/storage/settings_repo.dart';
import '../domain/saved_device.dart';

// ── ADB singleton ──────────────────────────────────────────────
final adbBackendProvider = Provider<AdbBackend>((ref) {
  return AdbRunner();
});

// ── ADB status (path + version + server health) ────────────────
class AdbStatus {
  final String? path;
  final String version;
  final bool serverRunning;
  const AdbStatus({this.path, this.version = '', this.serverRunning = false});
}

final adbStatusProvider = FutureProvider<AdbStatus>((ref) async {
  final adb = ref.watch(adbBackendProvider);
  final path = await adb.getAdbPath();
  if (path == null) {
    return const AdbStatus(version: 'Not found');
  }
  final started = await adb.startServer();
  final ver = await adb.getVersion();
  return AdbStatus(path: path, version: ver, serverRunning: started);
});

// ── Discovery ──────────────────────────────────────────────────
final discoveryBackendProvider = Provider<DiscoveryBackend>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final service = DiscoveryService(adbBackend: adb);
  service.startDiscovery();
  ref.onDispose(() {
    service.stopDiscovery();
  });
  return service;
});

final discoveredServicesStreamProvider =
    StreamProvider<List<DiscoveredService>>((ref) {
  final discovery = ref.watch(discoveryBackendProvider);
  return discovery.servicesStream;
});

// ── Pairing ────────────────────────────────────────────────────
final pairingServiceProvider = Provider<PairingService>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final discovery = ref.watch(discoveryBackendProvider);
  return PairingService(adbBackend: adb, discoveryBackend: discovery);
});

// ── Connection Manager ─────────────────────────────────────────
final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final discovery = ref.watch(discoveryBackendProvider);
  final manager = ConnectionManager(
    adbBackend: adb,
    discoveryBackend: discovery,
  );
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

// ── Saved devices (persistent) ─────────────────────────────────
final savedDevicesRepoProvider = Provider<SavedDevicesRepo>((ref) {
  return SavedDevicesRepo();
});

final savedDevicesListProvider = FutureProvider<List<SavedDevice>>((ref) async {
  final repo = ref.watch(savedDevicesRepoProvider);
  return repo.getSavedDevices();
});

// ── Settings ───────────────────────────────────────────────────
final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  return SettingsRepo();
});

// ── Live device list (track-devices stream + polling fallback) ─
final adbDevicesStreamProvider = StreamProvider<List<AdbDevice>>((ref) {
  final adb = ref.watch(adbBackendProvider);

  // We merge the socket-based track-devices stream with a periodic poll
  // so we always show something even if the socket breaks.
  final controller = StreamController<List<AdbDevice>>.broadcast();

  // Start the persistent track-devices connection
  final trackSub = adb.trackDevices().listen(
    (devices) {
      if (!controller.isClosed) controller.add(devices);
    },
    onError: (e) {
      // Track stream failed, poll will cover us
    },
  );

  // Also poll every 5s as a safety net
  Timer? pollTimer;
  pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (controller.isClosed) {
      pollTimer?.cancel();
      return;
    }
    try {
      final devices = await adb.getDevices();
      if (!controller.isClosed) controller.add(devices);
    } catch (_) {}
  });

  // Kick off an immediate poll
  Future.microtask(() async {
    try {
      final devices = await adb.getDevices();
      if (!controller.isClosed) controller.add(devices);
    } catch (_) {}
  });

  ref.onDispose(() {
    trackSub.cancel();
    pollTimer?.cancel();
    controller.close();
  });

  return controller.stream;
});
