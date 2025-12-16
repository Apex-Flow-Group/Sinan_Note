// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'screens/cinematic_intro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trash_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/locked_notes_screen.dart';
import 'config/flavor_config.dart';
import 'config/transfer_routes.dart';
import 'services/settings_provider.dart';
import 'services/notes_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/apex_diagnostics_engine.dart';
import 'services/apex_error_manager.dart';
import 'services/database_service.dart';
import 'screens/note_view_screen.dart';
import 'screens/widget_selection_screen.dart';

// Global navigator key for error feedback
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🕵️ الكشف الذكي عن النسخة بناءً على اسم الحزمة
  final packageInfo = await PackageInfo.fromPlatform();
  if (packageInfo.packageName == 'com.apexflow.app.sinan') {
    FlavorConfig.overrideFlavor(Flavor.googlePlay);
  }

  // تهيئة محرك التشخيص الأعمى مرة واحدة فقط
  final appDir = await getApplicationDocumentsDirectory();
  ApexDiagnosticsEngine().init(appDir.path);

  // Initialize error manager with navigator key
  ApexErrorManager.setNavigatorKey(navigatorKey);

  // 🧹 One-time legacy cleanup (runs in background)
  DatabaseService().runLegacyHistoryCleanup();

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await NotificationService().initialize();

      // طلب الأذونات في وقت التشغيل (Android 13+)
      if (Platform.isAndroid) {
        final permGranted = await NotificationService().requestNotificationPermissions();
        if (kDebugMode) {
          print('Notification permissions granted: $permGranted');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification initialization error: $e');
      }
    }

    // تهيئة الويدجت (Android فقط)
    if (Platform.isAndroid) {
      try {
        await WidgetService().initialize();
        await WidgetService().updateWidgetData();
        await WidgetService().updateChecklistWidget(0, '', '', 0);
      } catch (e) {
        // تجاهل أخطاء الويدجت
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const ApexNoteApp(),
    ),
  );
}

class ApexNoteApp extends StatefulWidget {
  const ApexNoteApp({super.key});

  @override
  State<ApexNoteApp> createState() => _ApexNoteAppState();
}

class _ApexNoteAppState extends State<ApexNoteApp> {
  static const platform = MethodChannel('com.apexflow.app.sinan/widget');

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _handleWidgetIntent();
      platform.setMethodCallHandler(_handleMethodCall);

      // 🔄 الاستماع للضغط على الويدجت عندما يكون التطبيق في الخلفية
      WidgetService().initialize().then((_) {
        HomeWidget.widgetClicked.listen((Uri? uri) {
          if (uri != null) {
            final noteId =
                int.tryParse(uri.queryParameters['note_id'] ?? '0') ?? 0;
            if (noteId > 0) {
              _openNoteById(noteId);
            } else {
              navigatorKey.currentState?.pushNamed('/widget_selection');
            }
          }
        });
      });
    }
  }

  Future<void> _handleWidgetIntent() async {
    try {
      final data = await platform.invokeMethod('getStartIntent');
      if (data != null && data is Map) {
        _processIntent(data);
      }
    } catch (e) {
      // Ignore: Widget intent errors are non-critical
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onIntent' && call.arguments is Map) {
      _processIntent(call.arguments);
    }
  }

  void _processIntent(Map data) async {
    final action = data['action'];
    final noteId = data['note_id'] ?? 0;
    final widgetType = data['widget_type'] ?? 'note';

    if (action == 'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WidgetSelectionScreen(widgetType: widgetType),
        ),
      );
    } else if (noteId == 0 && action == 'com.apexflow.app.sinan.ACTION_NEW_NOTE') {
      navigatorKey.currentState?.pushNamed('/widget_selection');
    } else if (action == 'com.apexflow.app.sinan.ACTION_VIEW_NOTE' && noteId > 0) {
      _openNoteById(noteId);
    }
  }

  void _openNoteById(int noteId) async {
    try {
      final dbService = DatabaseService();
      final note = await dbService.getNoteById(noteId);
      if (note != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                NoteViewScreen(note: note, showRestore: false),
          ),
        );
      } else {
        navigatorKey.currentState?.pushNamed('/widget_selection');
      }
    } catch (e) {
      navigatorKey.currentState?.pushNamed('/widget_selection');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  static Map<String, WidgetBuilder> _buildTransferRoutes() {
    return buildTransferRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              title: AppLocalizations.of(context)?.appName ?? 'Sinan Note',
              navigatorKey: navigatorKey,
              locale: settings.locale,
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: settings.themeMode,
              theme: ThemeData(
                colorScheme:
                    lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
                textTheme: TextTheme(
                  bodyMedium: TextStyle(fontSize: 16.0 * settings.textScaleFactor),
                ),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  },
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkDynamic ??
                    ColorScheme.fromSeed(
                        seedColor: Colors.teal, brightness: Brightness.dark),
                useMaterial3: true,
                textTheme: TextTheme(
                  bodyMedium: TextStyle(fontSize: 16.0 * settings.textScaleFactor),
                ),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  },
                ),
              ),
              home: Consumer<SettingsProvider>(
                builder: (context, settingsInner, child) {
                  if (!settingsInner.isInitialized) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (settingsInner.isFirstLaunch) {
                    return CinematicIntroScreen();
                  } else {
                    return const SplashScreen();
                  }
                },
              ),
              routes: {
                '/settings': (context) => const SettingsScreen(),
                '/trash': (context) => const TrashScreen(),
                '/archive': (context) => const ArchiveScreen(),
                '/locked': (context) => const LockedNotesScreen(),
                '/widget_selection': (context) => const WidgetSelectionScreen(),
                if (FlavorConfig.hasTransferFeature) ..._buildTransferRoutes(),
              },
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
