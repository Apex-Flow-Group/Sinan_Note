// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/services/key_value_store.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/domain/models/note_category.dart';
import 'package:sqflite/sqflite.dart';

/// المصدر الوحيد للتصنيفات، والكاتب الوحيد لجدول `categories`.
///
/// الأسماء فريدة (بلا اعتبار لحالة الأحرف)؛ الاسم هو هوية التصنيف بين
/// الأجهزة والنسخ الاحتياطية، والرقم محلي.
class CategoriesRepository extends ChangeNotifier {
  CategoriesRepository({
    required Database db,
    required NotesRepository notes,
    required DeletionLog deletionLog,
    required KeyValueStore store,
  })  : _db = db,
        _notes = notes,
        _deletionLog = deletionLog,
        _store = store;

  final Database _db;
  final NotesRepository _notes;
  final DeletionLog _deletionLog;
  final KeyValueStore _store;

  static const _seededKey = 'categories_seeded';
  static const _hideProKey = 'hide_pro_from_home';

  List<NoteCategory> _categories = const [];
  bool _hideProFromHome = false;

  /// يزداد مع كل تغيير محلي — ما تراقبه المزامنة.
  final localWrites = ValueNotifier(0);

  /// مرتبة حسب `sortOrder`.
  List<NoteCategory> get categories => _categories;

  /// إخفاء الملاحظات البرمجية من الرئيسية (يُزامَن مع التصنيفات).
  bool get hideProFromHome => _hideProFromHome;

  NoteCategory? byName(String name) {
    final key = CategoryPolicy.sameNameKey(name);
    for (final c in _categories) {
      if (CategoryPolicy.sameNameKey(c.name) == key) return c;
    }
    return null;
  }

  /// يقرأ التصنيفات. المكرر بالاسم (من إصدارات سابقة) يُدمج في الأول:
  /// ملاحظاته تنتقل إليه ثم يُحذف.
  Future<void> load() async {
    _hideProFromHome = await _store.getBool(_hideProKey) ?? false;
    final rows = await _db.query('categories', orderBy: 'sortOrder, id');
    final kept = <String, NoteCategory>{};
    for (final row in rows) {
      final category = NoteCategory(
        id: row['id'] as int,
        name: row['name'] as String,
        sortOrder: row['sortOrder'] as int,
      );
      final first = kept.putIfAbsent(
          CategoryPolicy.sameNameKey(category.name), () => category);
      if (!identical(first, category)) {
        await _notes.reassignCategory(category.id, to: first.id);
        await _db
            .delete('categories', where: 'id = ?', whereArgs: [category.id]);
      }
    }
    _categories = List.unmodifiable(kept.values);
    notifyListeners();
  }

  /// يُنشئ التصنيفات الافتراضية بأسماء لغة المستخدم — مرة واحدة في عمر
  /// التثبيت، فلا يعود ما حذفه المستخدم.
  Future<void> seedDefaults(List<String> names) async {
    if (await _store.getBool(_seededKey) ?? false) return;
    await _store.setBool(_seededKey, true);
    if (_categories.isNotEmpty) return;
    await _insertAll(names);
    await load();
  }

  /// يُرجع سبب الرفض، أو null عند الإضافة.
  Future<CategoryIssue?> add(String name) async {
    final issue = CategoryPolicy.check(name, _categories);
    if (issue != null) return issue;
    await _insertAll([name.trim()]);
    await _deletionLog.categoryCreated(name);
    await load();
    _changedLocally();
    return null;
  }

  Future<CategoryIssue?> rename(int id, String name) async {
    final issue = CategoryPolicy.check(name, _categories, renaming: id);
    if (issue != null) return issue;
    final old = _categories.firstWhere((c) => c.id == id);
    await _db.update('categories', {'name': name.trim()},
        where: 'id = ?', whereArgs: [id]);
    if (CategoryPolicy.sameNameKey(old.name) !=
        CategoryPolicy.sameNameKey(name)) {
      await _deletionLog.categoryDeleted(old.name);
      await _deletionLog.categoryCreated(name);
    }
    await load();
    _changedLocally();
    return null;
  }

  /// يحذف التصنيف ويزيله من ملاحظاته.
  Future<void> delete(int id) async {
    final category = _categories.where((c) => c.id == id).firstOrNull;
    if (category == null) return;
    await _notes.reassignCategory(id);
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _deletionLog.categoryDeleted(category.name);
    await load();
    _changedLocally();
  }

  Future<void> setHideProFromHome(bool value) async {
    if (value == _hideProFromHome) return;
    _hideProFromHome = value;
    await _store.setBool(_hideProKey, value);
    notifyListeners();
    _changedLocally();
  }

  // ── للاستيراد والمزامنة ──────────────────────────────────────────────────

  /// رقم محلي لكل اسم، بإنشاء الناقص. لا يُعد تغييراً محلياً للمزامنة.
  Future<Map<String, int>> ensureNamed(Iterable<String> names) async {
    final missing = <String, String>{};
    for (final name in names) {
      if (byName(name) == null) {
        missing.putIfAbsent(CategoryPolicy.sameNameKey(name), name.trim);
      }
    }
    if (missing.isNotEmpty) {
      await _insertAll(missing.values.toList());
      await load();
    }
    return {for (final name in names) name: byName(name)!.id};
  }

  /// يحذف تصنيفات حذفها جهاز آخر. لا يُعد تغييراً محلياً.
  Future<void> removeSynced(Set<int> ids) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      await _notes.reassignCategory(id);
      await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    }
    await load();
  }

  /// يطبق إعداد جهاز آخر. لا يُعد تغييراً محلياً.
  Future<void> applySyncedHideProFromHome(bool value) async {
    if (value == _hideProFromHome) return;
    _hideProFromHome = value;
    await _store.setBool(_hideProKey, value);
    notifyListeners();
  }

  Future<void> _insertAll(List<String> names) async {
    var sortOrder = _categories.isEmpty ? 0 : _categories.last.sortOrder + 1;
    await _db.transaction((txn) async {
      for (final name in names) {
        await txn
            .insert('categories', {'name': name, 'sortOrder': sortOrder++});
      }
    });
  }

  void _changedLocally() => localWrites.value++;

  @override
  void dispose() {
    localWrites.dispose();
    super.dispose();
  }
}
