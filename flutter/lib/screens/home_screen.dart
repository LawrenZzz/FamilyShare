import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';
import '../widgets/home_map.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/member_detail.dart';
import '../widgets/overflow_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppProvider? _app;
  bool _redirecting = false;

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
    return Scaffold(
      body: Stack(
        children: [
          const HomeMap(),
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
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: MemberDetailScreen(
                  deviceId: ui.selectedDeviceId!,
                  onClose: ui.closeDetail,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, app, __) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.currentFamily?.code ?? 'FamilyShare',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: app.status == 'online'
                              ? const Color(0xFF4ADE80)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${app.members.length} members',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      app.refreshMembers();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {
                      app.locateMe().then((_) => recenterFamilyMap());
                    },
                  ),
                  const OverflowMenu(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
