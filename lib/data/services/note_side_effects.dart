// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/services/note_services/note_side_effect_service.dart';

/// ما يحدث خارج القاعدة عند تغيّر ملاحظة: التذكيرات وويدجت الشاشة الرئيسية.
/// يستقبل الملاحظة كما خُزّنت؛ المقفلة تُعرض بنص عام لا بمحتواها.
abstract interface class NoteSideEffects {
  Future<void> noteChanged(Note note);
  Future<void> noteRemoved(int id);
}

/// سجل الحذف الذي تقرؤه المزامنة لنشر الحذف للأجهزة الأخرى.
abstract interface class DeletionLog {
  Future<void> recordDeleted(List<int> ids);
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

/// صيغة سجل الحذف التي تقرؤها المزامنة الحالية: `id:millis` في
/// SharedPreferences، آخر 1000 إدخال. تُستبدل بسجل uuid عند إعادة بناء
/// المزامنة.
class PreferencesDeletionLog implements DeletionLog {
  static const _key = 'deleted_note_ids';
  static const _limit = 1000;

  @override
  Future<void> recordDeleted(List<int> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final entries = [...?prefs.getStringList(_key)];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in ids) {
      if (!entries.any((e) => e.startsWith('$id:'))) entries.add('$id:$now');
    }
    if (entries.length > _limit) {
      entries.removeRange(0, entries.length - _limit);
    }
    await prefs.setStringList(_key, entries);
  }
}
