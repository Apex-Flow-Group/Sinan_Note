// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/note_side_effect_service.dart';
import 'package:sinan_note/domain/models/note.dart';

/// ما يحدث خارج القاعدة عند تغيّر ملاحظة: التذكيرات وويدجت الشاشة الرئيسية.
/// يستقبل الملاحظة كما خُزّنت؛ المقفلة تُعرض بنص عام لا بمحتواها.
abstract interface class NoteSideEffects {
  Future<void> noteChanged(Note note);
  Future<void> noteRemoved(int id);
}

class PlatformNoteSideEffects implements NoteSideEffects {
  PlatformNoteSideEffects([NoteSideEffectService? service])
      : _service = service ?? NoteSideEffectService();

  final NoteSideEffectService _service;

  @override
  Future<void> noteChanged(Note note) async {
    if (note.id == null) return;
    if (note.isTrashed || note.isArchived) {
      await _service.cancelReminderSideEffect(note.id!);
    } else {
      await _service.handleReminderSideEffect(note);
    }
    await _service.checkAndUpdateIfPinned(note);
  }

  @override
  Future<void> noteRemoved(int id) async {
    await _service.cancelReminderSideEffect(id);
    await _service.checkAndResetIfPinned(id);
  }
}
