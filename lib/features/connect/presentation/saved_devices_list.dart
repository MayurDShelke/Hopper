import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../data/connect_repository.dart';
import '../domain/saved_device.dart';

class SavedDevicesListWidget extends ConsumerWidget {
  final void Function(SavedDevice device) onConnect;

  const SavedDevicesListWidget({
    super.key,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedDevicesListProvider);

    return savedAsync.when(
      data: (devices) {
        if (devices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.space16),
            child: Text(
              'No saved devices yet. Pair a phone above to remember it.',
              style: TextStyle(color: AppTokens.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space8),
          itemBuilder: (context, index) {
            final dev = devices[index];
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.smartphone,
                  color: AppTokens.accent,
                ),
                title: Text(
                  dev.label.isNotEmpty ? dev.label : dev.instanceName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${dev.lastIp}:${dev.lastPort} • Auto-reconnect: ${dev.autoReconnect ? "On" : "Off"}',
                  style: const TextStyle(fontSize: 12, color: AppTokens.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => onConnect(dev),
                      child: const Text('Connect'),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Forget Device',
                      onPressed: () async {
                        final repo = ref.read(savedDevicesRepoProvider);
                        await repo.deleteDevice(dev.instanceName);
                        ref.invalidate(savedDevicesListProvider);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading saved devices: $e'),
    );
  }
}
