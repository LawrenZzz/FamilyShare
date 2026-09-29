import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/services/prefs_service.dart';

class OverflowMenu extends StatelessWidget {
  const OverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'code', child: Text('Family Code')),
        const PopupMenuItem(value: 'switch', child: Text('Switch Family')),
        const PopupMenuItem(value: 'server', child: Text('Change Server')),
        PopupMenuItem(
          value: 'offline',
          child: Row(
            children: [
              const Text('Offline Mode'),
              Switch(
                value: PrefsService().offlineMode,
                onChanged: (v) => app.setOfflineMode(v),
              ),
            ],
          ),
        ),
        const PopupMenuItem(value: 'track', child: Text('Track Location')),
        const PopupMenuItem(value: 'message', child: Text('Messages')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        if (app.isOwner)
          const PopupMenuItem(value: 'disband', child: Text('Disband Family')),
      ],
      onSelected: (value) => _handleMenu(context, value),
    );
  }

  void _handleMenu(BuildContext context, String value) {
    switch (value) {
      case 'code':
        _showFamilyCode(context);
        break;
      case 'switch':
        _showSwitchFamily(context);
        break;
      case 'server':
        _showChangeServer(context);
        break;
      case 'track':
        _showTrackOptions(context);
        break;
      case 'message':
        _showMessages(context);
        break;
      case 'settings':
        _showSettings(context);
        break;
      case 'disband':
        _showDisbandDialog(context);
        break;
    }
  }

  void _showFamilyCode(BuildContext context) {
    final code = PrefsService().familyCode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Family Code'),
        content: Text(code.isEmpty ? 'No code available' : code),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showSwitchFamily(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SwitchFamilyDialog(),
    );
  }

  void _showChangeServer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChangeServerDialog(),
    );
  }

  void _showTrackOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TrackOptionsDialog(),
    );
  }

  void _showMessages(BuildContext context) {
    final app = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Messages'),
        content: app.joinRequests.isEmpty
            ? const Text('No messages')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: app.joinRequests.length,
                itemBuilder: (_, idx) {
                  final req = app.joinRequests[idx];
                  return ListTile(
                    title: Text('Join request from ${req.name}'),
                    subtitle: Text(req.deviceId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            app.handleJoinRequest(req.requestId, true);
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            app.handleJoinRequest(req.requestId, false);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Offline Mode'),
              value: PrefsService().offlineMode,
              onChanged: (v) {
                context.read<AppProvider>().setOfflineMode(v);
              },
            ),
            SwitchListTile(
              title: const Text('Ring Enabled'),
              value: PrefsService().ringEnabled,
              onChanged: (v) {
                final prefs = PrefsService();
                prefs.setRingEnabled(v);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDisbandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disband family?'),
        content: const Text('All members will lose access to this family.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().disbandFamily();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/setup');
              }
            },
            child: const Text('Disband'),
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
      title: const Text('Switch Family'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (app.currentFamily != null)
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(app.currentFamily!.code),
              subtitle: Text('${app.members.length} members'),
              trailing: const Text('Current'),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/setup');
          },
          child: const Text('Create/Join'),
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
      title: const Text('Change Server'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Server URL',
          hintText: 'https://example.com',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final url = _controller.text.trim();
            if (url.isNotEmpty) {
              context.read<AppProvider>().changeServer(url);
              Navigator.pop(context);
            }
          },
          child: const Text('Apply'),
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
  int _selectedInterval = 5;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return AlertDialog(
      title: const Text('Track Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enable Tracking'),
            value: PrefsService().trackEnabled,
            onChanged: (v) {
              app.setTrackEnabled(v, _selectedInterval * 60 * 1000);
            },
          ),
          const SizedBox(height: 16),
          const Text('Interval:'),
          Wrap(
            spacing: 8,
            children: [1, 3, 5, 10, 15].map((m) {
              return ChoiceChip(
                label: Text('$m min'),
                selected: _selectedInterval == m,
                onSelected: (sel) {
                  setState(() => _selectedInterval = m);
                  app.setTrackEnabled(true, m * 60 * 1000);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
