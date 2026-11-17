import 'models/discovered_service.dart';

abstract class DiscoveryBackend {
  Stream<List<DiscoveredService>> get servicesStream;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  List<DiscoveredService> get currentServices;
}
