import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String _serverUrl = 'https://familyshare.lawlovesimone.site';
  static String _apiToken = 'mdi9a9083df9bnq97ssdbibbu7d98';
  static String _deviceId = '';
  static String _deviceName = '';

  static String get serverUrl => _serverUrl;
  static String get apiToken => _apiToken;
  static String get deviceId => _deviceId;
  static String get deviceName => _deviceName;
  static String get wsUrl =>
      _serverUrl.replaceFirst(RegExp(r'^http'), 'ws') + '/ws';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('server_url');
    if (stored != null && stored.isNotEmpty) {
      _serverUrl = stored.trim().replaceFirst(RegExp(r'/+$'), '');
    }
    _deviceId = prefs.getString('device_id') ?? '';
    _deviceName = prefs.getString('device_name') ?? '';
  }

  static void setDeviceId(String id) {
    _deviceId = id;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString('device_id', id));
  }

  static void setDeviceName(String name) {
    _deviceName = name;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString('device_name', name));
  }

  static void applyServer(String url) {
    _serverUrl = url.trim().replaceFirst(RegExp(r'/+$'), '');
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('server_url', _serverUrl);
    });
  }
}
