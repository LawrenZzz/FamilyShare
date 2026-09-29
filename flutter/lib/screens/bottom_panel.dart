import 'package:flutter/material.dart';

import '../widgets/bottom_panel.dart' as widgets;

/// Backwards-compatible import for callers that still use the old screen path.
/// The implementation lives in `widgets/bottom_panel.dart`.
class BottomPanel extends StatelessWidget {
  /// Retained for source compatibility with the former component API.
  final bool? collapsed;
  final VoidCallback? onToggle;
  final int? memberCount;

  const BottomPanel({
    super.key,
    this.collapsed,
    this.onToggle,
    this.memberCount,
  });

  @override
  Widget build(BuildContext context) => const widgets.BottomPanel();
}
