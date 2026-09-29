import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'ws_service.dart';
import 'permission_service.dart';
import 'prefs_service.dart';
import '../providers/app_provider.dart';

class LocationService {
  final PermissionService _perms;
  final ApiService _api;
  final AppProvider _app;

  LocationService(this._perms, this._api, WsService _, this._app);

  Timer? _reportTimer;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    if (!await _perms.checkLocationPermissions()) return;
    _running = true;
    await locateMe();
    _startReporting();
    _app.setStatus('online');
  }

  void stop() {
    _running = false;
    _reportTimer?.cancel();
    _reportTimer = null;
    _app.setStatus('offline');
  }

  void _startReporting() {
    final interval = PrefsService().trackIntervalMs;
    _reportTimer = Timer.periodic(Duration(milliseconds: interval), (_) async {
      if (!_running) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        await _reportLocation(pos);
      } catch (e) {
        debugPrint('Location read failed: $e');
      }
    });
  }

  Future<void> _reportLocation(Position pos) async {
    if (_app.familyId.isEmpty) return;
    final result = await _api.post('/api/location/report', {
      'deviceId': _app.deviceId,
      'familyId': _app.familyId,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'ts': pos.timestamp.millisecondsSinceEpoch,
      'battery': -1,
      'network': '',
      'address': '',
    });
    if (!result.ok) {
      debugPrint('Location report failed: ${result.error}');
    }
  }

  Future<void> locateMe() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _app.updateMyLocation(pos.latitude, pos.longitude);
      await _reportLocation(pos);
    } catch (e) {
      debugPrint('Location read failed: $e');
    }
  }

  void dispose() => stop();
}
