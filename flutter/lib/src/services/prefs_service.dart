import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static final PrefsService _instance = PrefsService._internal();
  factory PrefsService() => _instance;
  PrefsService._internal();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get deviceId => _prefs.getString('device_id') ?? '';
  String get deviceName => _prefs.getString('device_name') ?? '';
  String get familyId => _prefs.getString('family_id') ?? '';
  String get familyCode => _prefs.getString('family_code') ?? '';
  String get pendingJoinRequestId =>
      _prefs.getString('pending_join_request_id') ?? '';
  bool get isOwner => _prefs.getBool('is_owner') ?? false;
  bool get offlineMode => _prefs.getBool('offline_mode') ?? false;
  bool get trackEnabled => _prefs.getBool('track_enabled') ?? false;
  int get trackIntervalMs =>
      _prefs.getInt('track_interval_ms') ?? (5 * 60 * 1000);
  int get effectiveReportIntervalMs =>
      trackEnabled ? trackIntervalMs : 30 * 60 * 1000;
  bool get ringEnabled => _prefs.getBool('ring_enabled') ?? true;
  String get themeMode => _prefs.getString('theme_mode') ?? 'system';
  double get lastLat => _prefs.getDouble('last_lat') ?? 0.0;
  double get lastLng => _prefs.getDouble('last_lng') ?? 0.0;
  int get lastTs => _prefs.getInt('last_ts') ?? 0;

  void setDeviceId(String id) => _prefs.setString('device_id', id);
  void setDeviceName(String name) => _prefs.setString('device_name', name);
  void setFamilyId(String id) => _prefs.setString('family_id', id);
  void setFamilyCode(String code) => _prefs.setString('family_code', code);
  void setPendingJoinRequestId(String id) =>
      _prefs.setString('pending_join_request_id', id);
  void setIsOwner(bool v) => _prefs.setBool('is_owner', v);
  void setOfflineMode(bool v) => _prefs.setBool('offline_mode', v);
  void setTrackEnabled(bool v) => _prefs.setBool('track_enabled', v);
  void setTrackIntervalMs(int ms) => _prefs.setInt('track_interval_ms', ms);
  void setRingEnabled(bool v) => _prefs.setBool('ring_enabled', v);
  void setThemeMode(String mode) => _prefs.setString('theme_mode', mode);
  void saveLastLocation(double lat, double lng, int ts) {
    _prefs.setDouble('last_lat', lat);
    _prefs.setDouble('last_lng', lng);
    _prefs.setInt('last_ts', ts);
  }

  Future<List<String>> getFamilyIds() async {
    final raw = _prefs.getString('family_ids') ?? '';
    if (raw.isEmpty) return [];
    return raw.split('\n').where((s) => s.isNotEmpty).toList();
  }

  Future<void> setFamilyIds(List<String> ids) async {
    await _prefs.setString('family_ids', ids.join('\n'));
  }

  Future<void> removeFamily(String id) async {
    final ids = await getFamilyIds();
    ids.remove(id);
    await setFamilyIds(ids);
    if (familyId == id) {
      setFamilyId(ids.isEmpty ? '' : ids.first);
    }
  }

  Future<Map<String, String>> getFamilyCodes() async {
    final raw = _prefs.getString('family_codes') ?? '';
    final result = <String, String>{};
    for (final line in raw.split('\n')) {
      final idx = line.indexOf('|');
      if (idx > 0) {
        result[line.substring(0, idx)] = line.substring(idx + 1);
      }
    }
    return result;
  }
}
