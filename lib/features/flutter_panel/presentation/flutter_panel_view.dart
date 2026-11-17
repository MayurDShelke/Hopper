import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/router.dart';
import '../flutter_runner.dart';

final flutterRunnerProvider = Provider<FlutterRunner>((ref) {
  final runner = FlutterRunner();
  ref.onDispose(() {
    runner.stop();
  });
  return runner;
});

class FlutterPanelView extends ConsumerStatefulWidget {
  const FlutterPanelView({super.key});

  @override
  ConsumerState<FlutterPanelView> createState() => _FlutterPanelViewState();
}

class _FlutterPanelViewState extends ConsumerState<FlutterPanelView> {
  final TextEditingController _dirController = TextEditingController(text: '.');
  final ScrollController _scrollController = ScrollController();
  final StringBuffer _consoleBuffer = StringBuffer();
  StreamSubscription? _consoleSub;
  String _buildMode = 'debug';

  @override
  void initState() {
    super.initState();
    final runner = ref.read(flutterRunnerProvider);
    _consoleSub = runner.consoleOutput.listen((text) {
      if (!mounted) return;
      setState(() {
        _consoleBuffer.write(text);
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _consoleSub?.cancel();
    _dirController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final serial = nav.selectedDeviceId;
    final runner = ref.watch(flutterRunnerProvider);

    return Padding(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flutter_dash, color: AppTokens.accent),
                      const SizedBox(width: AppTokens.space8),
                      Text(
                        'Flutter Runner (${serial ?? "No device selected"})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _buildMode,
                        items: const [
                          DropdownMenuItem(
                              value: 'debug', child: Text('Debug')),
                          DropdownMenuItem(
                              value: 'profile', child: Text('Profile')),
                          DropdownMenuItem(
                              value: 'release', child: Text('Release')),
                        ],
                        onChanged: (v) =>
                            setState(() => _buildMode = v ?? 'debug'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dirController,
                          decoration: const InputDecoration(
                            labelText: 'Project Directory',
                            hintText: 'C:\\path\\to\\flutter_app',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space12),
                      ElevatedButton.icon(
                        icon: Icon(
                            runner.isRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(runner.isRunning ? 'Stop' : 'Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: runner.isRunning
                              ? AppTokens.error
                              : AppTokens.accent,
                          foregroundColor: runner.isRunning
                              ? Colors.white
                              : AppTokens.background,
                        ),
                        onPressed: serial == null
                            ? null
                            : () {
                                if (runner.isRunning) {
                                  runner.stop();
                                } else {
                                  runner.runProject(
                                    projectDirectory:
                                        _dirController.text.trim(),
                                    serial: serial,
                                    buildMode: _buildMode,
                                  );
                                }
                                setState(() {});
                              },
                      ),
                      const SizedBox(width: AppTokens.space8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Reload (r)'),
                        onPressed:
                            runner.isRunning ? () => runner.hotReload() : null,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Restart (R)'),
                        onPressed:
                            runner.isRunning ? () => runner.hotRestart() : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: AppTokens.border),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _consoleBuffer.isEmpty
                      ? 'Click Run to launch flutter run on the selected wireless device.\nHot Reload (r) and Hot Restart (R) controls will become active.'
                      : _consoleBuffer.toString(),
                  style: const TextStyle(
                    fontFamily: AppTokens.fontMono,
                    fontSize: 12,
                    color: AppTokens.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
