import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/validators.dart';
import 'adb_backend.dart';
import 'adb_locator.dart';
import 'adb_client.dart';
import 'models/adb_device.dart';

class AdbRunner implements AdbBackend {
  final AdbLocator locator;
  final AdbClient client;

  AdbRunner({
    AdbLocator? locator,
    AdbClient? client,
  })  : locator = locator ?? AdbLocator(),
        client = client ?? AdbClient();

  @override
  Future<String?> getAdbPath() => locator.locateAdb();

  @override
  Future<String> getVersion() async {
    final path = await getAdbPath();
    if (path == null) return 'Not found';

    try {
      final res = await Process.run(path, ['version'], runInShell: false);
      return res.stdout.toString().split('\n').first.trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Future<bool> startServer() async {
    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(path, ['start-server'], runInShell: false);
      return res.exitCode == 0;
    } catch (e) {
      debugPrint('AdbRunner startServer failed: $e');
      return false;
    }
  }

  @override
  Future<bool> killServer() async {
    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(path, ['kill-server'], runInShell: false);
      return res.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<AdbDevice>> trackDevices() {
    return client.trackDevices();
  }

  @override
  Future<List<AdbDevice>> getDevices() async {
    final path = await getAdbPath();
    if (path == null) return [];

    try {
      final res = await Process.run(path, ['devices', '-l'], runInShell: false);
      if (res.exitCode != 0) return [];

      final lines = res.stdout.toString().split('\n');
      final devices = <AdbDevice>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('List of devices attached')) {
          continue;
        }
        devices.add(AdbDevice.fromTrackLine(trimmed));
      }
      return devices;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> pair(String ip, int port, String code) async {
    if (!Validators.isValidIp(ip) || !Validators.isValidPort(port)) {
      throw ArgumentError('Invalid IP or port format');
    }

    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(
        path,
        ['pair', '$ip:$port', code.trim()],
        runInShell: false,
      );
      final output = '${res.stdout} ${res.stderr}';
      return output.contains('Successfully paired') || res.exitCode == 0;
    } catch (e) {
      debugPrint('Pair error: $e');
      return false;
    }
  }

  @override
  Future<bool> connect(String ip, int port) async {
    if (!Validators.isValidIp(ip) || !Validators.isValidPort(port)) {
      throw ArgumentError('Invalid IP or port format');
    }

    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(
        path,
        ['connect', '$ip:$port'],
        runInShell: false,
      );
      final output = '${res.stdout} ${res.stderr}';
      return output.contains('connected to') || res.exitCode == 0;
    } catch (e) {
      debugPrint('Connect error: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnect(String ip, int port) async {
    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(
        path,
        ['disconnect', '$ip:$port'],
        runInShell: false,
      );
      return res.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> runAdbCommand(List<String> args) async {
    final path = await getAdbPath();
    if (path == null) throw StateError('ADB executable not found.');

    final res = await Process.run(path, args, runInShell: false);
    if (res.exitCode != 0) {
      throw Exception('ADB failed (${res.exitCode}): ${res.stderr}');
    }
    return res.stdout.toString();
  }

  @override
  Stream<String> runAdbCommandStream(List<String> args) async* {
    final path = await getAdbPath();
    if (path == null) throw StateError('ADB executable not found.');

    final process = await Process.start(path, args, runInShell: false);
    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}
