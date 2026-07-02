// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// اختصارات لوحة المفاتيح المركزية — Sinan Note
/// ═══════════════════════════════════════════════════════════════════════════
///
/// مصدر واحد لكل الاختصارات — يُستخدم في:
/// - [DesktopMenuBar]  : يعرض الاختصار بجانب كل عنصر قائمة
/// - [HomeScreenResponsive] : يربط Shortcuts+Actions للشاشة الرئيسية
/// - [ShortcutScope]   : يربط CallbackShortcuts في المحرر وأي شاشة أخرى
///
/// **إضافة اختصار جديد:**
/// 1. أضف `static const` هنا
/// 2. أضفه في [DesktopMenuBar] إذا أردت عرضه في القائمة
/// 3. ربطه في الشاشة المناسبة
abstract class AppShortcuts {
  AppShortcuts._();

  // ═══════════════════════════════════════════════════════════════════════
  // File — ملاحظات جديدة وعمليات الملف
  // ═══════════════════════════════════════════════════════════════════════

  /// ملاحظة نصية جديدة
  static const newNote =
      SingleActivator(LogicalKeyboardKey.keyN, control: true);

  /// ملاحظة كود جديدة
  static const codeNote =
      SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true);

  /// قائمة مهام جديدة
  static const checklist =
      SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true);

  /// تذكير جديد
  static const reminder =
      SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true);

  /// ملاحظة Rich جديدة
  static const richNote =
      SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true);

  /// حفظ
  static const save = SingleActivator(LogicalKeyboardKey.keyS, control: true);

  /// حفظ كملف
  static const saveAs =
      SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true);

  /// إغلاق العارض / العودة
  static const close = SingleActivator(LogicalKeyboardKey.escape);

  // ═══════════════════════════════════════════════════════════════════════
  // Edit — تحرير وتنسيق
  // ═══════════════════════════════════════════════════════════════════════

  /// تراجع
  static const undo = SingleActivator(LogicalKeyboardKey.keyZ, control: true);

  /// إعادة
  static const redo = SingleActivator(LogicalKeyboardKey.keyY, control: true);

  /// إعادة (بديل)
  static const redoAlt =
      SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true);

  /// إعادة تسمية
  static const rename = SingleActivator(LogicalKeyboardKey.f2);

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

  /// تحديد الكل
  static const selectAll =
      SingleActivator(LogicalKeyboardKey.keyA, control: true);

  /// بحث
  static const search = SingleActivator(LogicalKeyboardKey.keyF, control: true);

  // ═══════════════════════════════════════════════════════════════════════
  // Note — إدارة الملاحظات
  // ═══════════════════════════════════════════════════════════════════════

  /// حذف (نقل للسلة)
  static const delete =
      SingleActivator(LogicalKeyboardKey.delete, control: true);

  /// أرشفة
  static const archive =
      SingleActivator(LogicalKeyboardKey.keyE, control: true);

  /// تكرار
  static const duplicate =
      SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true);

  /// قفل / فتح قفل
  static const lock = SingleActivator(LogicalKeyboardKey.keyL, control: true);

  /// تثبيت / إلغاء تثبيت
  static const pin =
      SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true);

  // ═══════════════════════════════════════════════════════════════════════
  // View — عرض وتنقل
  // ═══════════════════════════════════════════════════════════════════════

  /// تحديث
  static const refresh = SingleActivator(LogicalKeyboardKey.f5);

  /// الإعدادات
  static const settings =
      SingleActivator(LogicalKeyboardKey.comma, control: true);

  /// تبديل نوع العرض (compact/expanded)
  static const toggleView =
      SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true);
}

// ═══════════════════════════════════════════════════════════════════════════
// Intents — لاستخدام Shortcuts+Actions في الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

class NewNoteIntent extends Intent {
  const NewNoteIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class CodeNoteIntent extends Intent {
  const CodeNoteIntent();
}

class ChecklistIntent extends Intent {
  const ChecklistIntent();
}

class ReminderIntent extends Intent {
  const ReminderIntent();
}

class RichNoteIntent extends Intent {
  const RichNoteIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class ToggleViewIntent extends Intent {
  const ToggleViewIntent();
}

// ═══════════════════════════════════════════════════════════════════════════
// ShortcutScope — Widget مساعد لربط الاختصارات بـ callbacks مباشرة
// ═══════════════════════════════════════════════════════════════════════════

/// يُغلّف أي Widget ويستمع لضغطات لوحة المفاتيح عبر [HardwareKeyboard].
///
/// **لماذا HardwareKeyboard وليس CallbackShortcuts+Focus؟**
/// - `CallbackShortcuts` يحتاج الـ Focus على الـ widget نفسه
/// - في المحرر، الـ Focus دائماً على TextField/QuillEditor
/// - `HardwareKeyboard` يعمل بغض النظر عن أي widget يملك الـ Focus
///
/// ```dart
/// ShortcutScope(
///   bindings: {
///     AppShortcuts.save: _saveNote,
///     AppShortcuts.close: () => Navigator.pop(context),
///   },
///   child: Scaffold(...),
/// )
/// ```
class ShortcutScope extends StatefulWidget {
  final Map<SingleActivator, VoidCallback> bindings;
  final Widget child;
  final bool enabled;

  const ShortcutScope({
    super.key,
    required this.bindings,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShortcutScope> createState() => _ShortcutScopeState();
}

class _ShortcutScopeState extends State<ShortcutScope> {
  bool _handlerRegistered = false;

  /// Guard لمنع تنفيذ نفس الاختصار أكثر من مرة في نفس الـ frame
  static int _lastHandledTimestamp = 0;
  static LogicalKeyboardKey? _lastHandledKey;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(ShortcutScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _register();
      } else {
        _unregister();
      }
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _register() {
    if (_handlerRegistered) return;
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return;
    }
    if (!widget.enabled || widget.bindings.isEmpty) return;
    HardwareKeyboard.instance.addHandler(_handleKey);
    _handlerRegistered = true;
  }

  void _unregister() {
    if (!_handlerRegistered) return;
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _handlerRegistered = false;
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed;

    for (final entry in widget.bindings.entries) {
      final activator = entry.key;
      if (_matches(activator, event, ctrl, shift, alt, meta)) {
        // منع التكرار: إذا نفس المفتاح تم معالجته في نفس الـ timestamp
        final now = event.timeStamp.inMilliseconds;
        if (_lastHandledKey == event.logicalKey &&
            (now - _lastHandledTimestamp).abs() < 50) {
          return true; // consumed but don't fire again
        }
        _lastHandledKey = event.logicalKey;
        _lastHandledTimestamp = now;

        entry.value();
        return true;
      }
    }
    return false;
  }

  bool _matches(
    SingleActivator activator,
    KeyEvent event,
    bool ctrl,
    bool shift,
    bool alt,
    bool meta,
  ) {
    if (activator.trigger != event.logicalKey) return false;
    if (activator.control != ctrl) return false;
    if (activator.shift != shift) return false;
    if (activator.alt != alt) return false;
    if (activator.meta != meta) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
