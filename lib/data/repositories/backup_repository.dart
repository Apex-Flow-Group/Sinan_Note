// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/errors.dart' show ValidationException;
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sqflite/sqflite.dart';

/// محتوى نسخة احتياطية مقروءة، قبل أي كتابة.
class BackupContents {
  const BackupContents({
    required this.notes,
    required this.categories,
    this.versions = const {},
  });

  final List<Note> notes;

  /// تصنيفات النسخة: رقمها في النسخة ← اسمها.
  final Map<int, String> categories;

  /// النسخ السابقة لكل ملاحظة (بالـ uuid). ملفات JSON لا تحملها.
  final Map<String, List<NoteVersion>> versions;
}

/// قراءة النسخ الاحتياطية وكتابتها في القاعدة، وتصديرها.
///
/// كل الكتابة على الملاحظات تمر بـ [NotesRepository] (التشفير، الذرّية،
/// الهوية بالـ uuid). الاستبدال لا يمس ملاحظات الخزنة المحلية، وملفات JSON
/// القديمة لا تكتب شيئاً في مفاتيح الخزنة.
class BackupRepository {
  BackupRepository({
    required Database db,
    required NotesRepository notes,
    required CategoriesRepository categories,
  })  : _db = db,
        _categories = categories,
        _notes = notes;

  final Database _db;
  final NotesRepository _notes;
  final CategoriesRepository _categories;

  static const _sqliteHeader = 'SQLite format 3\u0000';

