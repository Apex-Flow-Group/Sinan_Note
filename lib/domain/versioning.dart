// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/models/note_version.dart';

/// متى تُحفظ نسخة جديدة من ملاحظة. [action] هو ما يُخزَّن ويُعرض — بنفس
/// القيم التي كتبتها الإصدارات السابقة.
enum VersionTrigger {
  /// حفظ صريح من المستخدم: يُسجَّل ما لم يطابق آخر نسخة حرفياً.
  manual('manual_save'),

  /// نهاية جلسة تحرير: يُسجَّل فقط إن كان التغيير ذا معنى.
  sessionEnd('session_end'),

  /// قبل عملية تغيّر المحتوى جذرياً (تحويل النوع، استعادة نسخة): دائماً.
  forced('manual_save');

  const VersionTrigger(this.action);

  final String action;
}

/// قواعد النسخ — بلا حالة.
abstract final class VersionPolicy {
  static const maxVersionsPerNote = 20;
  static const _minChangedChars = 20;
  static const _minChangedRatio = 0.05;

  static bool shouldRecord({
    required VersionTrigger trigger,
    required NoteVersion? last,
    required String title,
    required String content,
  }) {
    if (trigger == VersionTrigger.forced || last == null) return true;
    if (last.title == title && last.content == content) return false;
    if (trigger == VersionTrigger.manual) return true;
    return _isSignificant(last.title, last.content, title, content);
  }

  static bool _isSignificant(
      String oldTitle, String oldContent, String newTitle, String newContent) {
    final oldLength = oldTitle.length + oldContent.length;
    final lengthDiff = (newTitle.length + newContent.length - oldLength).abs();
    if (lengthDiff < _minChangedChars) return false;
    final ratio = oldLength > 0 ? lengthDiff / oldLength : 1.0;
    return ratio >= _minChangedRatio;
  }
}
