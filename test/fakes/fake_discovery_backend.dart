import 'dart:async';
import 'package:hopper/core/discovery/discovery_backend.dart';
import 'package:hopper/core/discovery/models/discovered_service.dart';

class FakeDiscoveryBackend implements DiscoveryBackend {
  final List<DiscoveredService> _services = [];
  final StreamController<List<DiscoveredService>> _streamController =
      StreamController<List<DiscoveredService>>.broadcast();

  bool isDiscovering = false;

  @override
  List<DiscoveredService> get currentServices => List.unmodifiable(_services);

  @override
  Stream<List<DiscoveredService>> get servicesStream => _streamController.stream;

  @override
  Future<void> startDiscovery() async {
    isDiscovering = true;
  }

  @override
  Future<void> stopDiscovery() async {
    isDiscovering = false;
  }

  void emitService(DiscoveredService service) {
    _services.add(service);
    _streamController.add(List.unmodifiable(_services));
  }

  void clear() {
    _services.clear();
    _streamController.add([]);
  }
}
