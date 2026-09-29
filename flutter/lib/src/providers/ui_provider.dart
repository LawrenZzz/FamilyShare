import 'package:flutter/foundation.dart';

class UiProvider extends ChangeNotifier {
  bool _detailOpen = false;
  String? _selectedDeviceId;
  bool _panelCollapsed = true;

  bool get detailOpen => _detailOpen;
  String? get selectedDeviceId => _selectedDeviceId;
  bool get panelCollapsed => _panelCollapsed;

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

  void togglePanel() {
    _panelCollapsed = !_panelCollapsed;
    notifyListeners();
  }
}
