import 'package:apex_note/models/category.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kMaxCategories = 20;
const int kMaxCategoryNameLength = 20;
const int kProCategoryId = -1; // ID ثابت للكتالوج المحترف (virtual)

class CategoriesProvider extends ChangeNotifier {
  List<NoteCategory> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _seeded = false;
  bool _hideProFromHome = false;

  List<NoteCategory> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  bool get hideProFromHome => _hideProFromHome;

  void setHideProFromHome(bool value) {
    _hideProFromHome = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('hide_pro_from_home', value));
  }

  CategoriesProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hideProFromHome = prefs.getBool('hide_pro_from_home') ?? false;
    await _load();
    if (_categories.isEmpty) {
      await _seedDefaults(null);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> seedIfEmpty(List<String> names) async {
    if (_categories.isNotEmpty || _seeded) return;
    _seeded = true;
    await _seedDefaults(names);
  }

  Future<void> _load() async {
    final isar = await IsarDatabaseService().database;
    final all =
        await isar.noteCategorys.filter().sortOrderGreaterThan(-1).findAll();
    all.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // حذف المكررات بناءً على الاسم
    final seen = <String>{};
    final duplicateIds = <int>[];
    final unique = <NoteCategory>[];
    for (final cat in all) {
      final key = cat.name.trim().toLowerCase();
      if (seen.contains(key)) {
        duplicateIds.add(cat.id);
      } else {
        seen.add(key);
        unique.add(cat);
      }
    }
    if (duplicateIds.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.noteCategorys.deleteAll(duplicateIds);
      });
    }

    _categories = unique;
    notifyListeners();
  }

  Future<void> _seedDefaults(List<String>? names) async {
    final defaults = names ?? ['Work', 'Personal', 'Ideas', 'Tasks'];
    final isar = await IsarDatabaseService().database;
    await isar.writeTxn(() async {
      for (int i = 0; i < defaults.length; i++) {
        await isar.noteCategorys.put(
          NoteCategory(name: defaults[i], sortOrder: i),
        );
      }
    });
    await _load();
  }

  Future<bool> addCategory(String name) async {
    if (_categories.length >= kMaxCategories) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > kMaxCategoryNameLength) return false;

    // الحل لمشكلة الترتيب: أخذ الترتيب الأخير + 1
    final nextSortOrder =
        _categories.isEmpty ? 0 : _categories.last.sortOrder + 1;

    final isar = await IsarDatabaseService().database;
    await isar.writeTxn(() async {
      await isar.noteCategorys.put(
        NoteCategory(name: trimmed, sortOrder: nextSortOrder),
      );
    });
    await _load();
    return true;
  }

  Future<void> renameCategory(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > kMaxCategoryNameLength) return;
    final isar = await IsarDatabaseService().database;
    final cat = await isar.noteCategorys.get(id);
    if (cat == null) return;
    cat.name = trimmed;
    await isar.writeTxn(() => isar.noteCategorys.put(cat));
    await _load();
  }

  Future<void> deleteCategory(int id) async {
    final isar = await IsarDatabaseService().database;

    // أزل الـ id من جميع الملاحظات التي تحمله لتجنب orphan IDs
    final notesWithCat =
        await isar.notes.filter().categoryIdsElementEqualTo(id).findAll();
    if (notesWithCat.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final note in notesWithCat) {
          note.categoryIds = note.categoryIds.where((i) => i != id).toList();
          if (note.categoryIds.isEmpty) note.isHiddenFromHome = false;
          await isar.notes.put(note);
        }
      });
    }

    await isar.writeTxn(() => isar.noteCategorys.delete(id));
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    await _load();
  }

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }
}
