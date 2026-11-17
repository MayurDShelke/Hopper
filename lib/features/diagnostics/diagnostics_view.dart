import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../core/diagnostics/diagnostics_service.dart';
import '../connect/data/connect_repository.dart';

final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  final adb = ref.watch(adbBackendProvider);
  return DiagnosticsService(adbBackend: adb);
});

class DiagnosticsView extends ConsumerStatefulWidget {
  const DiagnosticsView({super.key});

  @override
  ConsumerState<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends ConsumerState<DiagnosticsView> {
  bool _isLoading = false;
  List<DiagnosticResult> _results = [];

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() => _isLoading = true);
    final service = ref.read(diagnosticsServiceProvider);
    final results = await service.runAllChecks();
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Color _getStatusColor(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.passed:
        return AppTokens.success;
      case DiagnosticStatus.warning:
        return AppTokens.warning;
      case DiagnosticStatus.failed:
        return AppTokens.error;
    }
  }

  IconData _getStatusIcon(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.passed:
        return Icons.check_circle;
      case DiagnosticStatus.warning:
        return Icons.warning_amber;
      case DiagnosticStatus.failed:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(diagnosticsServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.troubleshoot, color: AppTokens.accent, size: 28),
                  const SizedBox(width: AppTokens.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Diagnostics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Automated network, firewall, and ADB server health checks',
                          style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-run'),
                    onPressed: _isLoading ? null : _runChecks,
                  ),
                  const SizedBox(width: AppTokens.space8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text('Export Report'),
                    onPressed: _results.isEmpty
                        ? null
                        : () {
                            final report = service.generateExportReport(_results);
                            Clipboard.setData(ClipboardData(text: report));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Diagnostics report copied to clipboard!'),
                              ),
                            );
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space20),
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.all(AppTokens.space32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space8),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final color = _getStatusColor(item.status);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.space16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_getStatusIcon(item.status), color: color, size: 22),
                            const SizedBox(width: AppTokens.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.space4),
                                  Text(
                                    item.message,
                                    style: const TextStyle(
                                      color: AppTokens.text,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (item.fixPrompt != null) ...[
                                    const SizedBox(height: AppTokens.space4),
                                    Text(
                                      'Fix: ${item.fixPrompt}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
