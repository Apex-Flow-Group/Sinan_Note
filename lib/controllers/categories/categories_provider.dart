// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/category.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kMaxCategories = 20;
const int kMaxCategoryNameLength = 20;
const int kProCategoryId = -1;

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
    SharedPreferences.getInstance()
        .then((p) => p.setBool('hide_pro_from_home', value));
  }

  CategoriesProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hideProFromHome = prefs.getBool('hide_pro_from_home') ?? false;
    await _load();
    if (_categories.isEmpty) await _seedDefaults(null);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> seedIfEmpty(List<String> names) async {
    if (_categories.isNotEmpty || _seeded) return;
    _seeded = true;
    await _seedDefaults(names);
  }

  Future<void> _load() async {
    final db = SqliteDatabaseService();
    final all = await db.getAllCategories();
    all.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // حذف المكررات بناءً على الاسم
    final seen = <String>{};
    final unique = <NoteCategory>[];
    for (final cat in all) {
      final key = cat.name.trim().toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(cat);
      } else {
        await db.deleteCategory(cat.id);
      }
    }

    _categories = unique;
    notifyListeners();
  }

  Future<void> _seedDefaults(List<String>? names) async {
    final defaults = names ?? ['Work', 'Personal', 'Ideas', 'Tasks'];
    final db = SqliteDatabaseService();
    for (int i = 0; i < defaults.length; i++) {
      await db.insertCategory(NoteCategory(name: defaults[i], sortOrder: i));
    }
    await _load();
  }

  Future<bool> addCategory(String name) async {
    if (_categories.length >= kMaxCategories) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > kMaxCategoryNameLength) return false;

    final nextSortOrder =
        _categories.isEmpty ? 0 : _categories.last.sortOrder + 1;
    await SqliteDatabaseService()
        .insertCategory(NoteCategory(name: trimmed, sortOrder: nextSortOrder));
    GoogleDriveService.markDirty();
    _triggerSync();
    await _load();
    return true;
  }

  Future<void> renameCategory(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed.length > kMaxCategoryNameLength) return;
    final cat = _categories.firstWhere((c) => c.id == id,
        orElse: () => NoteCategory(id: id, name: trimmed));
    cat.name = trimmed;
    await SqliteDatabaseService().updateCategory(cat);
    GoogleDriveService.markDirty();
    _triggerSync();
    await _load();
  }

  Future<void> deleteCategory(int id) async {
    final db = SqliteDatabaseService();

    // أزل الـ id من جميع الملاحظات التي تحمله
    final allNotes = await db.getAllNotes();
    for (final note in allNotes) {
      if (note.categoryIds.contains(id)) {
        final updated = note.copyWith(
          categoryIds: note.categoryIds.where((i) => i != id).toList(),
          isHiddenFromHome:
              note.categoryIds.length == 1 ? false : note.isHiddenFromHome,
        );
        await db.updateNote(updated);
      }
    }

    await db.deleteCategory(id);
    GoogleDriveService.markDirty();
    _triggerSync();
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    await _load();
  }

  // debounce لمنع رفعات متكررة عند تعديل كتالوجات متعددة
  Timer? _syncDebounce;
  void _triggerSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 5), () async {
      if (!GoogleDriveService.isSignedIn) return;
      if (!GoogleDriveService.autoSyncEnabled.value) return;
      try {
        await GoogleDriveService.smartSyncOnStartup();
      } catch (_) {}
    });
  }

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> refreshCategories() async => await _load();
}
