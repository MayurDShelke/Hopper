import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AdbLocator {
  String? _cachedPath;

  Future<String?> locateAdb({String? customPath}) async {
    if (customPath != null && customPath.isNotEmpty) {
      final file = File(customPath);
      if (await file.exists()) {
        _cachedPath = file.path;
        return _cachedPath;
      }
    }

    if (_cachedPath != null && await File(_cachedPath!).exists()) {
      return _cachedPath;
    }

    // 1. Search ANDROID_HOME and ANDROID_SDK_ROOT environment variables
    final envVars = ['ANDROID_HOME', 'ANDROID_SDK_ROOT'];
    for (final env in envVars) {
      final val = Platform.environment[env];
      if (val != null && val.isNotEmpty) {
        final candidate = p.join(val, 'platform-tools', _adbExecutableName);
        if (await File(candidate).exists()) {
          _cachedPath = candidate;
          return _cachedPath;
        }
      }
    }

    // 2. Search Windows default LocalAppData path
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        final candidate = p.join(
          localAppData,
          'Android',
          'Sdk',
          'platform-tools',
          _adbExecutableName,
        );
        if (await File(candidate).exists()) {
          _cachedPath = candidate;
          return _cachedPath;
        }
      }
    }

    // 3. Search PATH
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv != null) {
      final separator = Platform.isWindows ? ';' : ':';
      final parts = pathEnv.split(separator);
      for (final part in parts) {
        final candidate = p.join(part.trim(), _adbExecutableName);
        if (await File(candidate).exists()) {
          _cachedPath = candidate;
          return _cachedPath;
        }
      }
    }

    // 4. Bundled fallback in AppData / Hopper / bin
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final bundled = p.join(
          appData,
          'Hopper',
          'bin',
          'platform-tools',
          _adbExecutableName,
        );
        if (await File(bundled).exists()) {
          _cachedPath = bundled;
          return _cachedPath;
        }
      }
    }

    debugPrint(
        'AdbLocator: No local adb binary found in SDK, PATH, or bundled dirs.');
    return null;
  }

  static String get _adbExecutableName =>
      Platform.isWindows ? 'adb.exe' : 'adb';
}
