import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepo {
  static const String _customAdbPathKey = 'custom_adb_path';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _autoReconnectAllKey = 'auto_reconnect_all';
  static const String _scrcpyStayAwakeKey = 'scrcpy_stay_awake';
  static const String _scrcpyBitrateKey = 'scrcpy_bitrate';

  final SharedPreferences? _prefs;

  SettingsRepo([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<String?> getCustomAdbPath() async {
    final prefs = await _getPrefs();
    return prefs.getString(_customAdbPathKey);
  }

  Future<void> setCustomAdbPath(String? path) async {
    final prefs = await _getPrefs();
    if (path == null || path.isEmpty) {
      await prefs.remove(_customAdbPathKey);
    } else {
      await prefs.setString(_customAdbPathKey, path);
    }
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getAutoReconnectAll() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_autoReconnectAllKey) ?? true;
  }

  Future<void> setAutoReconnectAll(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_autoReconnectAllKey, enabled);
  }

  Future<bool> getScrcpyStayAwake() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_scrcpyStayAwakeKey) ?? true;
  }

  Future<void> setScrcpyStayAwake(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_scrcpyStayAwakeKey, value);
  }

  Future<int> getScrcpyBitrate() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_scrcpyBitrateKey) ?? 8; // Default 8 Mbps
  }

  Future<void> setScrcpyBitrate(int bitrateMbps) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_scrcpyBitrateKey, bitrateMbps);
  }
}
