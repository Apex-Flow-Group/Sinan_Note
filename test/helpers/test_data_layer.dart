import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// طبقة بيانات كاملة في الذاكرة للاختبارات: قاعدة بمخطط التطبيق، خزنة،
/// ومستودع الملاحظات — بلا إشعارات ولا ويدجت.
class TestDataLayer {
  TestDataLayer._(this.db, this.vault, this.notes);

  final Database db;
  final VaultRepository vault;
  final NotesRepository notes;

  static Future<TestDataLayer> create() async {
    await const FlutterSecureStorage().deleteAll();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: NotesSchema.version,
          onCreate: (db, _) => NotesSchema.create(db),
          singleInstance: false,
        ));
    final vault = VaultRepository(store: VaultKeyStore());
    final none = _NoPlatformEffects();
    final notes = NotesRepository(
        db: db, vault: vault, sideEffects: none, deletionLog: none);
    return TestDataLayer._(db, vault, notes);
  }

  Future<void> dispose() async {
    notes.dispose();
    vault.dispose();
    await db.close();
  }
}

class _NoPlatformEffects implements NoteSideEffects, DeletionLog {
  @override
  Future<void> noteChanged(Note note) async {}
  @override
  Future<void> noteRemoved(int id) async {}
  @override
  Future<void> recordDeleted(List<int> ids) async {}
}
