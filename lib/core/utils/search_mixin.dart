// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Mixin يوحّد منطق البحث المتكرر في الشاشات البسيطة
mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool _searchActive = false;

  bool get isSearchActive => _searchActive;

  void initSearch() {
    searchController.addListener(() {
      if (mounted) setState(() => searchQuery = searchController.text);
    });
  }

  void exitSearch() {
    _searchActive = false;
    searchController.clear();
    if (mounted) setState(() => searchQuery = '');
  }

  void toggleSearch() {
    if (_searchActive) {
      exitSearch();
    } else {
      _searchActive = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
