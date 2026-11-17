import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/features/logcat/logcat_parser.dart';

void main() {
  group('LogcatParser', () {
    test('parses threadtime format accurately', () {
      const line =
          '07-15 14:28:10.123  1234  5678 D FlutterActivityAndEmbedding: Attached to Activity';
      final entry = LogcatEntry.parse(line);

      expect(entry.date, '07-15');
      expect(entry.time, '14:28:10.123');
      expect(entry.pid, '1234');
      expect(entry.tid, '5678');
      expect(entry.level, LogcatLevel.debug);
      expect(entry.tag, 'FlutterActivityAndEmbedding');
      expect(entry.message, 'Attached to Activity');
    });

    test('handles error level lines', () {
      const line =
          '07-15 14:30:00.001   999  1000 E AndroidRuntime: FATAL EXCEPTION in main';
      final entry = LogcatEntry.parse(line);

      expect(entry.level, LogcatLevel.error);
      expect(entry.tag, 'AndroidRuntime');
      expect(entry.message, 'FATAL EXCEPTION in main');
    });

    test('fallback for arbitrary non-threadtime log lines', () {
      const line = '--------- beginning of main';
      final entry = LogcatEntry.parse(line);

      expect(entry.raw, line);
      expect(entry.level, LogcatLevel.debug);
    });
  });
}
