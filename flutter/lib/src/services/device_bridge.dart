import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationFix {
  final double lat;
  final double lng;
  final double accuracy;
  final int ts;
  final int battery;
  final String network;
  final String address;

  const LocationFix({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.ts,
    required this.battery,
    required this.network,
    required this.address,
  });

  factory LocationFix.fromMap(Map<dynamic, dynamic> value) => LocationFix(
        lat: (value['lat'] as num).toDouble(),
        lng: (value['lng'] as num).toDouble(),
        accuracy: (value['accuracy'] as num).toDouble(),
        ts: (value['ts'] as num).toInt(),
        battery: (value['battery'] as num?)?.toInt() ?? -1,
        network: value['network'] as String? ?? '',
        address: value['address'] as String? ?? '',
      );
}

class DeviceBridge {
  static const _channel = MethodChannel('familyshare/device');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<LocationFix> getCurrentLocation() async {
    if (isAndroid) {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) throw StateError('高德定位未返回结果');
      return LocationFix.fromMap(result);
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LocationFix(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      ts: position.timestamp.millisecondsSinceEpoch,
      battery: -1,
      network: '',
      address: '',
    );
  }

  Future<void> startTracking({
    required String deviceId,
    required String familyId,
    required int intervalMs,
  }) async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('startTracking', {
      'deviceId': deviceId,
      'familyId': familyId,
      'intervalMs': intervalMs,
    });
  }

  Future<void> stopTracking() async {
    if (isAndroid) await _channel.invokeMethod<void>('stopTracking');
  }

  Future<Uint8List?> pickAvatar() async {
    if (!isAndroid) return null;
    return _channel.invokeMethod<Uint8List>('pickAvatar');
  }

  Future<Map<dynamic, dynamic>> permissionStatus() async {
    if (!isAndroid) return {};
    return await _channel.invokeMapMethod<dynamic, dynamic>(
          'permissionStatus',
        ) ??
        {};
  }

  Future<void> openLocationSettings() => _openSettings('openLocationSettings');
  Future<void> openBatterySettings() => _openSettings('openBatterySettings');
  Future<void> openAutoStartSettings() =>
      _openSettings('openAutoStartSettings');

  Future<void> _openSettings(String method) async {
    if (isAndroid) await _channel.invokeMethod<void>(method);
  }
}
