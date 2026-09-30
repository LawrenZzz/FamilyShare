import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'device_bridge.dart';
import 'ws_service.dart';
import 'permission_service.dart';
import 'prefs_service.dart';
import '../providers/app_provider.dart';

class LocationService {
  final PermissionService _perms;
  final ApiService _api;
  final AppProvider _app;
  final DeviceBridge _device = DeviceBridge();

  LocationService(this._perms, this._api, WsService _, this._app);

  Timer? _reportTimer;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    if (!await _perms.checkLocationPermissions()) return;
    _running = true;
    if (DeviceBridge.isAndroid) {
      try {
        await _device.startTracking(
          deviceId: _app.deviceId,
          familyId: _app.familyId,
          intervalMs: PrefsService().effectiveReportIntervalMs,
        );
      } catch (error) {
        debugPrint('Background location service failed: $error');
        _startReporting();
      }
    } else {
      _startReporting();
    }
    await locateMe();
  }

  void stop() {
    _running = false;
    _reportTimer?.cancel();
    _reportTimer = null;
    unawaited(_device.stopTracking().catchError(
          (Object error) => debugPrint('Stop location service failed: $error'),
        ));
    _app.setStatus('offline');
  }

  Future<void> updateInterval() async {
    if (!_running) return;
    _reportTimer?.cancel();
    _reportTimer = null;
    if (DeviceBridge.isAndroid) {
      try {
        await _device.startTracking(
          deviceId: _app.deviceId,
          familyId: _app.familyId,
          intervalMs: PrefsService().effectiveReportIntervalMs,
        );
      } catch (error) {
        debugPrint('Update background interval failed: $error');
        _startReporting();
      }
    } else {
      _startReporting();
    }
  }

  void _startReporting() {
    final interval = PrefsService().effectiveReportIntervalMs;
    _reportTimer = Timer.periodic(Duration(milliseconds: interval), (_) async {
      if (!_running) return;
      try {
        final fix = await _device.getCurrentLocation();
        if (_running) await _reportLocation(fix);
      } catch (e) {
        debugPrint('Location read failed: $e');
      }
    });
  }

  Future<void> _reportLocation(LocationFix fix) async {
    if (_app.familyId.isEmpty || PrefsService().offlineMode) return;
    final result = await _api.post('/api/location/report', {
      'deviceId': _app.deviceId,
      'familyId': _app.familyId,
      'lat': fix.lat,
      'lng': fix.lng,
      'accuracy': fix.accuracy,
      'ts': fix.ts,
      'battery': fix.battery,
      'network': fix.network,
      'address': fix.address,
    });
    if (!result.ok) {
      debugPrint('Location report failed: ${result.error}');
    }
  }

  Future<void> locateMe() async {
    try {
      if (!await _perms.checkLocationPermissions()) return;
      final fix = await _device.getCurrentLocation();
      _app.updateMyLocation(fix);
      await _reportLocation(fix);
    } catch (e) {
      debugPrint('Location read failed: $e');
    }
  }

  void dispose() => stop();
}
