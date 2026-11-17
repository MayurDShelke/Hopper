import 'dart:async';
import 'models/adb_device.dart';

abstract class AdbBackend {
  Future<String?> getAdbPath();
  Future<String> getVersion();
  Future<bool> startServer();
  Future<bool> killServer();

  Stream<List<AdbDevice>> trackDevices();
  Future<List<AdbDevice>> getDevices();

  Future<bool> pair(String ip, int port, String code);
  Future<bool> connect(String ip, int port);
  Future<bool> disconnect(String ip, int port);

  Future<String> runAdbCommand(List<String> args);
  Stream<String> runAdbCommandStream(List<String> args);
}
