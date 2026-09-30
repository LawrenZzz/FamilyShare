import 'package:flutter/material.dart';

import '../src/services/permission_service.dart';

class PermissionGuide extends StatefulWidget {
  const PermissionGuide({super.key});

  @override
  State<PermissionGuide> createState() => _PermissionGuideState();
}

class _PermissionGuideState extends State<PermissionGuide>
    with WidgetsBindingObserver {
  final _service = PermissionService();
  PermissionSnapshot? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await _service.snapshot();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      debugPrint('Permission status failed: $error');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      debugPrint('Permission action failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开系统设置：$error')),
        );
      }
    } finally {
      await _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('位置共享所需权限',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _row(
            Icons.my_location_rounded,
            '精确定位',
            '地图和位置上报',
            status.preciseLocation,
            () => _run(_service.requestPreciseLocation)),
        _row(
            Icons.location_history_rounded,
            '始终允许定位',
            '切换到其他应用后继续共享',
            status.backgroundLocation,
            () => _run(_service.requestBackgroundLocation)),
        _row(Icons.notifications_rounded, '通知', '显示持续定位通知',
            status.notifications, () => _run(_service.requestNotifications)),
        _row(
            Icons.battery_saver_rounded,
            '电池无限制',
            '减少系统中断后台定位',
            status.batteryUnrestricted,
            () => _run(_service.openBatterySettings)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restart_alt_rounded),
          title: const Text('允许自启动'),
          subtitle: const Text('在厂商设置中手动确认；系统无法读取此开关状态'),
          trailing: TextButton(
            onPressed:
                _busy ? null : () => _run(_service.openAutoStartSettings),
            child: const Text('去设置'),
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新检查'),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String title, String subtitle, bool granted,
      VoidCallback action) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: granted
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : TextButton(
              onPressed: _busy ? null : action,
              child: const Text('去设置'),
            ),
    );
  }
}
