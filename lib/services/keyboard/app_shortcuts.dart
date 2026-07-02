// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// نظام اختصارات لوحة المفاتيح المركزي — Sinan Note
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// **البنية:**
/// ```
/// AppShortcuts (تعريف الاختصارات + Intents)
///   └── ShortcutScope (Widget يُغلّف أي شاشة ويربط الاختصارات بالأفعال)
/// ```
///
/// **الاستخدام:**
/// ```dart
/// ShortcutScope(
///   bindings: {
///     AppShortcuts.save: () => _saveNote(),
///     AppShortcuts.newNote: () => _createNote(),
///   },
///   child: Scaffold(...),
/// )
/// ```
///
/// **التوسع:**
/// أضف اختصاراً جديداً في 3 أسطر:
/// 1. `static const myAction = SingleActivator(LogicalKeyboardKey.keyM, control: true);`
/// 2. أضفه في `bindings` عند الاستخدام.
/// هذا كل شيء.

// ─── Intent فارغ — محجوز للاستخدام المستقبلي مع Shortcuts+Actions ──────────
// class _AppShortcutIntent extends Intent {
//   final String id;
//   const _AppShortcutIntent(this.id);
// }

/// تعريفات الاختصارات المركزية.
/// كل اختصار هو [SingleActivator] ثابت — لا يعتمد على context أو state.
abstract class AppShortcuts {
  AppShortcuts._();

  // ═══════════════════════════════════════════════════════════════════════════
  // عام — يعمل في كل الشاشات
  // ═══════════════════════════════════════════════════════════════════════════

  /// ملاحظة جديدة
  static const newNote =
      SingleActivator(LogicalKeyboardKey.keyN, control: true);

  /// بحث
  static const search = SingleActivator(LogicalKeyboardKey.keyF, control: true);

  /// إغلاق / عودة
  static const escape = SingleActivator(LogicalKeyboardKey.escape);

  /// الإعدادات
  static const settings =
      SingleActivator(LogicalKeyboardKey.comma, control: true);

  // ═══════════════════════════════════════════════════════════════════════════
  // المحرر
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ
  static const save = SingleActivator(LogicalKeyboardKey.keyS, control: true);

  /// حفظ كملف
  static const saveAs =
      SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true);

  /// تراجع
  static const undo = SingleActivator(LogicalKeyboardKey.keyZ, control: true);

  /// إعادة
  static const redo = SingleActivator(LogicalKeyboardKey.keyY, control: true);

  /// إعادة (بديل)
  static const redoAlt =
      SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true);

  /// إعادة تسمية
  static const rename = SingleActivator(LogicalKeyboardKey.f2);

  // ═══════════════════════════════════════════════════════════════════════════
  // تنسيق النص (Rich Editor)
  // ═══════════════════════════════════════════════════════════════════════════

  /// عريض
  static const bold = SingleActivator(LogicalKeyboardKey.keyB, control: true);

  /// مائل
  static const italic = SingleActivator(LogicalKeyboardKey.keyI, control: true);

  /// تحته خط
  static const underline =
      SingleActivator(LogicalKeyboardKey.keyU, control: true);

  /// يتوسطه خط
  static const strikethrough =
      SingleActivator(LogicalKeyboardKey.keyD, control: true);

  // ═══════════════════════════════════════════════════════════════════════════
  // إدارة الملاحظات
  // ═══════════════════════════════════════════════════════════════════════════

  /// حذف (نقل للسلة)
  static const delete =
      SingleActivator(LogicalKeyboardKey.delete, control: true);

  /// أرشفة
  static const archive =
      SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true);

  /// تكرار
  static const duplicate =
      SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true);

  /// قفل / فتح قفل
  static const toggleLock =
      SingleActivator(LogicalKeyboardKey.keyL, control: true);

  /// تثبيت / إلغاء تثبيت
  static const togglePin =
      SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true);

  // ═══════════════════════════════════════════════════════════════════════════
  // تنقل
  // ═══════════════════════════════════════════════════════════════════════════

  /// التبويب التالي
  static const nextTab = SingleActivator(LogicalKeyboardKey.tab, control: true);

  /// التبويب السابق
  static const prevTab =
      SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true);
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// [ShortcutScope] — Widget يُغلّف أي شاشة ويربط الاختصارات بالأفعال.
///
/// **لماذا هذا أفضل من Shortcuts+Actions:**
/// - أبسط: Map مباشر من Activator → VoidCallback
/// - لا يحتاج Intent/Action classes لكل اختصار
/// - يدعم التداخل: الشاشة الداخلية تُعيد تعريف اختصار بدون كسر الخارجية
/// - يعمل فقط على Desktop (يتجاهل Mobile تلقائياً)
///
/// ```dart
/// ShortcutScope(
///   bindings: {
///     AppShortcuts.save: _save,
///     AppShortcuts.escape: () => Navigator.pop(context),
///   },
///   child: Scaffold(...),
/// )
/// ```
/// ═══════════════════════════════════════════════════════════════════════════════
class ShortcutScope extends StatelessWidget {
  /// ربط كل [SingleActivator] بدالة تُنفَّذ عند الضغط.
  final Map<SingleActivator, VoidCallback> bindings;

  /// الـ Widget الابن.
  final Widget child;

  /// تفعيل/تعطيل الاختصارات (مفيد عند فتح dialog مثلاً).
  final bool enabled;

  const ShortcutScope({
    super.key,
    required this.bindings,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // على Mobile لا نحتاج اختصارات — نرجع الابن مباشرة
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return child;
    }

    if (!enabled || bindings.isEmpty) return child;

    return CallbackShortcuts(
      bindings: {
        for (final entry in bindings.entries) entry.key: entry.value,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
