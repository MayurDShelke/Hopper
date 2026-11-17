import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../connect/data/connect_repository.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final TextEditingController _adbPathController = TextEditingController();
  bool _notifications = true;
  bool _autoReconnect = true;
  bool _scrcpyStayAwake = true;
  int _scrcpyBitrate = 8;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepoProvider);
    final adb = await repo.getCustomAdbPath();
    final notifs = await repo.getNotificationsEnabled();
    final auto = await repo.getAutoReconnectAll();
    final stayAwake = await repo.getScrcpyStayAwake();
    final bitrate = await repo.getScrcpyBitrate();

    if (!mounted) return;
    setState(() {
      _adbPathController.text = adb ?? '';
      _notifications = notifs;
      _autoReconnect = auto;
      _scrcpyStayAwake = stayAwake;
      _scrcpyBitrate = bitrate;
      _isLoaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final repo = ref.read(settingsRepoProvider);
    await repo.setCustomAdbPath(_adbPathController.text.trim());
    await repo.setNotificationsEnabled(_notifications);
    await repo.setAutoReconnectAll(_autoReconnect);
    await repo.setScrcpyStayAwake(_scrcpyStayAwake);
    await repo.setScrcpyBitrate(_scrcpyBitrate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _adbPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'General Preferences',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      TextField(
                        controller: _adbPathController,
                        decoration: const InputDecoration(
                          labelText: 'Custom ADB Binary Path (Optional)',
                          hintText: 'C:\\Users\\...\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
                        ),
                      ),
                      const SizedBox(height: AppTokens.space12),
                      SwitchListTile(
                        title: const Text('Desktop Notifications'),
                        subtitle: const Text('Show toasts when devices connect or drop'),
                        value: _notifications,
                        onChanged: (v) => setState(() => _notifications = v),
                      ),
                      SwitchListTile(
                        title: const Text('Auto-Reconnect Saved Devices'),
                        subtitle: const Text('Automatically reconnect paired devices when discovered on LAN'),
                        value: _autoReconnect,
                        onChanged: (v) => setState(() => _autoReconnect = v),
                      ),
                      SwitchListTile(
                        title: const Text('Keep Phone Screen Awake During Mirroring'),
                        value: _scrcpyStayAwake,
                        onChanged: (v) => setState(() => _scrcpyStayAwake = v),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About Hopper', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: AppTokens.space8),
                      Text(
                        'Version 1.0.0 • Lightweight Windows desktop wireless ADB companion for Android testing.\nMIT License • Independent and open source.',
                        style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                      ),
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
