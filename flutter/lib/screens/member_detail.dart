import 'package:flutter/material.dart';

import '../widgets/member_detail.dart' as widgets;

/// Backwards-compatible import for callers that still use the old screen path.
/// The implementation lives in `widgets/member_detail.dart`.
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
    return widgets.MemberDetailScreen(
      deviceId: deviceId,
      onClose: onClose,
    );
  }
}
