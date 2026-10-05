// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/sync_repository.dart';

export 'package:sinan_note/domain/errors.dart' show SyncException;

/// المزامنة مع Google Drive للواجهات: الحساب، الحالة، والأوامر.
///
/// الأوامر ترمي `SyncException` عند الفشل؛ الواجهة تعرض الرسالة.
class SyncViewModel extends ChangeNotifier {
  SyncViewModel({required SyncRepository sync, required NotesRepository notes})
      : _sync = sync,
        _notes = notes {
    _sync.addListener(notifyListeners);
  }

  final SyncRepository _sync;
  final NotesRepository _notes;

  bool get isSignedIn => _sync.isSignedIn;
  String? get accountEmail => _sync.accountEmail;
  bool get autoSync => _sync.autoSync;
  bool get isSyncing => _sync.isSyncing;
  bool get hasPendingChanges => _sync.hasPendingChanges;
  DateTime? get lastSyncedAt => _sync.lastSyncedAt;

  /// الملاحظات التي تُزامن (غير المقفلة).
  int get localNoteCount => _notes.notes.length;

  Future<void> restoreSession() => _sync.restoreSession();
  Future<bool> signIn() => _sync.signIn();
  Future<void> signOut() => _sync.signOut();
  Future<void> setAutoSync(bool value) => _sync.setAutoSync(value);

  /// يدمج مع السحابة إن تغيّرت ثم يرفع — لا يُفقد شيء من الطرفين.
  Future<void> sync() => _sync.sync();

  /// "استخدم ما على الجهاز".
  Future<void> overwriteRemote() => _sync.overwriteRemote();

  /// "استخدم ما في Drive".
  Future<void> replaceLocal() => _sync.replaceLocal();

  Future<bool> hasRemote() => _sync.hasRemote();

  /// عدد الملاحظات في السحابة، أو null إن لم تكن فيها نسخة.
  Future<int?> remoteNoteCount() => _sync.remoteNoteCount();

  /// مزامنة صامتة إن كان المستخدم مسجلاً والمزامنة التلقائية مفعّلة (عند
  /// البدء والسحب للتحديث). الأخطاء لا تُعرض.
  Future<void> syncIfEnabled() async {
    if (!isSignedIn || !autoSync) return;
    try {
      await sync();
    } on Object {
      // التغييرات تبقى معلّمة وتُرفع في المرة التالية
    }
  }

  @override
  void dispose() {
    _sync.removeListener(notifyListeners);
    super.dispose();
  }
}
