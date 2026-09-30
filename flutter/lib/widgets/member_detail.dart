import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/models/member.dart';

class MemberDetailScreen extends StatelessWidget {
  final String deviceId;
  final VoidCallback onClose;

  const MemberDetailScreen({
    super.key,
    required this.deviceId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final member = app.members.firstWhere(
      (m) => m.deviceId == deviceId,
      orElse: () => Member(deviceId: deviceId),
    );

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, member),
                      const Divider(),
                      _infoRow(Icons.battery_full, '电量',
                          '${member.battery >= 0 ? "${member.battery}%" : "暂无"}'),
                      _infoRow(Icons.wifi, '网络',
                          member.network.isNotEmpty ? member.network : '暂无'),
                      _infoRow(
                          Icons.location_on,
                          '位置',
                          member.hasLocation
                              ? '${member.lat.toStringAsFixed(4)}, ${member.lng.toStringAsFixed(4)}'
                              : '暂无'),
                      _infoRow(
                          Icons.gps_fixed,
                          '定位精度',
                          member.hasLocation
                              ? '${member.accuracy.toInt()}m'
                              : '暂无'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                app.requestLocation(deviceId);
                                onClose();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('刷新位置'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                app.requestRing(deviceId, app.deviceName);
                                onClose();
                              },
                              icon: const Icon(Icons.notifications),
                              label: const Text('设备响铃'),
                            ),
                          ),
                        ],
                      ),
                      if (app.isOwner) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showRemoveDialog(context, member),
                          icon: const Icon(Icons.delete),
                          label: const Text('移除成员'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: onClose,
                        child: const Text('关闭'),
                      ),
                    ],
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          member.online ? const Color(0xFF4ADE80) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    member.online ? (member.offlineMode ? '离线模式' : '在线') : '离线',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (member.isOwner) ...[
                    const SizedBox(width: 8),
                    const Chip(
                      label: Text('群主', style: TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, Member member) {
    showDialog(
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
      Color(0xFFFFEAA7),
      Color(0xFFDDA0DD),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
