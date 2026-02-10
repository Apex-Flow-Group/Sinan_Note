// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:async';
import 'core/utils/logger.dart';
import 'screens/cinematic_intro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trash_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/locked_notes_screen.dart';

import 'controllers/settings/settings_provider.dart';
import 'controllers/notes/notes_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/diagnostics/apex_diagnostics_engine.dart';
import 'services/diagnostics/apex_error_manager.dart';
import 'services/storage/isar_database_service.dart';
import 'services/storage/sqlite_to_isar_migration.dart';
import 'services/security/security_gate.dart';
import 'screens/note_view_screen.dart';
import 'screens/widget_selection_screen.dart';

// Global navigator key for error feedback
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Initialize SecurityController IMMEDIATELY
  SecurityController().initialize(const SecurityConfig(
    lockEnabled: false,
    lockDelaySeconds: 0,
    privacyBlurEnabled: false,
  ));

  // ⚡ تهيئة خفيفة فقط - تأجيل العمليات الثقيلة
  final appDir = await getApplicationDocumentsDirectory();
  ApexDiagnosticsEngine().init(appDir.path);
  ApexErrorManager.setNavigatorKey(navigatorKey);

  // 🔄 Migrate from SQLite to Isar
  await SqliteToIsarMigration.migrateIfNeeded();

  // ⚡ تأجيل تهيئة الإشعارات والويدجت لما بعد أول إطار
  if (Platform.isAndroid || Platform.isIOS) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService().initialize();
        if (Platform.isAndroid) {
          await NotificationService().requestNotificationPermissions();
          await WidgetService().initialize();
        }
      } catch (e) {
        AppLogger.error('Background init error', 'Main', e);
      }
    });
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
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WidgetSelectionScreen(widgetType: widgetType),
        ),
      );
    } else if (action == 'com.apexflow.app.sinan.ACTION_VIEW_NOTE' && noteId > 0) {
      _openNoteById(noteId);
    }
  }

  void _openNoteById(int noteId) async {
    try {
      final dbService = IsarDatabaseService();
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



  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // SettingsProvider automatically updates SecurityController via _updateSecurityController()
        // No need for manual initialization here - observer is already registered in main()

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
              },
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
