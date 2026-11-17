import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../connect/data/connect_repository.dart';
import '../logcat_service.dart';

final logcatServiceProvider = Provider<LogcatService>((ref) {
  final adb = ref.watch(adbBackendProvider);
  final service = LogcatService(adbBackend: adb);
  ref.onDispose(() {
    service.stop();
  });
  return service;
});
