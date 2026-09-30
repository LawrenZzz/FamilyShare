import 'package:flutter/material.dart';

import '../src/config/app_config.dart';
import '../src/models/member.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 40});

  final Member member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: _color(member.deviceId),
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (member.avatar.isEmpty) return fallback;
    final path = Uri.parse(member.avatar);
    final url = path.hasScheme
        ? member.avatar
        : Uri.parse('${AppConfig.serverUrl}/')
            .resolve(member.avatar)
            .toString();
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image.network(
          url,
          headers: {'X-Api-Token': AppConfig.apiToken},
          fit: BoxFit.cover,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : fallback,
        ),
      ),
    );
  }

  Color _color(String id) {
    const colors = [
      Color(0xFF0F766E),
      Color(0xFF3563C7),
      Color(0xFFC45543),
      Color(0xFF8E58A8),
      Color(0xFFBE871F),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
