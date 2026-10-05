// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// قناة أوامر المحرر — تربط DesktopMenuBar بالمحرر النشط
/// ═══════════════════════════════════════════════════════════════════════════
///
/// **آلية منع التكرار:**
/// - كل محرر يُسجّل نفسه بـ [registerEditor] عند mount
/// - يُلغي تسجيله بـ [unregisterEditor] عند dispose
/// - [activeNoteId] = آخر محرر سجّل نفسه (= المحرر المرئي)
/// - كل أمر يُنفَّذ فقط في المحرر الذي [noteId == activeNoteId]
enum EditorCommand {
  bold,
  italic,
  underline,
  strikethrough,
  undo,
  redo,
  rename,
  save,
  saveAs,
  archive,
  pin,
  duplicate,
  delete,
  category,
}

class EditorCommandBus extends ChangeNotifier {
  static final EditorCommandBus _instance = EditorCommandBus._internal();
  factory EditorCommandBus() => _instance;
  EditorCommandBus._internal();

  // ── المحرر النشط ──────────────────────────────────────────────────────
  int? _activeNoteId;
  int? _activeEditorHash;
  final Set<VoidCallback> _registeredListeners = {};

  void registerEditor(int? noteId, int editorHash) {
    if (noteId == null) return;
    _activeNoteId = noteId;
    _activeEditorHash = editorHash;
  }

  void unregisterEditor(int? noteId) {
    if (_activeNoteId == noteId) _activeNoteId = null;
  }

  int? get activeNoteId => _activeNoteId;
  int? get activeEditorHash => _activeEditorHash;

  void addUniqueListener(VoidCallback listener) {
    if (_registeredListeners.contains(listener)) return;
    _registeredListeners.add(listener);
    addListener(listener);
  }

  void removeUniqueListener(VoidCallback listener) {
    if (_registeredListeners.remove(listener)) {
      removeListener(listener);
    }
  }

  int get listenerCount => _count;  // exposed for debugging
  int _count = 0;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _count++;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _count--;
  }

  // ── الأوامر ───────────────────────────────────────────────────────────
  EditorCommand? _lastCommand;
  EditorCommand? get lastCommand => _lastCommand;

  void _send(EditorCommand command) {
    _lastCommand = command;
    notifyListeners();
    _lastCommand = null;
  }

  // تنسيق
  void triggerBold() => _send(EditorCommand.bold);
  void triggerItalic() => _send(EditorCommand.italic);
  void triggerUnderline() => _send(EditorCommand.underline);
  void triggerStrikethrough() => _send(EditorCommand.strikethrough);
  // تحرير
  void triggerUndo() => _send(EditorCommand.undo);
  void triggerRedo() => _send(EditorCommand.redo);
  void triggerRename() => _send(EditorCommand.rename);
  void triggerSave() => _send(EditorCommand.save);
  void triggerSaveAs() => _send(EditorCommand.saveAs);
  // إدارة الملاحظة
  void triggerArchive() => _send(EditorCommand.archive);
  void triggerPin() => _send(EditorCommand.pin);
  void triggerDuplicate() => _send(EditorCommand.duplicate);
  void triggerDelete() => _send(EditorCommand.delete);
  void triggerCategory() => _send(EditorCommand.category);
}
