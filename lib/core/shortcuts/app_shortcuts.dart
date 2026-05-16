// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// اختصارات لوحة المفاتيح للتطبيق
class AppShortcuts {
  // New Note
  static const newNote =
      SingleActivator(LogicalKeyboardKey.keyN, control: true);

  // Search
  static const search = SingleActivator(LogicalKeyboardKey.keyF, control: true);

  // Save
  static const save = SingleActivator(LogicalKeyboardKey.keyS, control: true);

  // Delete
  static const delete = SingleActivator(LogicalKeyboardKey.delete);

  // Archive
  static const archive =
      SingleActivator(LogicalKeyboardKey.keyE, control: true);

  // Lock/Unlock
  static const lock = SingleActivator(LogicalKeyboardKey.keyL, control: true);

  // Code Note
  static const codeNote =
      SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true);

  // Checklist
  static const checklist =
      SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true);

  // Reminder
  static const reminder =
      SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true);

  // Close/Escape
  static const close = SingleActivator(LogicalKeyboardKey.escape);

  // Select All
  static const selectAll =
      SingleActivator(LogicalKeyboardKey.keyA, control: true);

  // Refresh
  static const refresh = SingleActivator(LogicalKeyboardKey.f5);
}

/// Intent لإنشاء ملاحظة جديدة
class NewNoteIntent extends Intent {
  const NewNoteIntent();
}

/// Intent للبحث
class SearchIntent extends Intent {
  const SearchIntent();
}

/// Intent للحفظ — محجوز للاستخدام المستقبلي
// class SaveIntent extends Intent { const SaveIntent(); }

/// Intent للحذف — محجوز للاستخدام المستقبلي
// class DeleteIntent extends Intent { const DeleteIntent(); }

/// Intent للأرشفة — محجوز للاستخدام المستقبلي
// class ArchiveIntent extends Intent { const ArchiveIntent(); }

/// Intent للقفل — محجوز للاستخدام المستقبلي
// class LockIntent extends Intent { const LockIntent(); }

/// Intent لملاحظة كود
class CodeNoteIntent extends Intent {
  const CodeNoteIntent();
}

/// Intent لقائمة مهام
class ChecklistIntent extends Intent {
  const ChecklistIntent();
}

/// Intent لتذكير
class ReminderIntent extends Intent {
  const ReminderIntent();
}

/// Intent للإغلاق — محجوز للاستخدام المستقبلي
// class CloseIntent extends Intent { const CloseIntent(); }

/// Intent لتحديد الكل — محجوز للاستخدام المستقبلي
// class SelectAllIntent extends Intent { const SelectAllIntent(); }

/// Intent للتحديث
class RefreshIntent extends Intent {
  const RefreshIntent();
}