  /// قاعدة SQLite؟ النسخ القديمة جداً (.sinannote بصيغة Isar) ليست كذلك.
  static Future<bool> isSqliteFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final raf = await file.open();
    try {
      return String.fromCharCodes(await raf.read(_sqliteHeader.length)) ==
          _sqliteHeader;
    } finally {
      await raf.close();
    }
  }

  /// يقرأ نسخة (.db أو JSON) دون أي كتابة. يرمي [ValidationException] لملف
  /// ليس نسخة صالحة لهذا الإصدار.
  Future<BackupContents> read(String path) async {
    if (await isSqliteFile(path)) return _readDatabase(path);
    try {
      return _readJson(await File(path).readAsString());
    } on FormatException catch (e) {
      throw ValidationException('Not a backup this version can read', e);
    }
  }

  Future<BackupContents> _readDatabase(String path) async {
    final backup = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
    try {
      final rows = await backup.query('notes');
      // ملف بلا uuid يأخذ هوية جديدة هنا؛ النسخ تتبع رقمها في الملف
      final notes = [for (final row in rows) NoteMapper.fromMap(row)];
      final uuidById = {
        for (final (i, row) in rows.indexed) row['id'] as int: notes[i].uuid,
      };
      Future<bool> has(String table) async => (await backup.query(
              'sqlite_master',
              where: "type = 'table' AND name = ?",
              whereArgs: [table]))
          .isNotEmpty;

      final versions = <String, List<NoteVersion>>{};
      if (await has('note_versions')) {
        for (final row in await backup.query('note_versions')) {
          final version = NoteMapper.versionFromMap(row);
          final uuid = uuidById[version.noteId];
          if (uuid != null) (versions[uuid] ??= []).add(version);
        }
      }
      return BackupContents(
        notes: notes,
        categories: {
          if (await has('categories'))
            for (final row in await backup.query('categories'))
              row['id'] as int: row['name'] as String,
        },
        versions: versions,
      );
    } finally {
      await backup.close();
    }
  }

  static BackupContents _readJson(String json) {
    final dynamic data = jsonDecode(json);
    final List<dynamic> list =
        data is Map<String, dynamic> ? (data['notes'] ?? []) : data as List;
    return BackupContents(
      notes: [
        for (final map in list)
          NoteMapper.fromMap(Map<String, Object?>.from(map as Map)),
      ],
      // ملفات JSON القديمة بلا أسماء تصنيفات؛ أرقامها تُطابق المحلية إن وُجدت
      categories: {
        if (data is Map<String, dynamic>)
          for (final c in (data['categories'] as List? ?? const []).cast<Map>())
            c['id'] as int: c['name'] as String,
      },
    );
  }

  Future<int> localNotesCount() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM notes')) ??
      0;

  /// يدمج [contents] مع الملاحظات المحلية. يُرجع عدد ما أُضيف أو حُدّث.
  Future<int> merge(BackupContents contents) async {
    final result = await _notes.merge(await _withLocalCategories(contents));
    await _importVersions(contents, result.localIds);
    return result.written;
  }

  /// يستبدل الملاحظات غير المقفلة بـ [contents].
  Future<void> replace(BackupContents contents) async {
    final localIds =
        await _notes.replaceUnlocked(await _withLocalCategories(contents));
    await _importVersions(contents, localIds);
  }

  Future<void> _importVersions(
      BackupContents contents, Map<String, int> localIds) async {
    await _notes.importVersions({
      for (final MapEntry(key: uuid, value: list) in contents.versions.entries)
        if (localIds[uuid] case final id?) id: list,
    });
  }

  /// لقطة متسقة من القاعدة (VACUUM INTO) في [directory]. يُرجع مسارها.
  Future<String> exportTo(String directory) async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final path = p.join(
      directory,
      'SinanNote_Backup_${now.year}-${two(now.month)}-${two(now.day)}_'
      '${two(now.hour)}${two(now.minute)}.db',
    );
    final file = File(path);
    if (await file.exists()) await file.delete();
    try {
      await _db.execute('VACUUM INTO ?', [path]);
    } on DatabaseException {
      // SQLite < 3.27 (أندرويد 7–10): نسخ الملف داخل transaction حتى لا
      // تتخلله كتابة
      await _db.transaction((_) => File(_db.path).copy(path));
    }
    return path;
  }

  /// ملف JSON يُستعاد بـ [read]. الملاحظات في السلة لا تُصدَّر؛ المقفلة فقط
  /// مع [includeVault]، كما هي مخزّنة (مشفّرة). يرمي `ValidationException`
  /// إن لم يكن هناك ما يُصدَّر.
  Future<({String path, int count})> exportJson(String directory,
      {required bool includeVault}) async {
    final rows = await _db.query('notes',
        where: includeVault ? 'isTrashed = 0' : 'isTrashed = 0 AND isLocked = 0');
    if (rows.isEmpty) throw const ValidationException('No notes to export');
    final notes = rows.map(NoteMapper.fromMap).toList();
    final data = {
      'version': '2.0',
      'created_at': DateTime.now().toIso8601String(),
      'has_locked_notes': notes.any((n) => n.isLocked),
      'notes': [for (final n in notes) NoteMapper.toMap(n)],
      'categories': [
        for (final c in _categories.categories)
          {'id': c.id, 'name': c.name, 'sortOrder': c.sortOrder},
      ],
    };
    final name = includeVault ? 'sinan_notes_full' : 'sinan_notes';
    final path = p.join(
        directory, '${name}_${DateTime.now().millisecondsSinceEpoch}.json');
    await File(path).writeAsString(jsonEncode(data), flush: true);
    return (path: path, count: notes.length);
  }

  /// يربط تصنيفات الملاحظات بالتصنيفات المحلية بالاسم، وينشئ الناقص منها.
  /// بلا أسماء (JSON): يبقي فقط الأرقام الموجودة محلياً.
  Future<List<Note>> _withLocalCategories(BackupContents contents) async {
    final idByName = await _categories.ensureNamed(contents.categories.values);
    final localIds = {for (final c in _categories.categories) c.id};

    List<int> remap(List<int> ids) => contents.categories.isEmpty
        ? ids.where(localIds.contains).toList()
        : ids
            .map((id) => idByName[contents.categories[id]])
            .whereType<int>()
            .toSet()
            .toList();

    return [
      for (final n in contents.notes)
        n.copyWith(categoryIds: remap(n.categoryIds)),
    ];
  }
}
