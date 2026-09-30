import 'package:flutter/material.dart';
import '../src/models/member.dart';
import 'member_avatar.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = scheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.9)
          : scheme.surfaceContainerLowest.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: MemberAvatar(member: member),
        title: Text(
          '${member.name.isNotEmpty ? member.name : member.deviceId}${isSelf ? '（我）' : ''}',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
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
                            ? secondaryText
                            : const Color(0xFF22C55E))
                        : secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  member.online ? (member.offlineMode ? '离线模式' : '在线') : '离线',
                  style: TextStyle(fontSize: 12, color: secondaryText),
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
              style: TextStyle(fontSize: 12, color: secondaryText),
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
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isOwner)
              Chip(
                label: const Text('群主', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                backgroundColor: scheme.primaryContainer,
                side: BorderSide.none,
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: secondaryText,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _batteryColor(int battery) {
    if (battery >= 80) return const Color(0xFF4ADE80);
    if (battery >= 20) return Colors.yellow;
    return Colors.red;
  }
}
