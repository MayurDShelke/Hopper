import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../app/router.dart';
import '../../core/connection/connection_state.dart';
import '../../shared/widgets/status_dot.dart';
import '../../shared/widgets/empty_state.dart';
import '../connect/data/connect_repository.dart';

class DevicesView extends ConsumerWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(adbDevicesStreamProvider);

    return devicesAsync.when(
      data: (devices) {
        if (devices.isEmpty) {
          return EmptyState(
            icon: Icons.phonelink_off,
            title: 'No Active Devices Found',
            description:
                'Make sure Wireless debugging is enabled on your phone and you are on the same Wi-Fi network.',
            action: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Pair New Phone'),
              onPressed: () {
                ref.read(navigationProvider.notifier).setTab(AppTab.connect);
              },
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTokens.space24),
          itemCount: devices.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTokens.space12),
          itemBuilder: (context, index) {
            final dev = devices[index];
            final status = dev.isConnected
                ? DeviceStatus.connected
                : dev.isUnauthorized
                    ? DeviceStatus.unauthorized
                    : DeviceStatus.offline;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.smartphone,
                          size: 32,
                          color: AppTokens.accent,
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dev.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTokens.space2),
                              Text(
                                '${dev.serial} • ${dev.isWireless ? "Wireless" : "USB"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusDot(status: status),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Wrap(
                      spacing: AppTokens.space8,
                      runSpacing: AppTokens.space8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cast, size: 16),
                          label: const Text('Mirror (scrcpy)'),
                          onPressed: () {
                            ref
                                .read(navigationProvider.notifier)
                                .selectDevice(dev.serial);
                            ref
                                .read(navigationProvider.notifier)
                                .setTab(AppTab.mirror);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.article_outlined, size: 16),
                          label: const Text('Logcat'),
                          onPressed: () {
                            ref
                                .read(navigationProvider.notifier)
                                .selectDevice(dev.serial);
                            ref
                                .read(navigationProvider.notifier)
                                .setTab(AppTab.logcat);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.install_mobile, size: 16),
                          label: const Text('Install APK'),
                          onPressed: () {
                            ref
                                .read(navigationProvider.notifier)
                                .selectDevice(dev.serial);
                            ref
                                .read(navigationProvider.notifier)
                                .setTab(AppTab.install);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.flutter_dash, size: 16),
                          label: const Text('Flutter Runner'),
                          onPressed: () {
                            ref
                                .read(navigationProvider.notifier)
                                .selectDevice(dev.serial);
                            ref
                                .read(navigationProvider.notifier)
                                .setTab(AppTab.flutterPanel);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Device stream error: $e')),
    );
  }
}
