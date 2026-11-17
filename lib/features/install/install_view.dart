import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../app/router.dart';
import '../../core/errors/error_mapper.dart';
import '../../shared/widgets/error_banner.dart';
import '../connect/data/connect_repository.dart';

class InstallView extends ConsumerStatefulWidget {
  const InstallView({super.key});

  @override
  ConsumerState<InstallView> createState() => _InstallViewState();
}

class _InstallViewState extends ConsumerState<InstallView> {
  bool _isDragging = false;
  bool _isInstalling = false;
  String? _statusMessage;
  dynamic _lastError;

  bool _reinstall = true;
  bool _allowDowngrade = false;
  bool _grantPermissions = true;

  Future<void> _installApk(String filePath, String serial) async {
    setState(() {
      _isInstalling = true;
      _statusMessage = 'Installing APK to $serial...';
      _lastError = null;
    });

    final adb = ref.read(adbBackendProvider);
    final args = <String>['-s', serial, 'install'];

    if (_reinstall) args.add('-r');
    if (_allowDowngrade) args.add('-d');
    if (_grantPermissions) args.add('-g');
    args.add(filePath);

    try {
      final res = await adb.runAdbCommand(args);
      if (res.contains('Success')) {
        setState(() {
          _statusMessage = 'APK successfully installed!';
          _isInstalling = false;
        });
      } else {
        setState(() {
          _lastError = res;
          _isInstalling = false;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _lastError = e;
        _isInstalling = false;
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final serial = nav.selectedDeviceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.install_mobile,
                            color: AppTokens.accent,
                            size: 28,
                          ),
                          const SizedBox(width: AppTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Install APK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  serial != null ? 'Target: $serial' : 'No target phone selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space20),
                      // Drop zone
                      DropTarget(
                        onDragEntered: (_) => setState(() => _isDragging = true),
                        onDragExited: (_) => setState(() => _isDragging = false),
                        onDragDone: (detail) {
                          setState(() => _isDragging = false);
                          if (serial == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a target device first.')),
                            );
                            return;
                          }
                          final apk = detail.files.firstWhere(
                            (f) => f.path.toLowerCase().endsWith('.apk'),
                            orElse: () => detail.files.first,
                          );
                          _installApk(apk.path, serial);
                        },
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? AppTokens.accent.withOpacity(0.1)
                                : AppTokens.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            border: Border.all(
                              color: _isDragging ? AppTokens.accent : AppTokens.border,
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: _isDragging ? AppTokens.accent : AppTokens.textMuted,
                                ),
                                const SizedBox(height: AppTokens.space12),
                                Text(
                                  _isDragging
                                      ? 'Drop APK file to install'
                                      : 'Drag and drop .apk file here',
                                  style: TextStyle(
                                    color: _isDragging ? AppTokens.accent : AppTokens.text,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      SwitchListTile(
                        title: const Text('Reinstall existing app (-r)'),
                        value: _reinstall,
                        onChanged: (v) => setState(() => _reinstall = v),
                      ),
                      SwitchListTile(
                        title: const Text('Allow version downgrade (-d)'),
                        value: _allowDowngrade,
                        onChanged: (v) => setState(() => _allowDowngrade = v),
                      ),
                      SwitchListTile(
                        title: const Text('Grant all runtime permissions (-g)'),
                        value: _grantPermissions,
                        onChanged: (v) => setState(() => _grantPermissions = v),
                      ),
                      if (_isInstalling) ...[
                        const SizedBox(height: AppTokens.space16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                      if (_statusMessage != null) ...[
                        const SizedBox(height: AppTokens.space16),
                        Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: AppTokens.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_lastError != null) ...[
                        const SizedBox(height: AppTokens.space16),
                        ErrorBanner(
                          error: ErrorMapper.map(_lastError),
                          onDismiss: () => setState(() => _lastError = null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
