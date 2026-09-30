import 'package:flutter/material.dart';

import '../services/prefs_service.dart';

class UiProvider extends ChangeNotifier {
  bool _detailOpen = false;
  String? _selectedDeviceId;
  String? _trajectoryDeviceId;
  bool _panelCollapsed = true;
  late ThemeMode _themeMode;

  UiProvider() {
    _themeMode = _parseThemeMode(PrefsService().themeMode);
  }

  bool get detailOpen => _detailOpen;
  String? get selectedDeviceId => _selectedDeviceId;
  String? get trajectoryDeviceId => _trajectoryDeviceId;
  bool get panelCollapsed => _panelCollapsed;
  ThemeMode get themeMode => _themeMode;

  void openDetail(String deviceId) {
    _selectedDeviceId = deviceId;
    _detailOpen = true;
    notifyListeners();
  }

  void closeDetail() {
    _detailOpen = false;
    _selectedDeviceId = null;
    notifyListeners();
  }

  void showTrajectory(String deviceId) {
    _trajectoryDeviceId = deviceId;
    notifyListeners();
  }

  void clearTrajectory() {
    if (_trajectoryDeviceId == null) return;
    _trajectoryDeviceId = null;
    notifyListeners();
  }

  void togglePanel() {
    _panelCollapsed = !_panelCollapsed;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    PrefsService().setThemeMode(mode.name);
    notifyListeners();
  }

  void setDarkMode(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static ThemeMode _parseThemeMode(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
