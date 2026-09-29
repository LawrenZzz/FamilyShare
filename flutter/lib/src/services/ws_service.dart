import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'api_service.dart';
import '../config/app_config.dart';
import '../providers/app_provider.dart';

class WsService {
  final AppProvider _app;
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final List<VoidCallback> _onConnectListeners = [];
  final List<VoidCallback> _onDisconnectListeners = [];
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connected = false;
  static const _maxDelay = Duration(seconds: 30);
  static const _minDelay = Duration(seconds: 2);

  WsService(ApiService _, [AppProvider? app]) : _app = app ?? AppProvider();

  bool get isConnected => _connected;

  void addConnectListener(VoidCallback cb) => _onConnectListeners.add(cb);
  void removeConnectListener(VoidCallback cb) => _onConnectListeners.remove(cb);
  void addDisconnectListener(VoidCallback cb) => _onDisconnectListeners.add(cb);
  void removeDisconnectListener(VoidCallback cb) =>
      _onDisconnectListeners.remove(cb);

  String get wsUrl => AppConfig.wsUrl;

  Future<void> connect() async {
    if (isConnected) return;
    final deviceId = AppConfig.deviceId;
    final familyId = _app.familyId;
    if (deviceId.isEmpty || familyId.isEmpty) return;
    try {
      final uri = Uri.parse(wsUrl).replace(
        queryParameters: {
          'deviceId': deviceId,
          'familyId': familyId,
          'name': AppConfig.deviceName,
          'token': AppConfig.apiToken,
        },
      );
      _channel = IOWebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      await _channel!.ready;
      _connected = true;
      _reconnectAttempt = 0;
      for (final cb in List.from(_onConnectListeners)) cb();
    } catch (e) {
      _connected = false;
      await _subscription?.cancel();
      await _channel?.sink.close();
      _subscription = null;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _connected = false;
    for (final cb in List.from(_onDisconnectListeners)) cb();
  }

  void send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  void _onMessage(dynamic data) {
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final type = map['type'] as String? ?? '';
      final payload = Map<String, dynamic>.from(map..remove('type'));
      _app.handleWsMessage(type, payload);
    } catch (e) {
      debugPrint('WS message parse error: $e');
    }
  }

  void _onError(dynamic err) {
    debugPrint('WS error: $err');
    _connected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WS closed');
    _connected = false;
    for (final cb in List.from(_onDisconnectListeners)) cb();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    final seconds = (_minDelay.inSeconds * (_reconnectAttempt.clamp(0, 4) + 1))
        .clamp(_minDelay.inSeconds, _maxDelay.inSeconds)
        .toInt();
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      connect();
    });
  }

  void dispose() {
    disconnect();
    _reconnectTimer?.cancel();
  }
}
