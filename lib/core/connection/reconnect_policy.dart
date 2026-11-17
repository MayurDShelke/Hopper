import 'dart:math';

class ReconnectPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;

  const ReconnectPolicy({
    this.maxRetries = 10,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    if (attempt > 4) return maxDelay;

    // 1s, 2s, 4s, 8s
    final seconds = min(pow(2, attempt - 1).toInt(), 30);
    return Duration(seconds: seconds);
  }

  bool canRetry(int currentAttempt) {
    return currentAttempt < maxRetries;
  }
}
