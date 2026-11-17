import 'checks/adb_check.dart';
import 'checks/network_profile_check.dart';
import 'checks/mdns_check.dart';
import 'checks/reachability_check.dart';
import 'checks/firewall_check.dart';
import '../adb/adb_backend.dart';

enum DiagnosticStatus {
  passed,
  warning,
  failed,
}

class DiagnosticResult {
  final String id;
  final String title;
  final DiagnosticStatus status;
  final String message;
  final String? fixPrompt;

  DiagnosticResult({
    required this.id,
    required this.title,
    required this.status,
    required this.message,
    this.fixPrompt,
  });
}

abstract class DiagnosticCheck {
  String get id;
  String get title;
  Future<DiagnosticResult> run({Map<String, dynamic>? params});
}

class DiagnosticsService {
  final AdbBackend adbBackend;
  late final List<DiagnosticCheck> _checks;

  DiagnosticsService({required this.adbBackend}) {
    _checks = [
      AdbDiagnosticCheck(adbBackend),
      NetworkProfileCheck(),
      MdnsCheck(),
      FirewallCheck(),
      ReachabilityCheck(),
    ];
  }

  Future<List<DiagnosticResult>> runAllChecks(
      {Map<String, dynamic>? params}) async {
    final results = <DiagnosticResult>[];
    for (final check in _checks) {
      final res = await check.run(params: params);
      results.add(res);
    }
    return results;
  }

  String generateExportReport(List<DiagnosticResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== Hopper Diagnostics Report ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');

    for (final r in results) {
      buffer.writeln('[${r.status.name.toUpperCase()}] ${r.title}');
      buffer.writeln('Message: ${r.message}');
      if (r.fixPrompt != null) {
        buffer.writeln('Fix: ${r.fixPrompt}');
      }
      buffer.writeln('----------------------------------------');
    }
    return buffer.toString();
  }
}
