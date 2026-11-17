import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import '../adb/adb_backend.dart';
import 'adb_mdns_fallback.dart';
import 'discovery_backend.dart';
import 'models/discovered_service.dart';

class DiscoveryService implements DiscoveryBackend {
  final AdbBackend? adbBackend;
  final StreamController<List<DiscoveredService>> _controller =
      StreamController<List<DiscoveredService>>.broadcast();

  MDnsClient? _mdnsClient;
  Timer? _pollTimer;
  bool _isDiscovering = false;
  final Map<String, DiscoveredService> _discovered = {};

  DiscoveryService({this.adbBackend});

  @override
  Stream<List<DiscoveredService>> get servicesStream => _controller.stream;

  @override
  List<DiscoveredService> get currentServices => _discovered.values.toList();

  @override
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _isDiscovering = true;

    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _scanMdns());
      _scanMdns();
    } catch (e) {
      debugPrint('mDNS client failed to start, falling back to adb mdns: $e');
      _startAdbMdnsFallback();
    }
  }

  void _startAdbMdnsFallback() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (adbBackend == null) return;
      try {
        final out = await adbBackend!.runAdbCommand(['mdns', 'services']);
        final parsed = AdbMdnsFallback.parseServices(out);
        for (final s in parsed) {
          _discovered['${s.type}_${s.instanceName}'] = s;
        }
        _controller.add(_discovered.values.toList());
      } catch (_) {}
    });
  }

  Future<void> _scanMdns() async {
    if (_mdnsClient == null) return;

    const pairingType = '_adb-tls-pairing._tcp.local';
    const connectType = '_adb-tls-connect._tcp.local';

    for (final serviceType in [pairingType, connectType]) {
      try {
        await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
          ResourceRecordQuery.ptr(serviceType),
        )) {
          await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
            ResourceRecordQuery.srv(ptr.domainName),
          )) {
            await for (final IPAddressResourceRecord ip in _mdnsClient!.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target),
            )) {
              final isPairing = serviceType.contains('pairing');
              final instanceName = ptr.domainName.split('.').first;

              final discovered = DiscoveredService(
                type: isPairing
                    ? DiscoveredServiceType.pairing
                    : DiscoveredServiceType.connect,
                instanceName: instanceName,
                ip: ip.address.address,
                port: srv.port,
              );

              _discovered['${discovered.type}_$instanceName'] = discovered;
              _controller.add(_discovered.values.toList());
            }
          }
        }
      } catch (e) {
        debugPrint('mDNS query error: $e');
      }
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _mdnsClient?.stop();
    _mdnsClient = null;
  }
}
