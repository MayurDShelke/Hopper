import '../diagnostics_service.dart';
import '../../adb/adb_backend.dart';

class AdbDiagnosticCheck implements DiagnosticCheck {
  final AdbBackend adbBackend;

  AdbDiagnosticCheck(this.adbBackend);

  @override
  String get id => 'adb_status';

  @override
  String get title => 'ADB Server & Binary Status';

  @override
  Future<DiagnosticResult> run({Map<String, dynamic>? params}) async {
    final path = await adbBackend.getAdbPath();
    if (path == null) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.failed,
        message: 'No adb executable found in SDK or PATH.',
        fixPrompt:
            'Install Android SDK Platform Tools or configure custom path in Settings.',
      );
    }

    final version = await adbBackend.getVersion();
    final serverOk = await adbBackend.startServer();

    if (!serverOk) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.failed,
        message: 'ADB server failed to start. Port 5037 may be blocked.',
        fixPrompt: 'Run adb kill-server or check for conflicting applications.',
      );
    }

    return DiagnosticResult(
      id: id,
      title: title,
      status: DiagnosticStatus.passed,
      message: 'ADB operational: $version',
    );
  }
}
