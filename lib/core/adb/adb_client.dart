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

  /// Sends a formatted ADB command prefix (4-digit hex length) over socket.
  static String formatRequest(String command) {
    final len = command.length.toRadixString(16).padLeft(4, '0');
    return '$len$command';
  }

  /// Query ADB server version (host:version).
  Future<String?> getServerVersion() async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      final request = formatRequest('host:version');
      socket.write(request);
      await socket.flush();

      final responseBytes = await socket.first;
      final responseStr = utf8.decode(responseBytes);

      if (responseStr.startsWith('OKAY') && responseStr.length >= 8) {
        final versionHex = responseStr.substring(4, 8);
        final versionInt = int.tryParse(versionHex, radix: 16);
        return versionInt?.toString() ?? versionHex;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      await socket?.close();
    }
  }

  /// Streams device changes from ADB server via `host:track-devices`.
  Stream<List<AdbDevice>> trackDevices() async* {
    while (true) {
      Socket? socket;
      try {
        socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
        final req = formatRequest('host:track-devices');
        socket.write(req);
        await socket.flush();

        // Check OKAY
        final completer = Completer<void>();
        String buffer = '';
        bool validated = false;

        final controller = StreamController<List<AdbDevice>>();

        final sub = socket.listen(
          (data) {
            buffer += utf8.decode(data);

            if (!validated) {
              if (buffer.length >= 4) {
                final status = buffer.substring(0, 4);
                if (status != 'OKAY') {
                  socket?.destroy();
                  controller.addError(Exception('ADB track-devices returned: $status'));
                  return;
                }
                validated = true;
                buffer = buffer.substring(4);
              }
            }

            if (validated) {
              while (buffer.length >= 4) {
                final lenHex = buffer.substring(0, 4);
                final length = int.tryParse(lenHex, radix: 16);
                if (length == null) {
                  buffer = '';
                  break;
                }

                if (buffer.length >= 4 + length) {
                  final payload = buffer.substring(4, 4 + length);
                  buffer = buffer.substring(4 + length);

                  final lines = payload
                      .split('\n')
                      .where((l) => l.trim().isNotEmpty)
                      .toList();

                  final devices = lines.map((l) => AdbDevice.fromTrackLine(l)).toList();
                  controller.add(devices);
                } else {
                  break;
                }
              }
            }
          },
          onError: (e) {
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
        );

        yield* controller.stream;
        await completer.future;
        await sub.cancel();
      } catch (e) {
        debugPrint('AdbClient track-devices connection error: $e');
        yield <AdbDevice>[];
        // Wait before reconnecting to adb server
        await Future.delayed(const Duration(seconds: 2));
      } finally {
        socket?.destroy();
      }
    }
  }
}
