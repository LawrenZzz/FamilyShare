import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../services/location_service.dart';
import '../services/device_bridge.dart';
import '../services/prefs_service.dart';
import '../models/family.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class AppProvider extends ChangeNotifier {
  final PrefsService _prefs = PrefsService();
  ApiService? _apiService;
  WsService? _wsService;
  LocationService? _locationService;

  String _status = 'connecting';
  String get status => _status;
  List<Member> get members => _members;
  final List<Member> _members = [];
  Family? _currentFamily;
  Family? get currentFamily => _currentFamily;
  String get deviceId => _prefs.deviceId;
  String get deviceName => _prefs.deviceName;
  String get familyId => _prefs.familyId;
  bool get isOwner => _prefs.isOwner;
  List<JoinRequest> get joinRequests => _joinRequests;
  final List<JoinRequest> _joinRequests = [];
  Timer? _joinPollTimer;
  Timer? _statusTimer;

  String get pendingJoinRequestId => _prefs.pendingJoinRequestId;

  void setApiService(ApiService api) => _apiService = api;
  void setWsService(WsService ws) {
    _wsService = ws;
    _wsService?.addConnectListener(
        () => setStatus(_prefs.offlineMode ? 'offline' : 'online'));
    _wsService?.addDisconnectListener(() => setStatus('connecting'));
  }

  void setLocationService(LocationService loc) => _locationService = loc;

  Future<void> initialize() async {
    if (familyId.isEmpty) {
      if (pendingJoinRequestId.isNotEmpty)
        _pollJoinStatus(pendingJoinRequestId);
      return;
    }
    _currentFamily = Family(
      familyId: familyId,
      code: _prefs.familyCode,
      isOwner: isOwner,
    );
    refreshMembers();
    await _wsService?.connect();
    if (pendingJoinRequestId.isNotEmpty) {
      _pollJoinStatus(pendingJoinRequestId);
    }
  }

  void setStatus(String s) {
    _status = s;
    notifyListeners();
  }

  void updateMyLocation(LocationFix fix) {
    final idx = _members.indexWhere((m) => m.deviceId == deviceId);
    if (idx >= 0) {
      _members[idx] = _members[idx].copyWith(
        hasLocation: true,
        lat: fix.lat,
        lng: fix.lng,
        accuracy: fix.accuracy,
        ts: fix.ts,
        battery: fix.battery,
        network: fix.network,
        address: fix.address,
      );
    } else {
      _members.add(Member(
        deviceId: deviceId,
        name: _prefs.deviceName,
        online: true,
        hasLocation: true,
        lat: fix.lat,
        lng: fix.lng,
        accuracy: fix.accuracy,
        ts: fix.ts,
        battery: fix.battery,
        network: fix.network,
        address: fix.address,
      ));
    }
    _prefs.saveLastLocation(fix.lat, fix.lng, fix.ts);
    notifyListeners();
  }

  Future<void> locateMe() async {
    await _locationService?.locateMe();
  }

  Future<bool?> uploadMyAvatar() async {
    if (_apiService == null || familyId.isEmpty || deviceId.isEmpty)
      return false;
    try {
      final jpeg = await DeviceBridge().pickAvatar();
      if (jpeg == null) return null;
      final result = await _apiService!.uploadAvatar(deviceId, familyId, jpeg);
      if (!result.ok) {
        debugPrint('Avatar upload failed: ${result.error}');
        return false;
      }
      refreshMembers();
      return true;
    } catch (error) {
      debugPrint('Avatar picker failed: $error');
      return false;
    }
  }

  Future<void> startLocationSharing() async {
    if (!_prefs.offlineMode) await _locationService?.start();
  }

  void refreshMembers() {
    if (familyId.isEmpty || _apiService == null) return;
    _apiService!.get('/api/family/members?familyId=$familyId').then((result) {
      if (!result.ok) return;
      try {
        _members.clear();
        _members.addAll(Member.fromJsonList(result.data));
        final own = _members.where((member) => member.deviceId == deviceId);
        if (own.isNotEmpty) {
          final member = own.first;
          if (_prefs.trackEnabled != member.track ||
              _prefs.trackIntervalMs != member.trackIntervalMs) {
            _prefs.setTrackEnabled(member.track);
            _prefs.setTrackIntervalMs(member.trackIntervalMs);
            final location = _locationService;
            if (location != null) unawaited(location.updateInterval());
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('parse members error: $e');
      }
    });
  }

  void handleWsMessage(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'location-update':
        final m = Member.fromJson(data);
        final idx = _members.indexWhere((e) => e.deviceId == m.deviceId);
        if (idx >= 0) {
          final current = _members[idx];
          _members[idx] = _members[idx].copyWith(
            name: m.name.isEmpty ? null : m.name,
            hasLocation: m.hasLocation,
            lat: m.lat,
            lng: m.lng,
            accuracy: m.accuracy,
            ts: m.ts,
            battery: m.battery,
            network: m.network,
            address: m.address,
            trajectory: current.track && m.hasLocation
                ? _appendTrackPoint(current, TrackPoint.fromJson(data))
                : null,
          );
        } else {
          _members.add(m.copyWith(online: true));
        }
        notifyListeners();
        break;
      case 'member-status':
        final did = data['deviceId'] as String? ?? '';
        final online = data['online'] as bool? ?? false;
        final idx = _members.indexWhere((e) => e.deviceId == did);
        if (idx >= 0) {
          _members[idx] = _members[idx].copyWith(
            online: online,
            offlineMode: data['offlineMode'] as bool?,
          );
          notifyListeners();
        }
        break;
      case 'member-joined':
        refreshMembers();
        break;
      case 'member-removed':
        final removedId = data['deviceId'] as String? ?? '';
        if (removedId == deviceId) {
          _locationService?.stop();
          _prefs.setFamilyId('');
          _currentFamily = null;
          _members.clear();
          _wsService?.disconnect();
          notifyListeners();
        } else {
          _members.removeWhere((m) => m.deviceId == removedId);
          notifyListeners();
        }
        break;
      case 'join-request':
        _joinRequests.add(JoinRequest(
          requestId: data['requestId'] as String? ?? '',
          deviceId: data['deviceId'] as String? ?? '',
          name: data['name'] as String? ?? '',
          ts: (data['ts'] as num?)?.toInt() ?? 0,
        ));
        notifyListeners();
        break;
      case 'family-disbanded':
        final fid = data['familyId'] as String? ?? '';
        if (fid == familyId) {
          _locationService?.stop();
          _prefs.setFamilyId('');
          _currentFamily = null;
          _members.clear();
          _wsService?.disconnect();
          notifyListeners();
        }
        break;
      case 'report-now':
        _locationService?.locateMe();
        break;
      case 'ring':
        if (_prefs.ringEnabled) {
          SystemSound.play(SystemSoundType.alert);
          setStatus('ringing');
          _statusTimer?.cancel();
          _statusTimer = Timer(const Duration(seconds: 3), () {
            if (_status == 'ringing') setStatus('online');
          });
        }
        break;
      case 'track-changed':
        final did = data['deviceId'] as String? ?? '';
        final enabled = data['track'] as bool? ?? false;
        final interval = (data['intervalMs'] as num?)?.toInt() ?? 0;
        final idx = _members.indexWhere((e) => e.deviceId == did);
        if (idx >= 0) {
          _members[idx] = _members[idx].copyWith(
            track: enabled,
            trackIntervalMs: interval > 0 ? interval : null,
            trajectory: enabled ? null : const [],
          );
          notifyListeners();
        }
        if (did == deviceId) {
          _prefs.setTrackEnabled(enabled);
          if (interval > 0) _prefs.setTrackIntervalMs(interval);
          final location = _locationService;
          if (location != null) unawaited(location.updateInterval());
        }
        refreshMembers();
        break;
      case 'owner-changed':
        final ownerId = data['deviceId'] as String? ?? '';
        _prefs.setIsOwner(ownerId == deviceId);
        for (var i = 0; i < _members.length; i++) {
          _members[i] = _members[i].copyWith(
            isOwner: _members[i].deviceId == ownerId,
          );
        }
        notifyListeners();
        break;
    }
  }

  Future<void> createFamily(String name) async {
    if (_apiService == null) return;
    final result = await _apiService!.post('/api/family/create', {
      'deviceId': deviceId,
      'name': name,
    });
    if (result.ok) {
      final data = jsonDecode(result.data) as Map<String, dynamic>;
      final fid = data['familyId'] as String? ?? '';
      final code = data['code'] as String? ?? '';
      if (fid.isNotEmpty) {
        _prefs.setFamilyId(fid);
        _prefs.setFamilyCode(code);
        _prefs.setIsOwner(true);
        _currentFamily =
            Family(familyId: fid, code: code, name: name, isOwner: true);
        _prefs.setFamilyIds({...await _prefs.getFamilyIds(), fid}.toList());
        notifyListeners();
        _wsService?.connect();
      }
    }
  }

  Future<void> joinFamily(String code) async {
    if (_apiService == null) return;
    final result = await _apiService!.post('/api/family/join', {
      'code': code,
      'deviceId': deviceId,
      'name': _prefs.deviceName,
    });
    if (result.ok) {
      final data = jsonDecode(result.data) as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      if (status == 'ok') {
        final fid = data['familyId'] as String? ?? '';
        final famCode = data['code'] as String? ?? '';
        _prefs.setFamilyId(fid);
        _prefs.setFamilyCode(famCode);
        _currentFamily = Family(familyId: fid, code: famCode, isOwner: false);
        _prefs.setFamilyIds({...await _prefs.getFamilyIds(), fid}.toList());
        notifyListeners();
        _wsService?.connect();
      } else if (status == 'pending') {
        final requestId = data['requestId'] as String? ?? '';
        _prefs.setPendingJoinRequestId(requestId);
        if (requestId.isNotEmpty) _pollJoinStatus(requestId);
        notifyListeners();
      }
    }
  }

  void _pollJoinStatus(String requestId) {
    _joinPollTimer?.cancel();
    _joinPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_apiService == null) return;
      final result = await _apiService!.get(
          '/api/family/join/status?requestId=$requestId&deviceId=$deviceId');
      if (!result.ok) return;
      try {
        final data = jsonDecode(result.data) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        if (status == 'approved') {
          final fid = data['familyId'] as String? ?? '';
          final code = data['code'] as String? ?? '';
          if (fid.isNotEmpty) {
            _prefs.setPendingJoinRequestId('');
            _prefs.setFamilyId(fid);
            _prefs.setFamilyCode(code);
            _prefs.setIsOwner(false);
            _currentFamily = Family(familyId: fid, code: code);
            _prefs.setFamilyIds({...await _prefs.getFamilyIds(), fid}.toList());
            _joinPollTimer?.cancel();
            notifyListeners();
            await _wsService?.connect();
            refreshMembers();
          }
        } else if (status == 'rejected') {
          _prefs.setPendingJoinRequestId('');
          _joinPollTimer?.cancel();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('join status parse error: $e');
      }
    });
  }

  Future<void> handleJoinRequest(String requestId, bool approve) async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/family/join/handle', {
      'familyId': _currentFamily!.familyId,
      'ownerDeviceId': deviceId,
      'requestId': requestId,
      'approve': approve,
    });
    _joinRequests.removeWhere((r) => r.requestId == requestId);
    notifyListeners();
    refreshMembers();
  }

  Future<void> removeMember(String targetDeviceId, bool ban) async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/family/member/remove', {
      'familyId': _currentFamily!.familyId,
      'ownerDeviceId': deviceId,
      'targetDeviceId': targetDeviceId,
      'ban': ban,
    });
    refreshMembers();
  }

  Future<void> disbandFamily() async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/family/disband', {
      'familyId': _currentFamily!.familyId,
      'ownerDeviceId': deviceId,
    });
    _locationService?.stop();
    _prefs.setFamilyId('');
    _members.clear();
    _currentFamily = null;
    notifyListeners();
    _wsService?.disconnect();
  }

  Future<void> requestLocation(String targetDeviceId) async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/location/request', {
      'familyId': _currentFamily!.familyId,
      'requesterId': deviceId,
      'targetDeviceId': targetDeviceId,
    });
  }

  Future<void> requestRing(String targetDeviceId, String name) async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/ring/request', {
      'familyId': _currentFamily!.familyId,
      'requesterId': deviceId,
      'targetDeviceId': targetDeviceId,
      'name': name,
    });
  }

  Future<void> setOfflineMode(bool offline) async {
    if (_apiService == null || _currentFamily == null) return;
    await _apiService!.post('/api/member/offline', {
      'familyId': _currentFamily!.familyId,
      'deviceId': deviceId,
      'offline': offline,
    });
    _prefs.setOfflineMode(offline);
    if (offline) {
      _locationService?.stop();
    } else {
      await _locationService?.start();
    }
    notifyListeners();
  }

  List<TrackPoint> _appendTrackPoint(Member member, TrackPoint point) {
    final points = member.trajectory;
    if (points.isNotEmpty && points.last.ts == point.ts) return points;
    final next = [...points, point];
    return next.length > 300 ? next.sublist(next.length - 300) : next;
  }

  Future<bool> setMemberTrack(
      String targetDeviceId, bool track, int intervalMs) async {
    if (_apiService == null || _currentFamily == null) return false;
    final result = await _apiService!.post('/api/member/track', {
      'familyId': _currentFamily!.familyId,
      'ownerDeviceId': deviceId,
      'targetDeviceId': targetDeviceId,
      'track': track,
      'intervalMs': intervalMs,
    });
    if (!result.ok) return false;
    final idx = _members.indexWhere((m) => m.deviceId == targetDeviceId);
    if (idx >= 0) {
      _members[idx] = _members[idx].copyWith(
        track: track,
        trackIntervalMs: intervalMs,
        trajectory: track ? null : const [],
      );
    }
    if (targetDeviceId == deviceId) {
      _prefs.setTrackEnabled(track);
      _prefs.setTrackIntervalMs(intervalMs);
      await _locationService?.updateInterval();
    }
    notifyListeners();
    refreshMembers();
    return true;
  }

  Future<bool> setTrackEnabled(bool track, int intervalMs) =>
      setMemberTrack(deviceId, track, intervalMs);

  void dispose() {
    _joinPollTimer?.cancel();
    _statusTimer?.cancel();
    _wsService?.dispose();
    super.dispose();
  }
}
