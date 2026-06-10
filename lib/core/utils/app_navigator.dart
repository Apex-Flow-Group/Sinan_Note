// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor.dart';
import 'package:sinan_note/screens/sync/google_drive_sync/google_drive_sync_page.dart';

// عتبة حجم النوت الطويل — ما فوقها نبني Quill أولاً لمنع تجمد الـ UI
const _kLongNoteThreshold = 1000;

/// مركز التنقل العام — مصدر واحد لكل انتقالات التطبيق.
///
/// للخزنة: استخدم [VaultNavigator] بدلاً من هذا.
///
/// الاستخدام:
/// ```dart
/// AppNavigator.toEditor(context, note: note, mode: mode);
/// AppNavigator.toSettings(context);
/// AppNavigator.toArchive(context);
/// AppNavigator.toTrash(context);
/// ```
abstract class AppNavigator {
  // ══════════════════════════════════════════════════════════════════
  // المحرر — أكثر وجهة استخداماً (8+ أماكن)
  // ══════════════════════════════════════════════════════════════════

  /// فتح المحرر لملاحظة موجودة أو جديدة.
  ///
  /// يُرجع `true` إذا تم حفظ/تعديل الملاحظة، `null` إذا رجع بدون حفظ.
  static Future<bool?> toEditor(
    BuildContext context, {
    required Note note,
    required NoteMode mode,
    bool readOnly = false,
    bool skipAuthentication = false,
    bool originallyLocked = false,
  }) async {
    if (!context.mounted) return null;

    // نوت طويل + readonly → نبني Quill في isolate أولاً لمنع تجمد الـ UI
    String? prebuiltDeltaJson;
    if (readOnly &&
        note.content.length > _kLongNoteThreshold &&
        (mode == NoteMode.simple ||
            mode == NoteMode.rich ||
            mode == NoteMode.reminder)) {
      prebuiltDeltaJson = await compute(buildDeltaJsonForIsolate, note.content);
      if (!context.mounted) return null;
    }

    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorImmersive(
          note: note,
          mode: mode,
          readOnly: readOnly,
          skipAuthentication: skipAuthentication,
          originallyLocked: originallyLocked,
          prebuiltDeltaJson: prebuiltDeltaJson,
        ),
        settings: const RouteSettings(name: '/editor'),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // شاشات الـ Drawer (named routes)
  // ══════════════════════════════════════════════════════════════════

  /// الإعدادات
  static Future<Object?> toSettings(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true).pushNamed('/settings');
  }

  /// سلة المحذوفات
  static Future<Object?> toTrash(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true).pushNamed('/trash');
  }

  /// الأرشيف
  static Future<Object?> toArchive(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true).pushNamed('/archive');
  }

  /// Google Drive
  static Future<Object?> toDrive(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true).pushNamed('/drive');
  }

  /// سجل الإصدارات
  static Future<Object?> toHistory(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true).pushNamed('/history');
  }

  /// اختيار ملاحظة للـ Widget
  static Future<Object?> toWidgetSelection(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.of(context, rootNavigator: true)
        .pushNamed('/widget_selection');
  }

  // ══════════════════════════════════════════════════════════════════
  // المزامنة
  // ══════════════════════════════════════════════════════════════════

  /// صفحة مزامنة Google Drive
  static Future<bool?> toGoogleDriveSync(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const GoogleDriveSyncPage(),
        settings: const RouteSettings(name: '/drive/sync'),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // أدوات مساعدة
  // ══════════════════════════════════════════════════════════════════

  /// العودة للشاشة الرئيسية من أي مكان
  static void popToMain(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil(
      (route) => route.settings.name == '/main' || route.isFirst,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Navigation بدون BuildContext (من intents / notifications)
  // ══════════════════════════════════════════════════════════════════

  /// فتح المحرر عبر navigatorKey (بدون context)
  static void toEditorViaKey(
    GlobalKey<NavigatorState> key, {
    required Note note,
    required NoteMode mode,
    bool readOnly = false,
  }) {
    key.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NoteEditorImmersive(
          note: note,
          mode: mode,
          readOnly: readOnly,
        ),
        settings: const RouteSettings(name: '/editor'),
      ),
    );
  }

  /// فتح شاشة اختيار Widget عبر navigatorKey (بدون context)
  static void toWidgetSelectionViaKey(GlobalKey<NavigatorState> key) {
    key.currentState?.pushNamed('/widget_selection');
  }
}
