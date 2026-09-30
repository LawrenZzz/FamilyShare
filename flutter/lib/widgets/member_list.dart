import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import 'member_card.dart';

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
              onTap: () =>
                  context.read<UiProvider>().openDetail(member.deviceId),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('还没有家庭成员', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 4),
          Text('邀请家人加入后即可共享位置',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
