import 'dart:async';
import 'package:hopper/core/adb/adb_backend.dart';
import 'package:hopper/core/adb/models/adb_device.dart';

class FakeAdbBackend implements AdbBackend {
  String? mockAdbPath = 'C:\\fake\\sdk\\adb.exe';
  String mockVersion = 'Android Debug Bridge version 1.0.41 (35.0.2)';
  bool isServerRunning = true;
  final List<AdbDevice> mockDevices = [];
  final StreamController<List<AdbDevice>> _trackController =
      StreamController<List<AdbDevice>>.broadcast();

  bool pairResult = true;
  bool connectResult = true;
  bool disconnectResult = true;
  final List<String> executedCommands = [];

  @override
  Future<String?> getAdbPath() async => mockAdbPath;

  @override
  Future<String> getVersion() async => mockVersion;

  @override
  Future<bool> startServer() async {
    isServerRunning = true;
    return true;
  }

  @override
  Future<bool> killServer() async {
    isServerRunning = false;
    return true;
  }

  @override
  Stream<List<AdbDevice>> trackDevices() => _trackController.stream;

  void emitDevices(List<AdbDevice> devices) {
    mockDevices.clear();
    mockDevices.addAll(devices);
    _trackController.add(List.unmodifiable(mockDevices));
  }

  @override
  Future<List<AdbDevice>> getDevices() async => List.unmodifiable(mockDevices);

  @override
  Future<bool> pair(String ip, int port, String code) async {
    executedCommands.add('pair $ip:$port $code');
    return pairResult;
  }

  @override
  Future<bool> connect(String ip, int port) async {
    executedCommands.add('connect $ip:$port');
    return connectResult;
  }

  @override
  Future<bool> disconnect(String ip, int port) async {
    executedCommands.add('disconnect $ip:$port');
    return disconnectResult;
  }

  @override
  Future<String> runAdbCommand(List<String> args) async {
    executedCommands.add(args.join(' '));
    return 'Success';
  }

  @override
  Stream<String> runAdbCommandStream(List<String> args) async* {
    executedCommands.add(args.join(' '));
    yield 'Success';
  }
}
