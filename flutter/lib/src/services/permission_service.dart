import 'package:permission_handler/permission_handler.dart';
import 'device_bridge.dart';

class PermissionSnapshot {
  final bool preciseLocation;
  final bool backgroundLocation;
  final bool notifications;
  final bool batteryUnrestricted;

  const PermissionSnapshot({
    required this.preciseLocation,
    required this.backgroundLocation,
    required this.notifications,
    required this.batteryUnrestricted,
  });

  bool get readyForBackground => preciseLocation && backgroundLocation;
}

class PermissionService {
  final DeviceBridge _bridge = DeviceBridge();

  Future<PermissionSnapshot> snapshot() async {
    if (DeviceBridge.isAndroid) {
      final status = await _bridge.permissionStatus();
      return PermissionSnapshot(
        preciseLocation: status['preciseLocation'] == true,
        backgroundLocation: status['backgroundLocation'] == true,
        notifications: status['notifications'] == true,
        batteryUnrestricted: status['batteryUnrestricted'] == true,
      );
    }
    return PermissionSnapshot(
      preciseLocation: await Permission.locationWhenInUse.isGranted,
      backgroundLocation: await Permission.locationAlways.isGranted,
      notifications: await Permission.notification.isGranted,
      batteryUnrestricted: true,
    );
  }

  Future<bool> checkLocationPermissions() async {
    if (await Permission.locationWhenInUse.isGranted) return true;
    return (await Permission.locationWhenInUse.request()).isGranted;
  }

  Future<void> requestPreciseLocation() async {
    if (await Permission.locationWhenInUse.isGranted) {
      await _bridge.openLocationSettings();
    } else {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<void> requestBackgroundLocation() async {
    if (!await checkLocationPermissions()) return;
    final result = await Permission.locationAlways.request();
    if (!result.isGranted) await _bridge.openLocationSettings();
  }

  Future<void> requestNotifications() async {
    final result = await Permission.notification.request();
    if (!result.isGranted) await openAppSettings();
  }

  Future<void> openLocationSettings() => _bridge.openLocationSettings();
  Future<void> openBatterySettings() => _bridge.openBatterySettings();
  Future<void> openAutoStartSettings() => _bridge.openAutoStartSettings();
}
