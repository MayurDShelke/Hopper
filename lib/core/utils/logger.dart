import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { verbose, debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] [${level.name.toUpperCase()}] [$tag] $message';
  }
}

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  final Queue<LogEntry> _history = Queue<LogEntry>();
  static const int maxHistory = 1000;

  List<LogEntry> get logs => List.unmodifiable(_history);

  void log(LogLevel level, String tag, String message) {
    final entry = LogEntry(level: level, tag: tag, message: message);
    if (_history.length >= maxHistory) {
      _history.removeFirst();
    }
    _history.add(entry);

    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void info(String tag, String message) => log(LogLevel.info, tag, message);
  void warning(String tag, String message) =>
      log(LogLevel.warning, tag, message);
  void error(String tag, String message) => log(LogLevel.error, tag, message);
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);

  void clear() => _history.clear();
}
