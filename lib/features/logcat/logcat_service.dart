import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/adb/adb_backend.dart';
import '../../core/utils/ring_buffer.dart';
import 'logcat_parser.dart';

class LogcatService {
  final AdbBackend adbBackend;
  final RingBuffer<LogcatEntry> buffer = RingBuffer<LogcatEntry>(100000);
  final StreamController<List<LogcatEntry>> _streamController =
      StreamController<List<LogcatEntry>>.broadcast();

  Process? _process;
  Timer? _batchTimer;
  final List<LogcatEntry> _pendingBatch = [];
  bool _isPaused = false;

  LogcatService({required this.adbBackend});

  Stream<List<LogcatEntry>> get logStream => _streamController.stream;
  List<LogcatEntry> get currentLogs => buffer.toList();

  bool get isPaused => _isPaused;
  void togglePause() => _isPaused = !_isPaused;

  Future<void> start(String serial) async {
    await stop();

    final path = await adbBackend.getAdbPath();
    if (path == null) throw StateError('ADB path not found');

    _process = await Process.start(
      path,
      ['-s', serial, 'logcat', '-v', 'threadtime'],
      runInShell: false,
    );

    _batchTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (_pendingBatch.isNotEmpty) {
        final toSend = List<LogcatEntry>.from(_pendingBatch);
        _pendingBatch.clear();
        _streamController.add(toSend);
      }
    });

    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (_isPaused || line.trim().isEmpty) return;

      final entry = LogcatEntry.parse(line);
      buffer.add(entry);
      _pendingBatch.add(entry);
    });
  }

  void clear() {
    buffer.clear();
    _pendingBatch.clear();
    _streamController.add([]);
  }

  Future<void> stop() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    _process?.kill();
    _process = null;
  }
}
