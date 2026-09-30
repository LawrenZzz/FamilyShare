import 'dart:convert';

class TrackPoint {
  final double lat;
  final double lng;
  final double accuracy;
  final int ts;
  final String address;

  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.ts,
    required this.address,
  });

  factory TrackPoint.fromJson(Map<String, dynamic> value) => TrackPoint(
        lat: (value['lat'] as num?)?.toDouble() ?? 0,
        lng: (value['lng'] as num?)?.toDouble() ?? 0,
        accuracy: (value['accuracy'] as num?)?.toDouble() ?? 0,
        ts: (value['ts'] as num?)?.toInt() ?? 0,
        address: value['address'] as String? ?? '',
      );

  Map<String, double> get mapPoint => {'lat': lat, 'lng': lng};
}

class Member {
  final String deviceId;
  String name;
  bool online;
  bool offlineMode;
  bool isOwner;
  bool track;
  int trackIntervalMs;
  bool hasLocation;
  double lat;
  double lng;
  double accuracy;
  int ts;
  int battery;
  String network;
  String address;
  String avatar;
  List<TrackPoint> trajectory;

  Member({
    required this.deviceId,
    this.name = '',
    this.online = false,
    this.offlineMode = false,
    this.isOwner = false,
    this.track = false,
    this.trackIntervalMs = 300000,
    this.hasLocation = false,
    this.lat = 0,
    this.lng = 0,
    this.accuracy = 0,
    this.ts = 0,
    this.battery = -1,
    this.network = '',
    this.address = '',
    this.avatar = '',
    this.trajectory = const [],
  });

  Member copyWith({
    String? name,
    bool? online,
    bool? offlineMode,
    bool? isOwner,
    bool? track,
    int? trackIntervalMs,
    bool? hasLocation,
    double? lat,
    double? lng,
    double? accuracy,
    int? ts,
    int? battery,
    String? network,
    String? address,
    String? avatar,
    List<TrackPoint>? trajectory,
  }) {
    return Member(
      deviceId: deviceId,
      name: name ?? this.name,
      online: online ?? this.online,
      offlineMode: offlineMode ?? this.offlineMode,
      isOwner: isOwner ?? this.isOwner,
      track: track ?? this.track,
      trackIntervalMs: trackIntervalMs ?? this.trackIntervalMs,
      hasLocation: hasLocation ?? this.hasLocation,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracy: accuracy ?? this.accuracy,
      ts: ts ?? this.ts,
      battery: battery ?? this.battery,
      network: network ?? this.network,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      trajectory: trajectory ?? this.trajectory,
    );
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    // The members endpoint wraps location in `location`, while WebSocket
    // location-update messages put the same fields at the top level.
    final rawLocation = json['location'];
    final loc =
        rawLocation is Map ? Map<String, dynamic>.from(rawLocation) : json;
    final rawTrajectory = json['trajectory'];
    final traj = rawTrajectory is List ? rawTrajectory : const <dynamic>[];
    final storedInterval = (json['trackInterval'] as num?)?.toInt() ?? 0;
    return Member(
      deviceId: json['deviceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      online: json['online'] as bool? ?? false,
      offlineMode: json['offlineMode'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
      track: json['track'] as bool? ?? false,
      trackIntervalMs: storedInterval > 0 ? storedInterval : 300000,
      hasLocation: loc['lat'] != null,
      lat: (loc['lat'] as num?)?.toDouble() ?? 0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0,
      accuracy: (loc['accuracy'] as num?)?.toDouble() ?? 0,
      ts: (loc['ts'] as num?)?.toInt() ?? 0,
      battery: (loc['battery'] as num?)?.toInt() ?? -1,
      network: loc['network'] as String? ?? '',
      address: loc['address'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      trajectory: traj
          .whereType<Map>()
          .map((p) => TrackPoint.fromJson(Map<String, dynamic>.from(p)))
          .where((p) => p.lat != 0 || p.lng != 0)
          .toList(),
    );
  }

  static List<Member> fromJsonList(String body) {
    final list = jsonDecode(body) as List;
    return list.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }
}
