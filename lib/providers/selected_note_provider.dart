// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:flutter/foundation.dart';

/// Provider لإدارة حالة الملاحظة المختارة في نمط Master-Details
/// 
/// يستخدم هذا Provider لتتبع الملاحظة المختارة حالياً على الشاشات الكبيرة
/// حيث يتم عرض قائمة الملاحظات (Master Panel) ومحتوى الملاحظة (Details Panel) جنباً إلى جنب
class SelectedNoteProvider extends ChangeNotifier {
  Note? _selectedNote;

  /// الحصول على الملاحظة المختارة حالياً
  Note? get selectedNote => _selectedNote;

  /// اختيار ملاحظة جديدة
  /// 
  /// يقوم بتحديث الملاحظة المختارة وإشعار جميع المستمعين
  /// لإعادة بناء الواجهة وعرض محتوى الملاحظة الجديدة
  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  /// مسح الملاحظة المختارة
  /// 
  /// يستخدم عند:
  /// - الانتقال بين الأقسام (Home/Vault/Archive/Trash)
  /// - حذف أو نقل الملاحظة المختارة
  /// - إغلاق Details Panel
  void clearSelection() {
    _selectedNote = null;
    notifyListeners();
  }

  /// التحقق من أن ملاحظة معينة هي المختارة حالياً
  /// 
  /// يستخدم لتمييز الملاحظة المختارة بصرياً في Master Panel
  bool isNoteSelected(int? noteId) {
    return _selectedNote?.id == noteId;
  }
}
