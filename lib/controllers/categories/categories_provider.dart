// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/domain/models/note_category.dart';

/// التصنيفات للواجهة: القائمة، والتصنيف المختار للتصفية، والأوامر.
class CategoriesProvider extends ChangeNotifier {
  CategoriesProvider({required CategoriesRepository categories})
      : _categories = categories {
    _categories.addListener(_onCategoriesChanged);
  }

  final CategoriesRepository _categories;
  int? _selectedCategoryId;

  List<NoteCategory> get categories => _categories.categories;
  bool get hideProFromHome => _categories.hideProFromHome;
  bool get isFull => categories.length >= CategoryPolicy.maxCategories;

  /// تصنيف التصفية في الرئيسية؛ [CategoryPolicy.proCategoryId] للبرمجية.
  int? get selectedCategoryId => _selectedCategoryId;

  /// التصنيفات الافتراضية بلغة المستخدم، مرة واحدة في عمر التثبيت.
  Future<void> seedDefaults(List<String> names) =>
      _categories.seedDefaults(names);

  /// يُرجع سبب الرفض، أو null عند النجاح.
  Future<CategoryIssue?> addCategory(String name) => _categories.add(name);

  Future<CategoryIssue?> renameCategory(int id, String name) =>
      _categories.rename(id, name);

  Future<void> deleteCategory(int id) => _categories.delete(id);

  void setHideProFromHome(bool value) => _categories.setHideProFromHome(value);

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void _onCategoriesChanged() {
    final selected = _selectedCategoryId;
    if (selected != null &&
        selected != CategoryPolicy.proCategoryId &&
        !categories.any((c) => c.id == selected)) {
      _selectedCategoryId = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _categories.removeListener(_onCategoriesChanged);
    super.dispose();
  }
}
