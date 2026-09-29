import 'package:flutter/foundation.dart';

class MapProvider extends ChangeNotifier {
  double? _centerLat;
  double? _centerLng;
  double _zoom = 15.0;

  double? get centerLat => _centerLat;
  double? get centerLng => _centerLng;
  double get zoom => _zoom;

  void setCenter(double lat, double lng) {
    _centerLat = lat;
    _centerLng = lng;
    notifyListeners();
  }

  void setZoom(double z) {
    _zoom = z;
    notifyListeners();
  }
}
