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
  bool _serverStarted = false;

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
    if (_serverStarted && await client.isServerRunning()) {
      return true;
    }

    final path = await getAdbPath();
    if (path == null) {
      debugPrint('AdbRunner: Cannot start server - adb not found');
      return false;
    }

    try {
      debugPrint('AdbRunner: Starting adb server...');
      final res = await Process.run(path, ['start-server'], runInShell: false);
      _serverStarted = res.exitCode == 0;
      debugPrint(
          'AdbRunner: start-server exit=${res.exitCode}, stdout=${res.stdout}');
      return _serverStarted;
    } catch (e) {
      debugPrint('AdbRunner: startServer failed: $e');
      return false;
    }
  }

  @override
  Future<bool> killServer() async {
    final path = await getAdbPath();
    if (path == null) return false;

    try {
      final res = await Process.run(path, ['kill-server'], runInShell: false);
      _serverStarted = false;
      return res.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<AdbDevice>> trackDevices() async* {
    await startServer();
    yield* client.trackDevices();
  }

  @override
  Future<List<AdbDevice>> getDevices() async {
    await startServer();
    final socketDevices = await client.getDevicesList();
    if (socketDevices.isNotEmpty) return socketDevices;

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

    await startServer();

    try {
      debugPrint('AdbRunner: pairing $ip:$port ...');
      final res = await Process.run(
        path,
        ['pair', '$ip:$port', code.trim()],
        runInShell: false,
      );
      final output = '${res.stdout} ${res.stderr}'.toLowerCase();
      debugPrint('AdbRunner: pair result: $output');
      return output.contains('successfully paired');
    } catch (e) {
      debugPrint('AdbRunner: pair error: $e');
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

    await startServer();

    try {
      debugPrint('AdbRunner: connecting to $ip:$port ...');
      final res = await Process.run(
        path,
        ['connect', '$ip:$port'],
        runInShell: false,
      );
      final output = '${res.stdout} ${res.stderr}'.toLowerCase();
      debugPrint('AdbRunner: connect result: $output');
      final isSuccess = (output.contains('connected to') ||
              output.contains('already connected to')) &&
          !output.contains('cannot connect') &&
          !output.contains('failed to connect') &&
          !output.contains('unable to connect');
      return isSuccess;
    } catch (e) {
      debugPrint('AdbRunner: connect error: $e');
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

    await startServer();

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

    await startServer();

    final process = await Process.start(path, args, runInShell: false);
    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}
