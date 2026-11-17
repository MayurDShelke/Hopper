import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/pairing/qr_payload.dart';
import '../../../core/pairing/pairing_service.dart';
import '../data/connect_repository.dart';
import '../domain/saved_device.dart';
import 'qr_step.dart';
import 'code_step.dart';
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

  bool _isPairing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _qrPayload = QrPayload.generate();
    _startQrPairingListener();
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
            break;
          case PairingStepState.pairing:
            _isPairing = true;
            _statusMessage = 'Phone detected! Exchanging keys...';
            break;
          case PairingStepState.connecting:
            _isPairing = true;
            _statusMessage = 'Connecting wireless ADB...';
            break;
          case PairingStepState.success:
            _isPairing = false;
            _statusMessage = 'Paired & Connected successfully!';
            _showSaveDeviceDialog();
            break;
          case PairingStepState.failed:
            _isPairing = false;
            _statusMessage = 'Pairing timed out or failed. Please retry.';
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
    });

    final pairingService = ref.read(pairingServiceProvider);
    final ok = await pairingService.pairWithCode(ip, port, code);

    if (!mounted) return;
    setState(() {
      _isPairing = false;
    });

    if (ok) {
      _showSaveDeviceDialog(ip: ip, port: port);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pairing failed. Check code and port.')),
      );
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
          title: const Text('Device Paired! Save Phone?'),
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
                    instanceName: _qrPayload.serviceName,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          Tab(text: 'Pair with QR Code'),
                          Tab(text: 'Pair with Code'),
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
                          ],
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: AppTokens.space12),
                        Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: AppTokens.accent,
                            fontSize: 13,
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
