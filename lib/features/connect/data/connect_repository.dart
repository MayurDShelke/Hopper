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

final adbBackendProvider = Provider<AdbBackend>((ref) {
  return AdbRunner();
});

final discoveryBackendProvider = Provider<DiscoveryBackend>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final service = DiscoveryService(adbBackend: adb);
  service.startDiscovery();
  ref.onDispose(() {
    service.stopDiscovery();
  });
  return service;
});

final pairingServiceProvider = Provider<PairingService>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final discovery = ref.watch(discoveryBackendProvider);
  return PairingService(adbBackend: adb, discoveryBackend: discovery);
});

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

final savedDevicesRepoProvider = Provider<SavedDevicesRepo>((ref) {
  return SavedDevicesRepo();
});

final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  return SettingsRepo();
});

final savedDevicesListProvider = FutureProvider<List<SavedDevice>>((ref) async {
  final repo = ref.watch(savedDevicesRepoProvider);
  return repo.getSavedDevices();
});

final adbDevicesStreamProvider = StreamProvider<List<AdbDevice>>((ref) {
  final adb = ref.watch(adbBackendProvider);
  return adb.trackDevices();
});

final discoveredServicesStreamProvider =
    StreamProvider<List<DiscoveredService>>((ref) {
  final discovery = ref.watch(discoveryBackendProvider);
  return discovery.servicesStream;
});
