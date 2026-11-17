import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowSetup {
  WindowSetup._();

  static Future<void> initialize() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1100, 750),
        minimumSize: Size(1000, 650),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'Hopper',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Window setup notice: $e');
    }
  }
}
