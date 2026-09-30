import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../src/config/app_config.dart';
import '../src/services/api_service.dart';
import '../src/services/ws_service.dart';
import '../src/services/prefs_service.dart';
import '../src/services/permission_service.dart';
import '../src/services/location_service.dart';
import '../src/providers/app_provider.dart';
import '../src/providers/map_provider.dart';
import '../src/providers/ui_provider.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  await AppConfig.init();
  await PrefsService.init();
  final prefs = PrefsService();
  if (prefs.deviceId.isEmpty) {
    AppConfig.setDeviceId(const Uuid().v4());
  } else {
    AppConfig.setDeviceId(prefs.deviceId);
  }
  runApp(
    LiquidGlassWidgets.wrap(
      child: const FamilyShareApp(),
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality: true,
      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 24,
        quality: GlassQuality.standard,
      ),
    ),
  );
}

class FamilyShareApp extends StatefulWidget {
  const FamilyShareApp({super.key});

  @override
  State<FamilyShareApp> createState() => _FamilyShareAppState();
}

class _FamilyShareAppState extends State<FamilyShareApp> {
  late final AppProvider _app;
  late final ApiService _apiService;
  late final WsService _wsService;
  late final LocationService _locationService;
  late final MapProvider _mapProvider;
  late final UiProvider _uiProvider;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() {
    _app = AppProvider();
    _apiService = ApiService(AppConfig.serverUrl, AppConfig.apiToken);
    _wsService = WsService(_apiService, _app);
    _locationService = LocationService(
      PermissionService(),
      _apiService,
      _wsService,
      _app,
    );
    _mapProvider = MapProvider();
    _uiProvider = UiProvider();

    _app
      ..setApiService(_apiService)
      ..setWsService(_wsService)
      ..setLocationService(_locationService);

    _app.initialize();

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _app),
        ChangeNotifierProvider.value(value: _mapProvider),
        ChangeNotifierProvider.value(value: _uiProvider),
      ],
      child: MaterialApp(
        title: '家庭共享',
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: _ready
            ? const _RouteChecker()
            : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
        routes: {
          '/setup': (_) => const SetupScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

class _RouteChecker extends StatelessWidget {
  const _RouteChecker();

  @override
  Widget build(BuildContext context) {
    final prefs = PrefsService();
    if (prefs.familyId.isEmpty) {
      return const SetupScreen();
    }
    return const HomeScreen();
  }
}
