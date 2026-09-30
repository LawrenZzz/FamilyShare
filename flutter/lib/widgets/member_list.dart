import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import 'member_card.dart';
import 'home_map.dart';

class MemberList extends StatelessWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, app, __) {
        if (app.members.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          physics: const BouncingScrollPhysics(),
          itemCount: app.members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, idx) {
            final member = app.members[idx];
            return MemberCard(
              member: member,
              isSelf: member.deviceId == app.deviceId,
              onTap: () {
                focusFamilyMember(member.deviceId);
                final ui = context.read<UiProvider>();
                if (ui.trajectoryDeviceId != member.deviceId) {
                  ui.clearTrajectory();
                }
                ui.openDetail(member.deviceId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: color),
          const SizedBox(height: 8),
          Text('还没有家庭成员', style: TextStyle(color: color)),
          const SizedBox(height: 4),
          Text('邀请家人加入后即可共享位置', style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
