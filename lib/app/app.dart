import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'router.dart';
import '../core/connection/connection_state.dart';
import '../shared/widgets/status_dot.dart';
import '../features/connect/data/connect_repository.dart';
import '../features/connect/presentation/pairing_wizard.dart';
import '../features/devices/devices_view.dart';
import '../features/mirror/mirror_view.dart';
import '../features/logcat/presentation/logcat_view.dart';
import '../features/install/install_view.dart';
import '../features/flutter_panel/presentation/flutter_panel_view.dart';
import '../features/diagnostics/diagnostics_view.dart';
import '../features/settings/settings_view.dart';

class HopperApp extends StatelessWidget {
  const HopperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HopperMainScaffold(),
    );
  }
}

class HopperMainScaffold extends ConsumerWidget {
  const HopperMainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final devicesAsync = ref.watch(adbDevicesStreamProvider);
    final adbStatusAsync = ref.watch(adbStatusProvider);

    return Scaffold(
      body: Column(
        children: [
          // Custom Window Titlebar
          Container(
            height: 40,
            color: AppTokens.surface,
            child: Row(
              children: [
                const SizedBox(width: AppTokens.space12),
                const Icon(Icons.swap_calls, color: AppTokens.accent, size: 20),
                const SizedBox(width: AppTokens.space8),
                const Text(
                  'Hopper',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Pair new phone'),
                  onPressed: () => navNotifier.setTab(AppTab.connect),
                ),
                const SizedBox(width: AppTokens.space8),
                IconButton(
                  icon: const Icon(Icons.settings, size: 18),
                  tooltip: 'Settings',
                  onPressed: () => navNotifier.setTab(AppTab.settings),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => windowManager.minimize(),
                ),
                IconButton(
                  icon: const Icon(Icons.crop_square, size: 16),
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  hoverColor: Colors.red.withValues(alpha: 0.5),
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTokens.border),
          // Body (Sidebar + Content)
          Expanded(
            child: Row(
              children: [
                // Left Sidebar
                Container(
                  width: 240,
                  color: AppTokens.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'MY PHONES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTokens.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: devicesAsync.when(
                          data: (devices) {
                            if (devices.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No phones attached',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTokens.textMuted),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                final d = devices[index];
                                final isSelected =
                                    nav.selectedDeviceId == d.serial;

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: AppTokens.surfaceVariant,
                                  leading: StatusDot(
                                    status: d.isConnected
                                        ? DeviceStatus.connected
                                        : DeviceStatus.offline,
                                    showLabel: false,
                                  ),
                                  title: Text(
                                    d.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    d.isWireless ? 'Wi-Fi' : 'USB',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTokens.textMuted),
                                  ),
                                  onTap: () {
                                    navNotifier.selectDevice(d.serial);
                                  },
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      const Divider(height: 1, color: AppTokens.border),
                      ListTile(
                        leading: const Icon(Icons.devices, size: 20),
                        title: const Text('Device Overview',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.devices ||
                            nav.currentTab == AppTab.overview,
                        onTap: () => navNotifier.setTab(AppTab.devices),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cast, size: 20),
                        title: const Text('Mirror (scrcpy)',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.mirror,
                        onTap: () => navNotifier.setTab(AppTab.mirror),
                      ),
                      ListTile(
                        leading: const Icon(Icons.article_outlined, size: 20),
                        title: const Text('Logcat',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.logcat,
                        onTap: () => navNotifier.setTab(AppTab.logcat),
                      ),
                      ListTile(
                        leading: const Icon(Icons.install_mobile, size: 20),
                        title: const Text('Install APK',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.install,
                        onTap: () => navNotifier.setTab(AppTab.install),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flutter_dash, size: 20),
                        title: const Text('Flutter Runner',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.flutterPanel,
                        onTap: () => navNotifier.setTab(AppTab.flutterPanel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.troubleshoot, size: 20),
                        title: const Text('Diagnostics',
                            style: TextStyle(fontSize: 13)),
                        selected: nav.currentTab == AppTab.diagnostics,
                        onTap: () => navNotifier.setTab(AppTab.diagnostics),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const VerticalDivider(
                    width: 1, thickness: 1, color: AppTokens.border),
                // Main Content View
                Expanded(
                  child: Container(
                    color: AppTokens.background,
                    child: _buildCurrentTab(nav.currentTab),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTokens.border),
          // Footer Status Bar
          Container(
            height: 28,
            color: AppTokens.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                adbStatusAsync.when(
                  data: (status) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.serverRunning
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 14,
                        color: status.serverRunning
                            ? AppTokens.success
                            : AppTokens.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.path != null
                            ? (status.serverRunning
                                ? 'adb operational (${status.version})'
                                : 'adb server stopped')
                            : 'adb not found (Platform Tools missing)',
                        style: const TextStyle(
                            fontSize: 11, color: AppTokens.textMuted),
                      ),
                    ],
                  ),
                  loading: () => const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      SizedBox(width: 6),
                      Text('Initializing adb...',
                          style: TextStyle(
                              fontSize: 11, color: AppTokens.textMuted)),
                    ],
                  ),
                  error: (e, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, size: 14, color: AppTokens.error),
                      const SizedBox(width: 6),
                      Text('adb error: $e',
                          style: const TextStyle(
                              fontSize: 11, color: AppTokens.error)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.wifi, size: 14, color: AppTokens.accent),
                const SizedBox(width: 6),
                const Text(
                  'Wi-Fi Discovery: Active',
                  style: TextStyle(fontSize: 11, color: AppTokens.textMuted),
                ),
                const Spacer(),
                const Text(
                  'Hopper v1.0.0',
                  style: TextStyle(fontSize: 11, color: AppTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(AppTab tab) {
    switch (tab) {
      case AppTab.connect:
        return const PairingWizard();
      case AppTab.devices:
      case AppTab.overview:
        return const DevicesView();
      case AppTab.mirror:
        return const MirrorView();
      case AppTab.logcat:
        return const LogcatView();
      case AppTab.install:
        return const InstallView();
      case AppTab.flutterPanel:
        return const FlutterPanelView();
      case AppTab.diagnostics:
        return const DiagnosticsView();
      case AppTab.settings:
        return const SettingsView();
    }
  }
}
