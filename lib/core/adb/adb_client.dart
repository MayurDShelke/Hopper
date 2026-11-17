import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'models/adb_device.dart';

class AdbClient {
  final String host;
  final int port;

  AdbClient({
    this.host = '127.0.0.1',
    this.port = 5037,
  });

  /// Sends a formatted ADB command prefix (4 hex-digit length) over socket.
  static String formatRequest(String command) {
    final len = command.length.toRadixString(16).padLeft(4, '0');
    return '$len$command';
  }

  /// Check if adb server is reachable on port 5037.
  Future<bool> isServerRunning() async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Query ADB server version (host:version).
  Future<String?> getServerVersion() async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      final request = formatRequest('host:version');
      socket.add(utf8.encode(request));
      await socket.flush();

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      socket.listen(
        (data) {
          buffer.write(utf8.decode(data));
        },
        onDone: () {
          final response = buffer.toString();
          if (response.startsWith('OKAY') && response.length >= 8) {
            final versionHex = response.substring(8).trim();
            final versionInt = int.tryParse(versionHex, radix: 16);
            completer.complete(versionInt?.toString() ?? versionHex);
          } else {
            completer.complete(null);
          }
        },
        onError: (_) => completer.complete(null),
        cancelOnError: true,
      );

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  /// One-shot: get current device list via `host:devices-l`.
  Future<List<AdbDevice>> getDevicesList() async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      final request = formatRequest('host:devices-l');
      socket.add(utf8.encode(request));
      await socket.flush();

      final completer = Completer<List<AdbDevice>>();
      final buffer = StringBuffer();

      socket.listen(
        (data) {
          buffer.write(utf8.decode(data));
        },
        onDone: () {
          final response = buffer.toString();
          if (response.startsWith('OKAY')) {
            final payload = response.substring(4);
            // Skip the 4-digit hex length prefix if present
            String deviceLines;
            if (payload.length >= 4) {
              final lenStr = payload.substring(0, 4);
              final len = int.tryParse(lenStr, radix: 16);
              if (len != null && payload.length >= 4 + len) {
                deviceLines = payload.substring(4, 4 + len);
              } else {
                deviceLines = payload;
              }
            } else {
              deviceLines = payload;
            }

            final lines = deviceLines
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList();
            final devices =
                lines.map((l) => AdbDevice.fromTrackLine(l)).toList();
            completer.complete(devices);
          } else {
            completer.complete(<AdbDevice>[]);
          }
        },
        onError: (_) => completer.complete(<AdbDevice>[]),
        cancelOnError: true,
      );

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => <AdbDevice>[],
      );
    } catch (e) {
      return <AdbDevice>[];
    } finally {
      socket?.destroy();
    }
  }

  /// Persistent stream: watches device changes via `host:track-devices`.
  /// Re-connects automatically on drop.
  Stream<List<AdbDevice>> trackDevices() {
    late StreamController<List<AdbDevice>> controller;
    bool alive = true;

    Future<void> connect() async {
      while (alive) {
        Socket? socket;
        try {
          socket = await Socket.connect(
            host,
            port,
            timeout: const Duration(seconds: 3),
          );
          final request = formatRequest('host:track-devices');
          socket.add(utf8.encode(request));
          await socket.flush();

          String buffer = '';
          bool okChecked = false;
          final completer = Completer<void>();

          socket.listen(
            (data) {
              buffer += utf8.decode(data);

              // First response must be OKAY
              if (!okChecked) {
                if (buffer.length >= 4) {
                  final status = buffer.substring(0, 4);
                  if (status != 'OKAY') {
                    debugPrint('track-devices rejected: $status');
                    socket?.destroy();
                    return;
                  }
                  okChecked = true;
                  buffer = buffer.substring(4);
                } else {
                  return;
                }
              }

              // Parse length-prefixed device blocks
              while (buffer.length >= 4) {
                final lenHex = buffer.substring(0, 4);
                final length = int.tryParse(lenHex, radix: 16);
                if (length == null) {
                  buffer = '';
                  break;
                }

                if (buffer.length < 4 + length) break; // wait for more data

                final payload = buffer.substring(4, 4 + length);
                buffer = buffer.substring(4 + length);

                final lines = payload
                    .split('\n')
                    .where((l) => l.trim().isNotEmpty)
                    .toList();
                final devices =
                    lines.map((l) => AdbDevice.fromTrackLine(l)).toList();

                if (!controller.isClosed) {
                  controller.add(devices);
                }
              }

              // A zero-length block means no devices
              if (buffer == '0000') {
                buffer = '';
                if (!controller.isClosed) {
                  controller.add(<AdbDevice>[]);
                }
              }
            },
            onError: (e) {
              debugPrint('track-devices stream error: $e');
              if (!completer.isCompleted) completer.complete();
            },
            onDone: () {
              debugPrint('track-devices stream closed by server.');
              if (!completer.isCompleted) completer.complete();
            },
            cancelOnError: true,
          );

          await completer.future;
        } catch (e) {
          debugPrint('track-devices connection failed: $e');
          if (!controller.isClosed) {
            controller.add(<AdbDevice>[]);
          }
        } finally {
          socket?.destroy();
        }

        // Wait before reconnecting
        if (alive) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }

    controller = StreamController<List<AdbDevice>>.broadcast(
      onListen: () => connect(),
      onCancel: () {
        alive = false;
      },
    );

    return controller.stream;
  }
}
