export 'member.dart';

class Family {
  final String familyId;
  final String code;
  final String name;
  final bool isOwner;
  final int memberCount;

  const Family({
    required this.familyId,
    this.code = '',
    this.name = '',
    this.isOwner = false,
    this.memberCount = 0,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      familyId: json['familyId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isOwner: json['isOwner'] as bool? ?? false,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class JoinRequest {
  final String requestId;
  final String deviceId;
  final String name;
  final int ts;

  const JoinRequest({
    required this.requestId,
    required this.deviceId,
    required this.name,
    required this.ts,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['requestId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
    );
  }
}
