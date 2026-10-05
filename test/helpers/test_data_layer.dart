import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sinan_note/data/services/key_value_store.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// طبقة بيانات كاملة في الذاكرة للاختبارات — "جهاز" مستقل: قاعدة بمخطط
/// التطبيق، خزنة، ملاحظات، تصنيفات، وسجل حذف وحالة خاصة به.
class TestDataLayer {
  TestDataLayer._(this.db, this.vault, this.notes, this.categories,
      this.tombstones, this.store);

  final Database db;
  final VaultRepository vault;
  final NotesRepository notes;
  final CategoriesRepository categories;
  final TombstoneStore tombstones;
  final MemoryStore store;

  static Future<TestDataLayer> create({DateTime Function()? clock}) async {
    await const FlutterSecureStorage().deleteAll();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: NotesSchema.version,
          onCreate: (db, _) => NotesSchema.create(db),
          singleInstance: false,
        ));
    final store = MemoryStore();
    final tombstones = TombstoneStore(store, clock: clock);
    final vault = VaultRepository(store: VaultKeyStore());
    final notes = NotesRepository(
        db: db,
        vault: vault,
        sideEffects: NoPlatformEffects(),
        deletionLog: tombstones,
        clock: clock);
    final categories = CategoriesRepository(
        db: db, notes: notes, deletionLog: tombstones, store: store);
    await categories.load();
    return TestDataLayer._(db, vault, notes, categories, tombstones, store);
  }

  Future<void> dispose() async {
    categories.dispose();
    notes.dispose();
    vault.dispose();
    await db.close();
  }
}

class NoPlatformEffects implements NoteSideEffects {
  @override
  Future<void> noteChanged(Note note) async {}
  @override
  Future<void> noteRemoved(int id) async {}
}

class MemoryStore implements KeyValueStore {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<int?> getInt(String key) async => values[key] as int?;
  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}
