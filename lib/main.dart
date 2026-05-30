import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app_providers.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/review_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spaced_review_screen.dart';
import 'screens/syntax_screen.dart';
import 'services/app_logger.dart';
import 'services/settings_service.dart';
import 'storage/hive_storage.dart';
import 'theme/app_theme.dart';
import 'widgets/epub_drop_importer.dart';
import 'widgets/release_notes_gate.dart';
import 'widgets/theme_transition.dart';
import 'widgets/word_mastery_confetti.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeLogging();
      _installGlobalErrorLogging();
      runApp(const FlowReadBootstrapApp());
    },
    (error, stackTrace) {
      AppLogger.instance.event(
        'zone.unhandled_error',
        level: AppLogLevel.fatal,
        source: 'main',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<void> _initializeLogging() async {
  try {
    await AppLogger.instance.init();
    AppLogger.instance.event('app.start', source: 'main');
  } catch (_) {
    // Logging must never prevent the app from opening.
  }
}

void _installGlobalErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.instance.event(
      'flutter.error',
      level: AppLogLevel.fatal,
      source: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.instance.event(
      'platform.unhandled_error',
      level: AppLogLevel.fatal,
      source: 'platform_dispatcher',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

class FlowReadBootstrapApp extends StatefulWidget {
  const FlowReadBootstrapApp({super.key});

  @override
  State<FlowReadBootstrapApp> createState() => _FlowReadBootstrapAppState();
}

class _FlowReadBootstrapAppState extends State<FlowReadBootstrapApp> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapStorageWithLogging();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = _bootstrapStorageWithLogging();
    });
  }

  Future<void> _bootstrapStorageWithLogging() async {
    AppLogger.instance.event('storage.bootstrap_started', source: 'storage');
    try {
      await bootstrapStorage();
      AppLogger.instance.event(
        'storage.bootstrap_succeeded',
        source: 'storage',
      );
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'storage.bootstrap_failed',
        level: AppLogLevel.fatal,
        source: 'storage',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const FlowReadApp();
        }

        return MaterialApp(
          title: 'Flow Read',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: StartupScreen(error: snapshot.error, onRetry: _retry),
        );
      },
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.error, required this.onRetry});

  static const _logoAsset = 'assets/brand/flow_read_logo.png';

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = error != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: hasError
                        ? Icon(
                            Icons.error_outline_rounded,
                            size: 36,
                            color: colorScheme.error,
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                _logoAsset,
                                filterQuality: FilterQuality.high,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Flow Read',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasError ? '启动失败，请重试' : '正在准备书架...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$error',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重试'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _CurrentRouteObserver extends NavigatorObserver {
  String? currentRouteName;

  void _setCurrent(Route<dynamic>? route) {
    currentRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _setCurrent(newRoute);
  }
}

class FlowReadApp extends StatefulWidget {
  const FlowReadApp({super.key});

  @override
  State<FlowReadApp> createState() => _FlowReadAppState();
}

class _FlowReadAppState extends State<FlowReadApp> {
  static const _appMenuChannel = MethodChannel('flow_read/app_menu');

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routeObserver = _CurrentRouteObserver();

  bool get _usesNativeSettingsMenu {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _appMenuChannel.setMethodCallHandler(_handleAppMenuCall);
  }

  @override
  void dispose() {
    _appMenuChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleAppMenuCall(MethodCall call) async {
    if (call.method == 'openSettings') {
      // AppKit key equivalents can consume Cmd+, before Flutter records the
      // modifier down, so align state before the synthesized modifier up.
      await HardwareKeyboard.instance.syncKeyboardState();
      _openSettings();
      return;
    }
    throw MissingPluginException('Unknown app menu method: ${call.method}');
  }

  void _openSettings() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null ||
        _routeObserver.currentRouteName == SettingsScreen.routeName) {
      return;
    }
    navigator.pushNamed(SettingsScreen.routeName);
  }

  Widget _buildShortcutScope(BuildContext context, Widget? child) {
    const openSettingsIntent = _OpenSettingsIntent();

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        if (!_usesNativeSettingsMenu)
          const SingleActivator(LogicalKeyboardKey.comma, meta: true):
              openSettingsIntent,
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            openSettingsIntent,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              _openSettings();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final themeId = settings.appThemeId;
          return ThemeTransitionHost(
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              navigatorObservers: [_routeObserver],
              title: 'Flow Read',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightThemeFor(themeId),
              darkTheme: AppTheme.darkThemeFor(themeId),
              themeMode: settings.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 220),
              themeAnimationCurve: Curves.easeOutCubic,
              builder: (context, child) {
                return _buildShortcutScope(
                  context,
                  WordMasteryConfettiHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: const ReleaseNotesGate(
                child: EpubDropImporter(child: HomeScreen()),
              ),
              routes: {
                SettingsScreen.routeName: (_) => const SettingsScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                '/syntax': (_) => const SyntaxScreen(),
                '/practice': (_) => const PracticeScreen(),
                '/review': (_) => const ReviewScreen(),
                '/spaced_review': (_) => const SpacedReviewScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
