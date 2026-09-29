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
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: app.members.length,
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
          Text('No members yet', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 4),
          Text('Create or join a family to start sharing',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
