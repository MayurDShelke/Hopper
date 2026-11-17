import 'dart:io';
import '../diagnostics_service.dart';

class ReachabilityCheck implements DiagnosticCheck {
  @override
  String get id => 'reachability';

  @override
  String get title => 'Device TCP Reachability';

  @override
  Future<DiagnosticResult> run({Map<String, dynamic>? params}) async {
    final ip = params?['ip'] as String?;
    final port = params?['port'] as int?;

    if (ip == null || port == null) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.passed,
        message: 'No specific device IP:port specified to test.',
      );
    }

    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();

      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.passed,
        message: 'Device reachable at $ip:$port.',
      );
    } catch (e) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.failed,
        message:
            'Cannot reach $ip:$port ($e). Router Client Isolation may be active.',
        fixPrompt:
            'Ensure phone and PC are on the same Wi-Fi, disable AP/Client Isolation in router settings, or use phone hotspot.',
      );
    }
  }
}
