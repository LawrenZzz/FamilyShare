import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:familyshare/src/config/app_config.dart';
import 'package:familyshare/src/providers/app_provider.dart';
import 'package:familyshare/src/providers/ui_provider.dart';
import 'package:familyshare/src/services/prefs_service.dart';
import 'package:familyshare/widgets/overflow_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('server remains fixed when an old saved URL exists', () async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://nas.lawlovesimone.site:37117',
    });
    await AppConfig.init();
    final prefs = await SharedPreferences.getInstance();
    expect(AppConfig.serverUrl, 'https://familyshare.lawlovesimone.site');
    expect(AppConfig.wsUrl, 'wss://familyshare.lawlovesimone.site/ws');
    expect(prefs.containsKey('server_url'), isFalse);
  });

  testWidgets('settings menu has a Material ancestor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => UiProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => OverflowMenu.show(context),
                child: const Text('打开菜单'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('我的头像'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('设置'), 200);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
