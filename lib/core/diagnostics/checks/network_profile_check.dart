import 'dart:io';
import '../diagnostics_service.dart';

class NetworkProfileCheck implements DiagnosticCheck {
  @override
  String get id => 'network_profile';

  @override
  String get title => 'Windows Network Profile';

  @override
  Future<DiagnosticResult> run({Map<String, dynamic>? params}) async {
    if (!Platform.isWindows) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.passed,
        message: 'Non-Windows system. Profile check skipped.',
      );
    }

    try {
      final res = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '(Get-NetConnectionProfile).NetworkCategory'
        ],
        runInShell: false,
      );

      final output = res.stdout.toString().trim();
      if (output.contains('Private')) {
        return DiagnosticResult(
          id: id,
          title: title,
          status: DiagnosticStatus.passed,
          message: 'Active network profile is Private.',
        );
      } else if (output.contains('Public')) {
        return DiagnosticResult(
          id: id,
          title: title,
          status: DiagnosticStatus.failed,
          message:
              'Active network profile is set to Public. Multicast discovery is blocked.',
          fixPrompt:
              'Change network profile to Private: Windows Settings -> Network & Internet -> Wi-Fi -> Properties -> Private network.',
        );
      } else {
        return DiagnosticResult(
          id: id,
          title: title,
          status: DiagnosticStatus.warning,
          message: 'Could not determine profile type: $output',
        );
      }
    } catch (e) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.warning,
        message: 'Could not query network profile: $e',
      );
    }
  }
}
