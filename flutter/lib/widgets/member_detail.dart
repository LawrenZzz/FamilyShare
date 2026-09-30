import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../src/models/member.dart';
import '../src/providers/app_provider.dart';
import '../src/theme/app_theme.dart';

class MemberDetailScreen extends StatelessWidget {
  final String deviceId;
  final VoidCallback onClose;

  const MemberDetailScreen({
    super.key,
    required this.deviceId,
    required this.onClose,
  });

  bool get _overNativeMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final member = app.members.firstWhere(
      (m) => m.deviceId == deviceId,
      orElse: () => Member(deviceId: deviceId),
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: scheme.scrim.withValues(alpha: isDark ? 0.58 : 0.32),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 8),
                    settings: FamilyShareTheme.overlayGlassSettings(context),
                    quality: GlassQuality.premium,
                    useOwnLayer: true,
                    platformViewBackdrop: _overNativeMap,
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, member),
                          const SizedBox(height: 14),
                          Divider(color: scheme.outlineVariant),
                          const SizedBox(height: 4),
                          _infoRow(
                            context,
                            Icons.battery_full_rounded,
                            '电量',
                            member.battery >= 0 ? '${member.battery}%' : '暂无',
                          ),
                          _infoRow(
                            context,
                            Icons.wifi_rounded,
                            '网络',
                            member.network.isNotEmpty ? member.network : '暂无',
                          ),
                          _infoRow(
                            context,
                            Icons.location_on_rounded,
                            '位置',
                            member.hasLocation
                                ? '${member.lat.toStringAsFixed(4)}, ${member.lng.toStringAsFixed(4)}'
                                : '暂无',
                          ),
                          _infoRow(
                            context,
                            Icons.gps_fixed_rounded,
                            '定位精度',
                            member.hasLocation
                                ? '${member.accuracy.toInt()}m'
                                : '暂无',
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    app.requestLocation(deviceId);
                                    onClose();
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('刷新位置'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    app.requestRing(deviceId, app.deviceName);
                                    onClose();
                                  },
                                  icon: const Icon(Icons.notifications_rounded),
                                  label: const Text('设备响铃'),
                                ),
                              ),
                            ],
                          ),
                          if (app.isOwner) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.error,
                                  side: BorderSide(
                                    color: scheme.error.withValues(alpha: 0.55),
                                  ),
                                ),
                                onPressed: () =>
                                    _showRemoveDialog(context, member),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('移除成员'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Member member) {
    final scheme = Theme.of(context).colorScheme;
    final secondaryText = scheme.onSurfaceVariant;
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: _color(member.deviceId),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name.isNotEmpty ? member.name : member.deviceId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: member.online
                              ? const Color(0xFF22C55E)
                              : secondaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        member.online
                            ? (member.offlineMode ? '离线模式' : '在线')
                            : '离线',
                        style: TextStyle(color: secondaryText),
                      ),
                    ],
                  ),
                  if (member.isOwner)
                    Chip(
                      label: const Text('群主', style: TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '关闭',
          color: scheme.onSurface,
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 19, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, Member member) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('移除家庭成员'),
        content: Text(
          '确定将 ${member.name.isEmpty ? member.deviceId : member.name} 移出家庭吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeMember(member.deviceId, false);
              Navigator.pop(context);
              onClose();
            },
            child: const Text('移除'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeMember(member.deviceId, true);
              Navigator.pop(context);
              onClose();
            },
            child: const Text('移除并禁止再次加入'),
          ),
        ],
      ),
    );
  }

  Color _color(String id) {
    final colors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFF45B7D1),
      Color(0xFF96CEB4),
      Color(0xFFF6C453),
      Color(0xFFDDA0DD),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
