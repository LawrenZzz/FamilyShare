import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import '../src/utils/boot_log.dart';
import 'member_list.dart';

class BottomPanel extends StatelessWidget {
  const BottomPanel({super.key});

  static const _glassSettings = LiquidGlassSettings(
    blur: 14,
    thickness: 24,
    saturation: 1.2,
    glassColor: Color(0x42FFFFFF),
    platformViewFallbackColor: Color(0xF0FFFFFF),
  );

  bool get _overNativeMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    if (screen.width <= 32 || screen.height <= 0) {
      bootLog(
        'Layout',
        'waiting for valid viewport metrics; size='
            '${screen.width}x${screen.height}',
      );
      return const SizedBox.shrink();
    }
    final panelHeight = (screen.height * 0.42).clamp(250.0, 380.0).toDouble();
    final buttonWidth = screen.width - 32;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Consumer2<UiProvider, AppProvider>(
        builder: (_, ui, app, __) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: ui.panelCollapsed
                ? _toggleButton(
                    context,
                    width: buttonWidth,
                    memberCount: app.members.length,
                    expanded: false,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassContainer(
                        width: buttonWidth,
                        height: panelHeight,
                        padding: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 22,
                        ),
                        settings: _glassSettings,
                        quality: GlassQuality.standard,
                        useOwnLayer: true,
                        platformViewBackdrop: _overNativeMap,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: ui.togglePanel,
                              child: SizedBox(
                                height: 58,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.family_restroom_rounded,
                                        color: Color(0xFF0F766E),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          '家庭成员',
                                          style: TextStyle(
                                            color: Color(0xFF102A2C),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${app.members.length} 位',
                                        style: const TextStyle(
                                          color: Color(0xFF5F7476),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF456063),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0x1F0F766E)),
                            const Expanded(child: MemberList()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _toggleButton(
                        context,
                        width: buttonWidth,
                        memberCount: app.members.length,
                        expanded: true,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _toggleButton(
    BuildContext context, {
    required double width,
    required int memberCount,
    required bool expanded,
  }) {
    return GlassButton.custom(
      width: width,
      height: 58,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      settings: _glassSettings,
      platformViewBackdrop: _overNativeMap,
      shape: const LiquidRoundedSuperellipse(borderRadius: 22),
      stretch: 0.12,
      label: expanded ? '收起家庭成员' : '展开家庭成员',
      onTap: context.read<UiProvider>().togglePanel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              color: Color(0xFF0F766E),
              size: 23,
            ),
            const SizedBox(width: 10),
            Text(
              expanded ? '收起家庭成员' : '家庭成员',
              style: const TextStyle(
                color: Color(0xFF102A2C),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$memberCount',
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: const Color(0xFF456063),
            ),
          ],
        ),
      ),
    );
  }
}
