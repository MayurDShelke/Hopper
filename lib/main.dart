import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowSetup.initialize();

  runApp(
    const ProviderScope(
      child: HopperApp(),
    ),
  );
}
