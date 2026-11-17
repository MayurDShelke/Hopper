import 'dart:io';
import 'package:flutter/foundation.dart';
import 'job_object.dart';

class HopperProcessManager {
  final WindowsJobObject _jobObject = WindowsJobObject();
  final Set<Process> _runningProcesses = {};

  HopperProcessManager() {
    _jobObject.initialize();
  }

  Future<Process> spawn(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
      runInShell: false, // Rule: Never runInShell
    );

    _runningProcesses.add(process);
    _jobObject.assignProcess(process.pid);

    process.exitCode.then((_) {
      _runningProcesses.remove(process);
    });

    return process;
  }

  void kill(Process process) {
    try {
      process.kill(ProcessSignal.sigterm);
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
    }
    _runningProcesses.remove(process);
  }

  void killAll() {
    for (final proc in _runningProcesses) {
      try {
        proc.kill();
      } catch (e) {
        debugPrint('Error terminating process ${proc.pid}: $e');
      }
    }
    _runningProcesses.clear();
    _jobObject.dispose();
  }
}
