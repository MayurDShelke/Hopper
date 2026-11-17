import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AdbLocator {
  String? _cachedPath;

  Future<String?> locateAdb({String? customPath}) async {
    // 0. Custom user path
    if (customPath != null && customPath.trim().isNotEmpty) {
      final clean = _stripQuotes(customPath.trim());
      final file = File(clean);
      if (await file.exists()) {
        _cachedPath = file.path;
        return _cachedPath;
      }
    }

    if (_cachedPath != null && await File(_cachedPath!).exists()) {
      return _cachedPath;
    }

    // 1. Try 'where.exe adb' on Windows or 'which adb' on Unix
    try {
      final cmd = Platform.isWindows ? 'where.exe' : 'which';
      final res = await Process.run(cmd, ['adb'], runInShell: false);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        for (final l in lines) {
          final clean = _stripQuotes(l.trim());
          if (clean.isNotEmpty && await File(clean).exists()) {
            _cachedPath = clean;
            return _cachedPath;
          }
        }
      }
    } catch (_) {}

    // 2. Search ANDROID_HOME and ANDROID_SDK_ROOT
    final envVars = ['ANDROID_HOME', 'ANDROID_SDK_ROOT'];
    for (final env in envVars) {
      final val = Platform.environment[env];
      if (val != null && val.trim().isNotEmpty) {
        final cleanEnv = _stripQuotes(val.trim());
        final candidate =
            p.join(cleanEnv, 'platform-tools', _adbExecutableName);
        if (await File(candidate).exists()) {
          _cachedPath = candidate;
          return _cachedPath;
        }
      }
    }

    // 3. Search Windows default locations
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        final candidate = p.join(
          _stripQuotes(localAppData.trim()),
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

      // Common standard Windows install roots
      const standardPaths = [
        r'C:\platform-tools\adb.exe',
        r'C:\Android\platform-tools\adb.exe',
        r'C:\Android\Sdk\platform-tools\adb.exe',
        r'C:\Program Files\Android\platform-tools\adb.exe',
      ];
      for (final sp in standardPaths) {
        if (await File(sp).exists()) {
          _cachedPath = sp;
          return _cachedPath;
        }
      }
    }

    // 4. Search PATH environment variable
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv != null) {
      final separator = Platform.isWindows ? ';' : ':';
      final parts = pathEnv.split(separator);
      for (final part in parts) {
        final cleanPart = _stripQuotes(part.trim());
        if (cleanPart.isEmpty) continue;
        final candidate = p.join(cleanPart, _adbExecutableName);
        if (await File(candidate).exists()) {
          _cachedPath = candidate;
          return _cachedPath;
        }
      }
    }

    // 5. Bundled fallback in AppData / Hopper / bin
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final bundled = p.join(
          _stripQuotes(appData.trim()),
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

  static String _stripQuotes(String path) {
    if ((path.startsWith('"') && path.endsWith('"')) ||
        (path.startsWith("'") && path.endsWith("'"))) {
      return path.substring(1, path.length - 1);
    }
    return path;
  }

  static String get _adbExecutableName =>
      Platform.isWindows ? 'adb.exe' : 'adb';
}
