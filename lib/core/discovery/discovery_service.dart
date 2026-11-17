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
  Timer? _adbMdnsTimer;
  Timer? _mdnsTimer;
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

    // 1. Immediately and periodically poll `adb mdns services` (primary & robust)
    _startAdbMdnsPolling();

    // 2. Also start multicast_dns client in parallel
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();
      _mdnsTimer =
          Timer.periodic(const Duration(seconds: 4), (_) => _scanMdns());
      _scanMdns();
    } catch (e) {
      debugPrint('mDNS client could not start: $e (adb mdns active)');
    }
  }

  void _startAdbMdnsPolling() {
    _adbMdnsTimer?.cancel();
    // Immediate first check
    _queryAdbMdns();
    // Recurring poll every 2 seconds
    _adbMdnsTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _queryAdbMdns());
  }

  Future<void> _queryAdbMdns() async {
    if (adbBackend == null) return;
    try {
      final out = await adbBackend!.runAdbCommand(['mdns', 'services']);
      final parsed = AdbMdnsFallback.parseServices(out);
      bool changed = false;
      for (final s in parsed) {
        final key = '${s.type.name}_${s.ip}_${s.port}';
        if (!_discovered.containsKey(key)) {
          _discovered[key] = s;
          changed = true;
        }
      }
      if (changed && !_controller.isClosed) {
        _controller.add(_discovered.values.toList());
      }
    } catch (_) {}
  }

  Future<void> _scanMdns() async {
    if (_mdnsClient == null) return;

    const pairingType = '_adb-tls-pairing._tcp.local';
    const connectType = '_adb-tls-connect._tcp.local';

    for (final serviceType in [pairingType, connectType]) {
      try {
        await for (final PtrResourceRecord ptr in _mdnsClient!
            .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(serviceType),
            )
            .timeout(const Duration(seconds: 2),
                onTimeout: (sink) => sink.close())) {
          await for (final SrvResourceRecord srv in _mdnsClient!
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
              )
              .timeout(const Duration(seconds: 2),
                  onTimeout: (sink) => sink.close())) {
            await for (final IPAddressResourceRecord ip in _mdnsClient!
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target),
                )
                .timeout(const Duration(seconds: 2),
                    onTimeout: (sink) => sink.close())) {
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

              final key =
                  '${discovered.type.name}_${discovered.ip}_${discovered.port}';
              if (!_discovered.containsKey(key)) {
                _discovered[key] = discovered;
                if (!_controller.isClosed) {
                  _controller.add(_discovered.values.toList());
                }
              }
            }
          }
        }
      } catch (e) {
        // Ignored, fallback handles discovery
      }
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _adbMdnsTimer?.cancel();
    _adbMdnsTimer = null;
    _mdnsTimer?.cancel();
    _mdnsTimer = null;
    _mdnsClient?.stop();
    _mdnsClient = null;
  }
}
