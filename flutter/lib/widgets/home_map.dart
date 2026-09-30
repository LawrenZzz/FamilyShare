import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../src/models/member.dart';
import '../src/providers/app_provider.dart';
import '../src/providers/ui_provider.dart';

const _mapChannel = MethodChannel('familyshare/map');

Future<void> recenterFamilyMap() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _mapChannel.invokeMethod('recenter');
  } on MissingPluginException {
    // The preview map has no native camera to control.
  }
}

class HomeMap extends StatefulWidget {
  const HomeMap({super.key});

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  String _lastSignature = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, app, __) {
        final signature = app.members
            .map((m) => '${m.deviceId}:${m.lat}:${m.lng}:${m.name}')
            .join('|');
        if (defaultTargetPlatform == TargetPlatform.android) {
          _syncNativeMarkers(app.members, signature);
          return AndroidView(
            viewType: 'familyshare/amap',
            onPlatformViewCreated: (id) {
              _lastSignature = '';
              _syncNativeMarkers(app.members, signature);
              MethodChannel('familyshare/map/$id')
                  .setMethodCallHandler((call) async {
                if (call.method == 'memberTap' &&
                    call.arguments is String &&
                    mounted) {
                  context
                      .read<UiProvider>()
                      .openDetail(call.arguments as String);
                }
              });
            },
          );
        }
        return _PreviewMap(members: app.members, selfId: app.deviceId);
      },
    );
  }

  void _syncNativeMarkers(List<Member> members, String signature) {
    if (signature == _lastSignature) return;
    _lastSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _mapChannel.invokeMethod(
            'updateMarkers',
            members
                .where((m) => m.hasLocation)
                .map((m) => {
                      'deviceId': m.deviceId,
                      'name': m.name,
                      'lat': m.lat,
                      'lng': m.lng,
                      'address': m.address,
                    })
                .toList());
      } on MissingPluginException {
        // The preview remains available on non-Android targets.
      } on PlatformException catch (e) {
        debugPrint('Map update failed: ${e.message}');
      }
    });
  }
}

class _PreviewMap extends StatelessWidget {
  final List<Member> members;
  final String selfId;

  const _PreviewMap({required this.members, required this.selfId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF5F5), Color(0xFFDCE9ED)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
          if (members.where((m) => m.hasLocation).isEmpty)
            const Center(
              child: Text('开启定位后即可查看家庭地图',
                  style: TextStyle(color: Color(0xFF64748B))),
            )
          else
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final located = members.where((m) => m.hasLocation).toList();
                  final minLat =
                      located.map((m) => m.lat).reduce((a, b) => a < b ? a : b);
                  final maxLat =
                      located.map((m) => m.lat).reduce((a, b) => a > b ? a : b);
                  final minLng =
                      located.map((m) => m.lng).reduce((a, b) => a < b ? a : b);
                  final maxLng =
                      located.map((m) => m.lng).reduce((a, b) => a > b ? a : b);
                  final latRange =
                      (maxLat - minLat).abs() < 0.0001 ? 0.01 : maxLat - minLat;
                  final lngRange =
                      (maxLng - minLng).abs() < 0.0001 ? 0.01 : maxLng - minLng;
                  return Stack(
                    children: located.map((m) {
                      final x = 32 +
                          ((m.lng - minLng) / lngRange) *
                              (constraints.maxWidth - 64);
                      final y = 72 +
                          ((maxLat - m.lat) / latRange) *
                              (constraints.maxHeight - 144)
                                  .clamp(80, double.infinity)
                                  .toDouble();
                      return Positioned(
                          left: x - 22,
                          top: y - 22,
                          child: _PreviewMarker(
                              member: m, self: m.deviceId == selfId));
                    }).toList(),
                  );
                },
              ),
            ),
          Positioned(
            left: 18,
            top: MediaQuery.paddingOf(context).top + 78,
            child: const _MapLegend(),
          ),
        ],
      ),
    );
  }
}

class _PreviewMarker extends StatelessWidget {
  final Member member;
  final bool self;

  const _PreviewMarker({required this.member, required this.self});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: self ? const Color(0xFF3563E9) : const Color(0xFF0D9488),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 8)
            ],
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
                child: Text(
                    member.name.isEmpty
                        ? '?'
                        : member.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700))),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 4)
              ]),
          child: Text(member.name.isEmpty ? '家庭成员' : member.name,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.my_location, size: 14, color: Color(0xFF3563E9)),
          SizedBox(width: 5),
          Text('家庭实时位置',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x335B8C94)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 78) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    for (var y = 22.0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
