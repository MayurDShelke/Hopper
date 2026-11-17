import 'dart:io';
import '../diagnostics_service.dart';

class FirewallCheck implements DiagnosticCheck {
  @override
  String get id => 'firewall_status';

  @override
  String get title => 'Windows Firewall Permissions';

  @override
  Future<DiagnosticResult> run({Map<String, dynamic>? params}) async {
    if (!Platform.isWindows) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.passed,
        message: 'Non-Windows system. Firewall check skipped.',
      );
    }

    try {
      final res = await Process.run(
        'netsh',
        ['advfirewall', 'firewall', 'show', 'rule', 'name=all'],
        runInShell: false,
      );

      final out = res.stdout.toString().toLowerCase();
      final hasAdbOrHopper = out.contains('adb') || out.contains('hopper');

      if (hasAdbOrHopper) {
        return DiagnosticResult(
          id: id,
          title: title,
          status: DiagnosticStatus.passed,
          message: 'Firewall rules present for developer tooling.',
        );
      } else {
        return DiagnosticResult(
          id: id,
          title: title,
          status: DiagnosticStatus.warning,
          message: 'No explicit firewall exception found for ADB/Hopper.',
          fixPrompt: 'When prompted by Windows Defender Firewall, allow Hopper on Private networks.',
        );
      }
    } catch (e) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.warning,
        message: 'Could not query Windows Firewall: $e',
      );
    }
  }
}
