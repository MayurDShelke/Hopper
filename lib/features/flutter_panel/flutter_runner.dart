import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/process/process_manager.dart';

class FlutterRunner {
  final HopperProcessManager processManager;
  Process? _flutterProcess;
  final StreamController<String> _consoleController =
      StreamController<String>.broadcast();

  bool _isRunning = false;

  FlutterRunner({HopperProcessManager? processManager})
      : processManager = processManager ?? HopperProcessManager();

  Stream<String> get consoleOutput => _consoleController.stream;
  bool get isRunning => _isRunning;

  Future<void> runProject({
    required String projectDirectory,
    required String serial,
    String buildMode = 'debug',
  }) async {
    await stop();

    final args = <String>[
      'run',
      '-d',
      serial,
      '--$buildMode',
    ];

    _isRunning = true;
    _consoleController.add('[Hopper] Starting flutter run -d $serial...\n');

    _flutterProcess = await processManager.spawn(
      'flutter',
      args,
      workingDirectory: projectDirectory,
    );

    _flutterProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _consoleController.add('$line\n');
    });

    _flutterProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _consoleController.add('[stderr] $line\n');
    });

    _flutterProcess!.exitCode.then((code) {
      _isRunning = false;
      _consoleController.add('[Hopper] Flutter process exited with code $code.\n');
    });
  }

  void hotReload() {
    if (_flutterProcess != null && _isRunning) {
      _flutterProcess!.stdin.writeln('r');
      _consoleController.add('[Hopper] Triggering Hot Reload (r)...\n');
    }
  }

  void hotRestart() {
    if (_flutterProcess != null && _isRunning) {
      _flutterProcess!.stdin.writeln('R');
      _consoleController.add('[Hopper] Triggering Hot Restart (R)...\n');
    }
  }

  Future<void> stop() async {
    if (_flutterProcess != null) {
      _flutterProcess!.stdin.writeln('q');
      await Future.delayed(const Duration(milliseconds: 300));
      processManager.kill(_flutterProcess!);
      _flutterProcess = null;
      _isRunning = false;
    }
  }
}
