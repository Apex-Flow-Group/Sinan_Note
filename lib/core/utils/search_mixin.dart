// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Mixin يوحّد منطق البحث المتكرر في الشاشات البسيطة
mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  bool get isSearchActive => searchController.text.isNotEmpty;

  void initSearch() {
    searchController.addListener(() {
      if (mounted) setState(() => searchQuery = searchController.text.toLowerCase());
    });
  }

  void exitSearch() {
    searchController.clear();
    if (mounted) setState(() => searchQuery = '');
  }

  void toggleSearch() {
    if (searchController.text.isEmpty) {
      searchController.text = ' ';
    } else {
      exitSearch();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
