import 'package:flutter/material.dart';
import '../src/models/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final bool isSelf;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.isSelf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x140F766E)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor:
              isSelf ? const Color(0xFF4A6CF7) : _color(member.deviceId),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${member.name.isNotEmpty ? member.name : member.deviceId}${isSelf ? '（我）' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: member.online
                        ? (member.offlineMode
                            ? Colors.grey
                            : const Color(0xFF4ADE80))
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  member.online ? (member.offlineMode ? '离线模式' : '在线') : '离线',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              member.hasLocation
                  ? '${member.lat.toStringAsFixed(4)}, ${member.lng.toStringAsFixed(4)}'
                  : '暂无位置信息',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (member.battery >= 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.battery_full,
                    size: 14,
                    color: _batteryColor(member.battery),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${member.battery}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: member.isOwner
            ? const Chip(
                label: Text('群主', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Color _color(String id) {
    final colors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFF45B7D1),
      Color(0xFF96CEB4),
      Color(0xFFFFEAA7),
      Color(0xFFDDA0DD),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  Color _batteryColor(int battery) {
    if (battery >= 80) return const Color(0xFF4ADE80);
    if (battery >= 20) return Colors.yellow;
    return Colors.red;
  }
}
