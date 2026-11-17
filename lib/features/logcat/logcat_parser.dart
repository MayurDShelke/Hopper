enum LogcatLevel {
  verbose('V'),
  debug('D'),
  info('I'),
  warning('W'),
  error('E'),
  fatal('F');

  final String code;
  const LogcatLevel(this.code);

  static LogcatLevel fromCode(String code) {
    switch (code) {
      case 'V':
        return LogcatLevel.verbose;
      case 'D':
        return LogcatLevel.debug;
      case 'I':
        return LogcatLevel.info;
      case 'W':
        return LogcatLevel.warning;
      case 'E':
        return LogcatLevel.error;
      case 'F':
        return LogcatLevel.fatal;
      default:
        return LogcatLevel.debug;
    }
  }
}

class LogcatEntry {
  final String raw;
  final String date;
  final String time;
  final String pid;
  final String tid;
  final LogcatLevel level;
  final String tag;
  final String message;

  const LogcatEntry({
    required this.raw,
    required this.date,
    required this.time,
    required this.pid,
    required this.tid,
    required this.level,
    required this.tag,
    required this.message,
  });

  static final RegExp _threadtimeRegex = RegExp(
    r'^(\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2}\.\d+)\s+(\d+)\s+(\d+)\s+([VDIWEF])\s+([^:]*?)\s*:\s*(.*)$',
  );

  static LogcatEntry parse(String line) {
    final match = _threadtimeRegex.firstMatch(line.trim());
    if (match != null) {
      return LogcatEntry(
        raw: line,
        date: match.group(1) ?? '',
        time: match.group(2) ?? '',
        pid: match.group(3) ?? '',
        tid: match.group(4) ?? '',
        level: LogcatLevel.fromCode(match.group(5) ?? 'D'),
        tag: (match.group(6) ?? '').trim(),
        message: match.group(7) ?? '',
      );
    }

    return LogcatEntry(
      raw: line,
      date: '',
      time: '',
      pid: '',
      tid: '',
      level: LogcatLevel.debug,
      tag: 'system',
      message: line,
    );
  }
}
