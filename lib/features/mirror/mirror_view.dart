import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../app/router.dart';
import '../../core/process/process_manager.dart';
import '../connect/data/connect_repository.dart';

class MirrorView extends ConsumerStatefulWidget {
  const MirrorView({super.key});

  @override
  ConsumerState<MirrorView> createState() => _MirrorViewState();
}

class _MirrorViewState extends ConsumerState<MirrorView> {
  final HopperProcessManager _processManager = HopperProcessManager();
  Process? _scrcpyProcess;
  bool _isMirroring = false;

  bool _stayAwake = true;
  bool _noAudio = false;
  int _bitrate = 8; // Mbps
  int _maxSize = 1080;

  Future<void> _startMirroring(String serial) async {
    final settings = ref.read(settingsRepoProvider);
    final customAdb = await settings.getCustomAdbPath();

    final args = <String>[
      '--serial',
      serial,
      '--video-bit-rate',
      '${_bitrate}M',
      '--max-size',
      '$_maxSize',
    ];

    if (_stayAwake) args.add('--stay-awake');
    if (_noAudio) args.add('--no-audio');

    try {
      final env = <String, String>{};
      if (customAdb != null) {
        env['ADB'] = customAdb;
      }

      setState(() => _isMirroring = true);

      // Launch scrcpy
      _scrcpyProcess = await _processManager.spawn(
        'scrcpy',
        args,
        environment: env,
      );

      _scrcpyProcess?.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _isMirroring = false;
            _scrcpyProcess = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isMirroring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to launch scrcpy: $e. Ensure scrcpy is installed or bundled.'),
            backgroundColor: AppTokens.error,
          ),
        );
      }
    }
  }

  void _stopMirroring() {
    if (_scrcpyProcess != null) {
      _processManager.kill(_scrcpyProcess!);
      setState(() {
        _isMirroring = false;
        _scrcpyProcess = null;
      });
    }
  }

  @override
  void dispose() {
    _stopMirroring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final serial = nav.selectedDeviceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cast,
                              color: AppTokens.accent, size: 28),
                          const SizedBox(width: AppTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Screen Mirroring (scrcpy)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  serial != null
                                      ? 'Target: $serial'
                                      : 'No target phone selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space20),
                      SwitchListTile(
                        title: const Text('Stay awake while plugged/mirroring'),
                        value: _stayAwake,
                        onChanged: (v) => setState(() => _stayAwake = v),
                      ),
                      SwitchListTile(
                        title: const Text('Mute device audio forwarding'),
                        value: _noAudio,
                        onChanged: (v) => setState(() => _noAudio = v),
                      ),
                      ListTile(
                        title: const Text('Bitrate (Mbps)'),
                        subtitle: Slider(
                          value: _bitrate.toDouble(),
                          min: 2,
                          max: 16,
                          divisions: 7,
                          label: '$_bitrate Mbps',
                          onChanged: (v) =>
                              setState(() => _bitrate = v.toInt()),
                        ),
                        trailing: Text('$_bitrate M'),
                      ),
                      ListTile(
                        title: const Text('Max resolution limit'),
                        trailing: DropdownButton<int>(
                          value: _maxSize,
                          items: const [
                            DropdownMenuItem(value: 720, child: Text('720p')),
                            DropdownMenuItem(value: 1080, child: Text('1080p')),
                            DropdownMenuItem(
                                value: 1440, child: Text('1440p (2K)')),
                          ],
                          onChanged: (v) =>
                              setState(() => _maxSize = v ?? 1080),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space20),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMirroring
                                ? AppTokens.error
                                : AppTokens.accent,
                            foregroundColor: _isMirroring
                                ? Colors.white
                                : AppTokens.background,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                          ),
                          icon: Icon(
                              _isMirroring ? Icons.stop : Icons.play_arrow),
                          label: Text(_isMirroring
                              ? 'Stop Mirroring'
                              : 'Start Mirroring'),
                          onPressed: serial == null
                              ? null
                              : () {
                                  if (_isMirroring) {
                                    _stopMirroring();
                                  } else {
                                    _startMirroring(serial);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
