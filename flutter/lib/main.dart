import 'dart:async';
import 'dart:ui';

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
import '../src/theme/app_theme.dart';
import '../src/utils/boot_log.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  _installErrorLogging();
  bootLog('Dart', 'main() entered');

  try {
    await _bootStep(
      'LiquidGlass',
      () => LiquidGlassWidgets.initialize(enablePerformanceMonitor: false),
    );
    await _bootStep('AppConfig', AppConfig.init);
    await _bootStep('PrefsService', PrefsService.init);

    final prefs = PrefsService();
    final hasStoredDeviceId = prefs.deviceId.isNotEmpty;
    if (!hasStoredDeviceId) {
      final id = const Uuid().v4();
      prefs.setDeviceId(id);
      AppConfig.setDeviceId(id);
    } else {
      AppConfig.setDeviceId(prefs.deviceId);
    }
    bootLog(
      'Dart',
      'preferences ready; storedDevice=$hasStoredDeviceId, '
          'storedFamily=${prefs.familyId.isNotEmpty}',
    );

    bootLog('Dart', 'calling runApp()');
    runApp(
      LiquidGlassWidgets.wrap(
        child: const FamilyShareApp(),
        brightnessResolver: Theme.maybeBrightnessOf,
        adaptiveQuality: true,
        theme: FamilyShareTheme.glassTheme,
      ),
    );
    binding.addPostFrameCallback((_) {
      bootLog('Flutter', 'first frame built');
    });
    unawaited(binding.waitUntilFirstFrameRasterized.then((_) {
      bootLog('Flutter', 'first frame rasterized');
    }));
  } catch (error, stackTrace) {
    bootLog(
      'Dart',
      'startup failed before runApp completed',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(_BootFailureApp(error: error));
  }
}

Future<T> _bootStep<T>(String name, Future<T> Function() action) async {
  final timer = Stopwatch()..start();
  bootLog(name, 'initialization started');
  try {
    final result = await action();
    bootLog(
        name, 'initialization completed in ${timer.elapsedMilliseconds} ms');
    return result;
  } catch (error, stackTrace) {
    bootLog(
      name,
      'initialization failed after ${timer.elapsedMilliseconds} ms',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _installErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    bootLog(
      'FlutterError',
      details.context?.toDescription() ?? 'uncaught framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    bootLog(
      'PlatformDispatcher',
      'uncaught asynchronous error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
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
    bootLog('App', 'FamilyShareApp.initState');
    _initServices();
  }

  void _initServices() {
    try {
      bootLog('Services', 'creating service graph');
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

      unawaited(_initializeAppProvider());
      _ready = true;
      bootLog('Services', 'service graph ready');
    } catch (error, stackTrace) {
      bootLog(
        'Services',
        'service graph creation failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _initializeAppProvider() async {
    bootLog('AppProvider', 'initialize() started');
    try {
      await _app.initialize();
      bootLog('AppProvider', 'initialize() completed');
    } catch (error, stackTrace) {
      bootLog(
        'AppProvider',
        'initialize() failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _app),
        ChangeNotifierProvider.value(value: _mapProvider),
        ChangeNotifierProvider.value(value: _uiProvider),
      ],
      child: Consumer<UiProvider>(
        builder: (_, ui, __) => MaterialApp(
          title: '家庭共享',
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: FamilyShareTheme.light(),
          darkTheme: FamilyShareTheme.dark(),
          themeMode: ui.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 320),
          themeAnimationCurve: Curves.easeOutCubic,
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
      bootLog('Route', 'opening setup screen');
      return const SetupScreen();
    }
    bootLog('Route', 'opening home screen');
    return const HomeScreen();
  }
}

class _BootFailureApp extends StatelessWidget {
  final Object error;

  const _BootFailureApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 52),
                  const SizedBox(height: 16),
                  const Text(
                    '启动失败',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '请在调试控制台中筛选 FamilyShareBoot 查看原因。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
