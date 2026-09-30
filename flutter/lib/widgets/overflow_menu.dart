import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import '../src/services/prefs_service.dart';
import '../src/theme/app_theme.dart';

class OverflowMenu extends StatelessWidget {
  const OverflowMenu({super.key});

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    final overNativeMap =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return GlassModalSheet.show<void>(
      context: context,
      initialState: GlassSheetState.half,
      halfSize: 0.78,
      fullSize: 0.92,
      quality: GlassQuality.premium,
      settings: FamilyShareTheme.overlayGlassSettings(context),
      expandedColor: theme.colorScheme.surface,
      platformViewBackdrop: overNativeMap,
      barrierColor: theme.colorScheme.scrim.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.5 : 0.26,
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 1,
        child: _MoreActionsSheet(parentContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overNativeMap =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return GlassIconButton(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => show(context),
      semanticLabel: '更多功能',
      useOwnLayer: true,
      settings: FamilyShareTheme.mapGlassSettings(context),
      quality: GlassQuality.premium,
      platformViewBackdrop: overNativeMap,
    );
  }
}

class _MoreActionsSheet extends StatelessWidget {
  const _MoreActionsSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ui = context.watch<UiProvider>();
    final prefs = PrefsService();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '更多功能',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              _tile(
                context,
                icon:
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: '深色模式',
                subtitle: isDark ? '已使用深色外观' : '当前使用浅色外观',
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (value) {
                    ui.setDarkMode(value);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  ui.setDarkMode(!isDark);
                  Navigator.pop(context);
                },
              ),
              _tile(
                context,
                icon: Icons.key_rounded,
                title: '家庭码',
                subtitle: '查看并复制家庭邀请码',
                onTap: () => _open(context, _showFamilyCode),
              ),
              _tile(
                context,
                icon: Icons.swap_horiz_rounded,
                title: '切换家庭',
                subtitle: '查看当前家庭或创建、加入家庭',
                onTap: () => _open(context, _showSwitchFamily),
              ),
              _tile(
                context,
                icon: Icons.dns_rounded,
                title: '服务器',
                subtitle: '更改家庭共享服务器地址',
                onTap: () => _open(context, _showChangeServer),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off_rounded),
                title: const Text('离线模式'),
                subtitle: const Text('暂停上传当前位置'),
                value: prefs.offlineMode,
                onChanged: (value) async {
                  await app.setOfflineMode(value);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              _tile(
                context,
                icon: Icons.timeline_rounded,
                title: '位置追踪',
                subtitle: '设置持续定位和上报频率',
                onTap: () => _open(context, _showTrackOptions),
              ),
              _tile(
                context,
                icon: Icons.notifications_rounded,
                title: '消息',
                subtitle: app.joinRequests.isEmpty
                    ? '暂无新的家庭申请'
                    : '${app.joinRequests.length} 条待处理申请',
                onTap: () => _open(context, _showMessages),
              ),
              _tile(
                context,
                icon: Icons.settings_rounded,
                title: '设置',
                subtitle: '外观、离线模式和响铃偏好',
                onTap: () => _open(context, _showSettings),
              ),
              if (app.isOwner)
                _tile(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: '解散家庭',
                  subtitle: '移除所有成员并结束家庭共享',
                  color: Theme.of(context).colorScheme.error,
                  onTap: () => _open(context, _showDisbandDialog),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: scheme.surfaceContainerHigh.withValues(alpha: 0.58),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color == null
                ? scheme.primaryContainer.withValues(alpha: 0.78)
                : scheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 21,
            color: color == null ? scheme.onPrimaryContainer : scheme.error,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  void _open(
    BuildContext sheetContext,
    void Function(BuildContext) openDialog,
  ) {
    Navigator.pop(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parentContext.mounted) openDialog(parentContext);
    });
  }

  void _showFamilyCode(BuildContext context) {
    final code = PrefsService().familyCode;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('家庭码'),
        content: SelectableText(code.isEmpty ? '暂无可用的家庭码' : code),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton.tonalIcon(
            onPressed: code.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('家庭码已复制')),
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _showSwitchFamily(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const SwitchFamilyDialog(),
    );
  }

