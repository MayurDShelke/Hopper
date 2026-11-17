import 'package:shared_preferences/shared_preferences.dart';
import '../../features/connect/domain/saved_device.dart';

class SavedDevicesRepo {
  static const String _key = 'hopper_saved_devices';
  final SharedPreferences? _prefs;

  SavedDevicesRepo([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<List<SavedDevice>> getSavedDevices() async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((str) => SavedDevice.fromJson(str)).toList();
  }

  Future<void> saveDevice(SavedDevice device) async {
    final prefs = await _getPrefs();
    final devices = await getSavedDevices();
    final index =
        devices.indexWhere((d) => d.instanceName == device.instanceName);

    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }

    final rawList = devices.map((d) => d.toJson()).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> deleteDevice(String instanceName) async {
    final prefs = await _getPrefs();
    final devices = await getSavedDevices();
    devices.removeWhere((d) => d.instanceName == instanceName);

    final rawList = devices.map((d) => d.toJson()).toList();
    await prefs.setStringList(_key, rawList);
  }
}
