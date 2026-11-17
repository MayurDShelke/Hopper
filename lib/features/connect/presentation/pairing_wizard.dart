import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/discovery/models/discovered_service.dart';
import '../../../core/pairing/qr_payload.dart';
import '../../../core/pairing/pairing_service.dart';
import '../data/connect_repository.dart';
import '../domain/saved_device.dart';
import 'qr_step.dart';
import 'code_step.dart';
import 'direct_connect_step.dart';
import 'saved_devices_list.dart';

class PairingWizard extends ConsumerStatefulWidget {
  const PairingWizard({super.key});

  @override
  ConsumerState<PairingWizard> createState() => _PairingWizardState();
}

class _PairingWizardState extends ConsumerState<PairingWizard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late QrPayload _qrPayload;
  StreamSubscription? _pairingSub;

  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _codeController = TextEditingController();

  final _directIpController = TextEditingController();
  final _directPortController = TextEditingController(text: '5555');

  bool _isPairing = false;
  bool _isDirectConnecting = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _qrPayload = QrPayload.generate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQrPairingListener();
    });
  }

  void _startQrPairingListener() {
    final pairingService = ref.read(pairingServiceProvider);
    _pairingSub?.cancel();
    _pairingSub = pairingService.pairWithQr(_qrPayload).listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case PairingStepState.waitingForDevice:
            _isPairing = false;
            _statusMessage = 'Waiting for phone scan...';
            _isError = false;
            break;
          case PairingStepState.pairing:
            _isPairing = true;
            _statusMessage = 'Phone detected! Exchanging keys...';
            _isError = false;
            break;
          case PairingStepState.connecting:
            _isPairing = true;
            _statusMessage = 'Connecting wireless ADB...';
            _isError = false;
            break;
          case PairingStepState.success:
            _isPairing = false;
            _statusMessage = 'Paired & Connected successfully!';
            _isError = false;
            _showSaveDeviceDialog();
            break;
          case PairingStepState.failed:
            _isPairing = false;
            _statusMessage =
                'Pairing timed out or failed. Please ensure same Wi-Fi and retry.';
            _isError = true;
            break;
          default:
            break;
        }
      });
    });
  }

  Future<void> _pairWithCode() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    final code = _codeController.text.trim();

    if (ip.isEmpty || port <= 0 || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid IP, port, and 6-digit code')),
      );
      return;
    }

    setState(() {
      _isPairing = true;
      _statusMessage = 'Pairing with code...';
      _isError = false;
    });

    final pairingService = ref.read(pairingServiceProvider);
    final ok = await pairingService.pairWithCode(ip, port, code);

    if (!mounted) return;
    setState(() {
      _isPairing = false;
    });

    if (ok) {
      setState(() {
        _statusMessage = 'Paired successfully! Connecting...';
      });

      // Try automatic connection to discovered connect port, or prompt
      final discovery = ref.read(discoveryBackendProvider);
      final connectService =
          discovery.currentServices.cast<DiscoveredService?>().firstWhere(
                (s) => s?.type == DiscoveredServiceType.connect && s?.ip == ip,
                orElse: () => null,
              );

      if (connectService != null) {
        final adb = ref.read(adbBackendProvider);
        await adb.connect(connectService.ip, connectService.port);
        _showSaveDeviceDialog(ip: connectService.ip, port: connectService.port);
      } else {
        _showSaveDeviceDialog(ip: ip, port: port);
      }
    } else {
      setState(() {
        _statusMessage =
            'Pairing failed. Make sure the pairing dialog is open on your phone and the code matches.';
        _isError = true;
      });
    }
  }

  Future<void> _directConnect() async {
    final ip = _directIpController.text.trim();
    final port = int.tryParse(_directPortController.text.trim()) ?? 0;

    if (ip.isEmpty || port <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP and port')),
      );
      return;
    }

    setState(() {
      _isDirectConnecting = true;
      _statusMessage = 'Connecting to $ip:$port ...';
      _isError = false;
    });

    final adb = ref.read(adbBackendProvider);
    final ok = await adb.connect(ip, port);

    if (!mounted) return;
    setState(() {
      _isDirectConnecting = false;
    });

    if (ok) {
      setState(() {
        _statusMessage = 'Connected successfully to $ip:$port!';
        _isError = false;
      });
      _showSaveDeviceDialog(ip: ip, port: port);
    } else {
      setState(() {
        _statusMessage =
            'Connection refused or timed out. Ensure Wireless debugging is turned ON in Developer options and check the port.';
        _isError = true;
      });
    }
  }

  void _showSaveDeviceDialog({String? ip, int? port}) {
    final nameController = TextEditingController(text: 'My Android Phone');
    bool autoReconnect = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Device Connected! Save Phone?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
              ),
              const SizedBox(height: AppTokens.space12),
              SwitchListTile(
                title: const Text('Auto-reconnect on discovery'),
                value: autoReconnect,
                onChanged: (val) => setDlgState(() => autoReconnect = val),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(savedDevicesRepoProvider);
                await repo.saveDevice(
                  SavedDevice(
                    instanceName:
                        ip != null ? '$ip:$port' : _qrPayload.serviceName,
                    label: nameController.text.trim(),
                    lastIp: ip ?? '192.168.1.xxx',
                    lastPort: port ?? 5555,
                    autoReconnect: autoReconnect,
                    lastConnected: DateTime.now(),
                  ),
                );
                ref.invalidate(savedDevicesListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save & Finish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pairingSub?.cancel();
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    _directIpController.dispose();
    _directPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveredServicesAsync = ref.watch(discoveredServicesStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nearby Discovered Phones (1-Click connect)
              discoveredServicesAsync.when(
                data: (services) {
                  final connectServices = services
                      .where((s) => s.type == DiscoveredServiceType.connect)
                      .toList();

                  if (connectServices.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space16),
                    child: Card(
                      color: AppTokens.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi_tethering,
                                    color: AppTokens.accent, size: 20),
                                SizedBox(width: AppTokens.space8),
                                Text(
                                  'Nearby Phones Found (Wireless Debugging Active)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.space8),
                            ...connectServices.map((svc) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.smartphone, size: 18),
                                    const SizedBox(width: AppTokens.space8),
                                    Expanded(
                                      child: Text(
                                        '${svc.instanceName} • ${svc.serviceAddress}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        textStyle:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () async {
                                        final adb =
                                            ref.read(adbBackendProvider);
                                        final ok =
                                            await adb.connect(svc.ip, svc.port);
                                        if (ok) {
                                          _showSaveDeviceDialog(
                                              ip: svc.ip, port: svc.port);
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to connect to ${svc.serviceAddress}'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('1-Click Connect'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Connection Modes Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppTokens.accent,
                        labelColor: AppTokens.accent,
                        unselectedLabelColor: AppTokens.textMuted,
                        tabs: const [
                          Tab(text: 'Scan QR Code'),
                          Tab(text: 'Pair with Code'),
                          Tab(text: 'IP & Port (Direct)'),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space20),
                      SizedBox(
                        height: 330,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            QrStepWidget(
                              payload: _qrPayload,
                              isPairing: _isPairing,
                            ),
                            CodeStepWidget(
                              ipController: _ipController,
                              portController: _portController,
                              codeController: _codeController,
                              onPair: _pairWithCode,
                              isPairing: _isPairing,
                            ),
                            DirectConnectStepWidget(
                              ipController: _directIpController,
                              portController: _directPortController,
                              onConnect: _directConnect,
                              isConnecting: _isDirectConnecting,
                            ),
                          ],
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: AppTokens.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isError
                                ? AppTokens.error.withValues(alpha: 0.1)
                                : AppTokens.accent.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusSm),
                            border: Border.all(
                              color:
                                  _isError ? AppTokens.error : AppTokens.accent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color:
                                  _isError ? AppTokens.error : AppTokens.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space24),
              const Text(
                'Saved Devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              SavedDevicesListWidget(
                onConnect: (device) {
                  final manager = ref.read(connectionManagerProvider);
                  manager.connectDevice(
                    device.instanceName,
                    device.lastIp,
                    device.lastPort,
                    isAutoReconnect: device.autoReconnect,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