  void _showChangeServer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const ChangeServerDialog(),
    );
  }

  void _showTrackOptions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const TrackOptionsDialog(),
    );
  }

  void _showMessages(BuildContext context) {
    final app = context.read<AppProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('家庭消息'),
        content: app.joinRequests.isEmpty
            ? const Text('暂无消息')
            : SizedBox(
                width: 420,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: app.joinRequests.length,
                  itemBuilder: (_, index) {
                    final request = app.joinRequests[index];
                    return ListTile(
                      title: Text('${request.name} 申请加入家庭'),
                      subtitle: Text(request.deviceId),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '同意',
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              app.handleJoinRequest(request.requestId, true);
                              Navigator.pop(context);
                            },
                          ),
                          IconButton(
                            tooltip: '拒绝',
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              app.handleJoinRequest(request.requestId, false);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _SettingsDialog(),
    );
  }

  void _showDisbandDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确定解散家庭？'),
        content: const Text('解散后，所有成员都将无法继续访问这个家庭。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().disbandFamily();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/setup');
              }
            },
            child: const Text('解散家庭'),
          ),
        ],
      ),
    );
  }
}

class SwitchFamilyDialog extends StatelessWidget {
  const SwitchFamilyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return AlertDialog(
      title: const Text('切换家庭'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (app.currentFamily != null)
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: Text('家庭码 ${app.currentFamily!.code}'),
              subtitle: Text('${app.members.length} 位成员'),
              trailing: const Text('当前'),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/setup');
          },
          child: const Text('创建或加入'),
        ),
      ],
    );
  }
}

class ChangeServerDialog extends StatefulWidget {
  const ChangeServerDialog({super.key});

  @override
  State<ChangeServerDialog> createState() => _ChangeServerDialogState();
}

class _ChangeServerDialogState extends State<ChangeServerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更改服务器'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: '服务器地址',
          hintText: 'https://example.com',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final url = _controller.text.trim();
            if (url.isNotEmpty) {
              context.read<AppProvider>().changeServer(url);
              Navigator.pop(context);
            }
          },
          child: const Text('应用'),
        ),
      ],
    );
  }
}

class TrackOptionsDialog extends StatefulWidget {
  const TrackOptionsDialog({super.key});

  @override
  State<TrackOptionsDialog> createState() => _TrackOptionsDialogState();
}

class _TrackOptionsDialogState extends State<TrackOptionsDialog> {
  late bool _enabled;
  late int _selectedInterval;

  @override
  void initState() {
    super.initState();
    final prefs = PrefsService();
    _enabled = prefs.trackEnabled;
    _selectedInterval = (prefs.trackIntervalMs / 60000).round().clamp(1, 15);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return AlertDialog(
      title: const Text('位置追踪'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用持续追踪'),
            value: _enabled,
            onChanged: (value) {
              setState(() => _enabled = value);
              app.setTrackEnabled(value, _selectedInterval * 60 * 1000);
            },
          ),
          const SizedBox(height: 12),
          const Text('位置上报间隔'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 3, 5, 10, 15].map((minutes) {
              return ChoiceChip(
                label: Text('$minutes 分钟'),
                selected: _selectedInterval == minutes,
                onSelected: (_) {
                  setState(() {
                    _selectedInterval = minutes;
                    _enabled = true;
                  });
                  app.setTrackEnabled(true, minutes * 60 * 1000);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool _offline;
  late bool _ringEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = PrefsService();
    _offline = prefs.offlineMode;
    _ringEnabled = prefs.ringEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassDialog(
      title: '设置',
      maxWidth: 380,
      settings: FamilyShareTheme.overlayGlassSettings(context),
      quality: GlassQuality.premium,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            ),
            title: const Text('深色模式'),
            subtitle: Text(isDark ? '减少夜间屏幕亮度' : '使用明亮清晰的界面'),
            value: isDark,
            onChanged: ui.setDarkMode,
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.visibility_off_rounded),
            title: const Text('离线模式'),
            subtitle: const Text('暂停上传当前位置'),
            value: _offline,
            onChanged: (value) {
              setState(() => _offline = value);
              context.read<AppProvider>().setOfflineMode(value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('允许设备响铃'),
            value: _ringEnabled,
            onChanged: (value) {
              setState(() => _ringEnabled = value);
              PrefsService().setRingEnabled(value);
            },
          ),
        ],
      ),
      actions: [
        GlassDialogAction(
          label: '完成',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
