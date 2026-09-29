import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> checkLocationPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return false;
  }
}
