import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/home_map.dart';
import '../widgets/member_detail.dart';
import '../widgets/overflow_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _glassSettings = LiquidGlassSettings(
    blur: 12,
    thickness: 22,
    saturation: 1.2,
    glassColor: Color(0x38FFFFFF),
    platformViewFallbackColor: Color(0xE8FFFFFF),
  );

  AppProvider? _app;
  bool _redirecting = false;

  bool get _overNativeMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _app = app;
    app.addListener(_onAppChanged);
    app.refreshMembers();
    app.startLocationSharing();
  }

  void _onAppChanged() {
    if (!mounted || _redirecting || _app?.familyId.isNotEmpty != false) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _app?.familyId.isEmpty == true) {
        Navigator.of(context).pushReplacementNamed('/setup');
      }
    });
  }

  @override
  void dispose() {
    _app?.removeListener(_onAppChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: HomeMap()),
            _buildTopBar(context),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomPanel(),
            ),
            Consumer<UiProvider>(
              builder: (_, ui, __) {
                if (!ui.detailOpen || ui.selectedDeviceId == null) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: MemberDetailScreen(
                    deviceId: ui.selectedDeviceId!,
                    onClose: ui.closeDetail,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Consumer<AppProvider>(
          builder: (_, app, __) {
            final code = app.currentFamily?.code ?? '';
            return Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                    settings: _glassSettings,
                    quality: GlassQuality.standard,
                    useOwnLayer: true,
                    platformViewBackdrop: _overNativeMap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code.isEmpty ? '家庭共享' : '家庭码  $code',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102A2C),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: app.status == 'online'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${_statusText(app.status)} · ${app.members.length} 位成员',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF456063),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GlassButtonGroup.icons(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  settings: _glassSettings,
                  platformViewBackdrop: _overNativeMap,
                  borderRadius: 18,
                  itemPadding: const EdgeInsets.all(11),
                  iconSize: 21,
                  items: [
                    GlassButtonGroupItem(
                      icon: const Icon(Icons.sync_rounded),
                      label: '刷新家庭成员',
                      onTap: app.refreshMembers,
                    ),
                    GlassButtonGroupItem(
                      icon: const Icon(Icons.my_location_rounded),
                      label: '定位到我的位置',
                      onTap: () async {
                        await app.locateMe();
                        await recenterFamilyMap();
                      },
                    ),
                    GlassButtonGroupItem(
                      icon: const Icon(Icons.more_horiz_rounded),
                      label: '更多功能',
                      onTap: () => OverflowMenu.show(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'online':
        return '在线';
      case 'ringing':
        return '响铃中';
      case 'connecting':
        return '连接中';
      default:
        return '离线';
    }
  }
}
