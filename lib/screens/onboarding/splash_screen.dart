// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/main.dart' show navigatorKey;
import 'package:apex_note/screens/auth/pin_lock_screen.dart';
import 'package:apex_note/screens/onboarding/whats_new_dialog.dart';
import 'package:apex_note/screens/shared/main_layout_screen.dart';
import 'package:apex_note/services/app_update_service.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/diagnostics/apex_diagnostics_engine.dart';
import 'package:apex_note/services/diagnostics/apex_error_manager.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:apex_note/services/security/vault_reset_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Set navigator key immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApexErrorManager.setNavigatorKey(navigatorKey);
      _initApp();
    });
  }

  void _updateStatus(String message, double progress) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  Future<void> _initApp() async {
    if (!mounted) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    try {
      // Step 1: Initialize SQLite Database (20%)
      _updateStatus(
          isArabic ? 'تهيئة قاعدة البيانات...' : 'Initializing database...',
          0.2);
      await SqliteDatabaseService.initialize();

      // Step 2: Background services (60%)
      _updateStatus(isArabic ? 'تحميل الخدمات...' : 'Loading services...', 0.6);
      await _initBackgroundServices();

      // Step 3: Wait for settings (80%)
      _updateStatus(
          isArabic ? 'تحميل الإعدادات...' : 'Loading settings...', 0.8);
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      while (!settings.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }

      // Initialize Google Sign-In + smart sync in background
      await GoogleDriveService.initializeSignIn();
      if (GoogleDriveService.isSignedIn) {
        unawaited(GoogleDriveService.smartSyncOnStartup().then((_) async {
          if (!mounted) return;
          await Provider.of<NotesProvider>(context, listen: false).loadNotes();
        }));
      }

      if (!mounted) return;

      // Step 4: Authentication check (90%)
      _updateStatus(
          isArabic ? 'التحقق من الأمان...' : 'Security check...', 0.9);
      AppLogger.debug(
          '[Splash] isAppLockEnabled: ${settings.isAppLockEnabled}');
      if (settings.isAppLockEnabled) {
        AppLogger.debug(
            '[Splash] Calling UnifiedLockService.authenticate()...');
        final lockType = await UnifiedLockService().getLockType();
        AppLogger.debug('[Splash] LockType: $lockType');

        if (lockType == LockType.pin) {
          // PIN: عرض شاشة PIN وانتظار النتيجة
          if (!mounted) return;
          final hasPinAlready = await UnifiedLockService().hasPinSet();
          if (!mounted) return;
          final pinCompleter = Completer<bool>();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PinLockScreen(
                isSetup: !hasPinAlready,
                autoBiometric: settings.biometricLockEnabled,
                onSuccess: () {
                  Navigator.of(context).pop();
                  pinCompleter.complete(true);
                },
              ),
            ),
          );
          if (!pinCompleter.isCompleted) pinCompleter.complete(false);
          final pinResult = await pinCompleter.future;
          if (!pinResult) {
            AppLogger.debug('[Splash] PIN auth failed — stopping');
            return;
          }
        } else {
          final result = await UnifiedLockService().authenticate(
            context: 'app_lock',
            biometricEnabled: settings.biometricLockEnabled,
          );
          AppLogger.debug('[Splash] authenticate() returned: $result');
          if (!result) {
            AppLogger.debug('[Splash] User refused authentication — stopping');
            return;
          }
        }
      }
      AppLogger.debug('[Splash] Security check passed');

      if (!mounted) return;

      // Step 5: Load notes (100%)
      _updateStatus(isArabic ? 'تحميل الملاحظات...' : 'Loading notes...', 1.0);
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      // ✅ Load notes in background (non-blocking)
      notesProvider.loadNotes();

      // Navigate immediately without waiting
      if (!mounted) return;

      // Navigate
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainLayoutScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      // فحص التحديثات في الخلفية بعد التشغيل
      unawaited(Future.delayed(
        const Duration(seconds: 3),
        AppUpdateService.checkForUpdate,
      ));

      // تشويق النسخة النهائية
      if (mounted) _checkAndShowWhatsNew();
    } catch (e) {
      AppLogger.error('Splash initialization error', 'SplashScreen', e);
      _updateStatus(isArabic ? 'حدث خطأ...' : 'Error occurred...', 0.0);
    }
  }

  Future<void> _initBackgroundServices() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      ApexDiagnosticsEngine().init(appDir.path);

      // حذف النسخ الاحتياطية المنتهية (أقدم من 15 يوم)
      unawaited(VaultResetService.cleanExpiredBackups());

      if (Platform.isAndroid || Platform.isIOS) {
        await NotificationService().initialize();
        if (Platform.isAndroid) {
          await WidgetService().initialize();
        }
      }
    } catch (e) {
      AppLogger.error('Background services init error', 'SplashScreen', e);
    }
  }

  Future<void> _checkAndShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    final lastSeenVersion = prefs.getInt('last_seen_version') ?? 0;

    if (currentVersion > lastSeenVersion) {
      await prefs.setInt('last_seen_version', currentVersion);
      if (!mounted) return;
      _showWhatsNewDialog();
    }
  }

  void _showWhatsNewDialog() {
    WhatsNewDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'Sinan Note',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 48),

            // Progress Bar
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusMessage.isEmpty
                          ? (isArabic ? 'جاري التحميل...' : 'Loading...')
                          : _statusMessage,
                      key: ValueKey(_statusMessage),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
