import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:familyshare/src/models/member.dart';
import 'package:familyshare/src/providers/app_provider.dart';
import 'package:familyshare/src/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses server trajectory and default interval', () {
    final member = Member.fromJson({
      'deviceId': 'a',
      'track': true,
      'trackInterval': 0,
      'location': {'lat': 31.2, 'lng': 121.4},
      'trajectory': [
        {
          'lat': 31.1,
          'lng': 121.3,
          'accuracy': 12,
          'ts': 1000,
          'address': '起点',
        },
        {'lat': 31.2, 'lng': 121.4, 'ts': 2000},
      ],
    });

    expect(member.trackIntervalMs, 300000);
    expect(member.trajectory.length, 2);
    expect(member.trajectory.first.address, '起点');
    expect(member.trajectory.last.mapPoint, {'lat': 31.2, 'lng': 121.4});
  });

  test('appends live position updates while tracking', () async {
    SharedPreferences.setMockInitialValues({'device_id': 'self'});
    await PrefsService.init();
    final app = AppProvider();
    app.handleWsMessage('location-update', {
      'deviceId': 'other',
      'lat': 31.1,
      'lng': 121.3,
      'ts': 1000,
    });
    app.handleWsMessage('track-changed', {
      'deviceId': 'other',
      'track': true,
      'intervalMs': 180000,
    });
    for (final timestamp in [2000, 2000, 3000]) {
      app.handleWsMessage('location-update', {
        'deviceId': 'other',
        'lat': 31.2,
        'lng': 121.4,
        'ts': timestamp,
      });
    }

    expect(app.members.single.trackIntervalMs, 180000);
    expect(app.members.single.trajectory.map((p) => p.ts), [2000, 3000]);
    app.dispose();
  });
}
