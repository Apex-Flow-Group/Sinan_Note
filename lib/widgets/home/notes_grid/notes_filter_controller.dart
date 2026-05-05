// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart'
    show ChangeNotifier, ScrollController, TextEditingController, ValueNotifier;

class NotesFilterController extends ChangeNotifier {
  static const int _pageSize = 100;
  static const double _loadThreshold = 0.95;

  final TextEditingController searchController;
  final ValueNotifier<String?> activeFilterNotifier;
  final ValueNotifier<List<Note>>? externalFilteredNotifier;
  final ValueNotifier<int>? externalTotalNotifier;
  final ValueNotifier<int>? externalVisibleNotifier;

  late final ValueNotifier<List<Note>> filteredNotesNotifier;
  final ValueNotifier<bool> hasMoreNotifier = ValueNotifier(false);
  final ValueNotifier<int> visibleCountNotifier = ValueNotifier(0);
  final ValueNotifier<int> totalCountNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isFilteringNotifier = ValueNotifier(false);

  List<Note> _sourceNotes = [];
  List<Note> _allFiltered = [];
  int _visibleCount = _pageSize;
  int? _lastSelectedCategoryId;
  bool _lastHideProFromHome = false;
  String _lastSearchQuery = '';
  int _lastRefreshStamp = -1;

  NotesFilterController({
    required this.searchController,
    required this.activeFilterNotifier,
    this.externalFilteredNotifier,
    this.externalTotalNotifier,
    this.externalVisibleNotifier,
  }) {
    filteredNotesNotifier = externalFilteredNotifier ?? ValueNotifier([]);
    searchController.addListener(_onSearchChanged);
    activeFilterNotifier.addListener(_onFilterChanged);
  }

  void onScroll(ScrollController sc) {
    final pos = sc.position;
    if (pos.pixels >= pos.maxScrollExtent * _loadThreshold &&
        _visibleCount < _allFiltered.length) {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _allFiltered.length);
      _updateNotifiers();
      filteredNotesNotifier.value = _allFiltered.sublist(0, _visibleCount);
    }
  }

  void syncFromProvider(
      NotesProvider provider, CategoriesProvider catProvider) {
    final selectedId = catProvider.selectedCategoryId;
    final hideProFromHome = catProvider.hideProFromHome;
    final stamp = provider.refreshStamp;
    final forceRefresh = stamp != _lastRefreshStamp;

    if (forceRefresh) _lastRefreshStamp = stamp;

    final categoryChanged = selectedId != _lastSelectedCategoryId ||
        hideProFromHome != _lastHideProFromHome;
    if (categoryChanged) {
      _lastSelectedCategoryId = selectedId;
      _lastHideProFromHome = hideProFromHome;
    }

    if (forceRefresh || categoryChanged) {
      _sourceNotes = List.of(provider.notes);
      _syncFilteredNotes(_sourceNotes, force: true);
      return;
    }

    _onProviderChanged(provider.notes);
  }

  void _onProviderChanged(List<Note> newNotes) {
    final newIds = newNotes.map((n) => n.id).toSet();
    final currentIds = _allFiltered.map((n) => n.id).toSet();

    final removedIds = currentIds.difference(newIds);
    if (removedIds.isNotEmpty) {
      _sourceNotes = List.of(newNotes);
      _allFiltered.removeWhere((n) => removedIds.contains(n.id));
      _visibleCount = _visibleCount.clamp(0, _allFiltered.length);
      _updateNotifiers();
      filteredNotesNotifier.value =
          List.of(_allFiltered.sublist(0, _visibleCount));
      return;
    }

    final addedIds = newIds.difference(currentIds);
    if (addedIds.isNotEmpty) {
      _sourceNotes = List.of(newNotes);
      _syncFilteredNotes(_sourceNotes, force: true);
      return;
    }

    bool anyUpdated = false;
    for (int i = 0; i < _allFiltered.length; i++) {
      final updated = newNotes.firstWhere(
        (n) => n.id == _allFiltered[i].id,
        orElse: () => _allFiltered[i],
      );
      if (updated.updatedAt != _allFiltered[i].updatedAt ||
          updated.colorIndex != _allFiltered[i].colorIndex) {
        _allFiltered[i] = updated;
        anyUpdated = true;
      }
    }
    // Also update _sourceNotes to reflect latest note data
    for (int i = 0; i < _sourceNotes.length; i++) {
      final updated = newNotes.firstWhere(
        (n) => n.id == _sourceNotes[i].id,
        orElse: () => _sourceNotes[i],
      );
      _sourceNotes[i] = updated;
    }
    if (anyUpdated) {
      filteredNotesNotifier.value =
          List.of(_allFiltered.sublist(0, _visibleCount));
    }
  }

  void _onSearchChanged() {
    final query = searchController.text;
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;
    _syncFilteredNotes(_sourceNotes);
  }

  void _onFilterChanged() => _syncFilteredNotes(_sourceNotes, force: true);

  void _syncFilteredNotes(List<Note> notes, {bool force = false}) {
    final searchQuery = searchController.text.toLowerCase();
    final isFiltering = searchQuery.isNotEmpty ||
        _lastSelectedCategoryId != null ||
        activeFilterNotifier.value != null;
    isFilteringNotifier.value = isFiltering;

    final newFiltered = _filterNotes(notes);
    _allFiltered = newFiltered;
    _visibleCount = _pageSize.clamp(0, newFiltered.length);
    _updateNotifiers();

    final page = newFiltered.sublist(0, _visibleCount);
    if (!force) {
      final current = filteredNotesNotifier.value;
      if (page.length == current.length) {
        bool same = true;
        for (int i = 0; i < page.length; i++) {
          if (current[i].id != page[i].id ||
              current[i].updatedAt != page[i].updatedAt) {
            same = false;
            break;
          }
        }
        if (same) return;
      }
    }
    filteredNotesNotifier.value = List.of(page);
  }

  void _updateNotifiers() {
    hasMoreNotifier.value = _visibleCount < _allFiltered.length;
    visibleCountNotifier.value = _visibleCount;
    totalCountNotifier.value = _allFiltered.length;
    externalTotalNotifier?.value = _allFiltered.length;
    externalVisibleNotifier?.value = _visibleCount;
  }

  List<Note> _filterNotes(List<Note> notes) {
    final searchQuery = searchController.text.toLowerCase();
    final activeFilter = activeFilterNotifier.value;
    final selectedCategoryId = _lastSelectedCategoryId;
    final hideProFromHome = _lastHideProFromHome;
    final isFiltering = searchQuery.isNotEmpty ||
        selectedCategoryId != null ||
        activeFilter != null;

    return notes.where((note) {
      if (note.isLocked || note.isArchived || note.isTrashed) return false;
      if (!isFiltering && note.isHiddenFromHome) return false;

      if (selectedCategoryId == kProCategoryId) {
        if (!note.isProfessional) return false;
      } else if (selectedCategoryId != null) {
        if (!note.categoryIds.contains(selectedCategoryId)) return false;
      } else {
        if (!isFiltering && hideProFromHome && note.isProfessional) {
          return false;
        }
      }

      if (activeFilter != null) {
        if (activeFilter.startsWith('type:')) {
          if (!_matchNoteType(note, activeFilter.substring(5))) {
            return false;
          }
        } else if (activeFilter == 'pinned:true') {
          if (!note.isPinned) return false;
        }
      }

      if (searchQuery.isEmpty) return true;

      final normalized = Note.normalize(searchQuery);
      if (note.normalizedTitle.contains(normalized) ||
          note.normalizedContent.contains(normalized)) {
        return true;
      }

      if (normalized.length >= 4) {
        for (final word in [
          ...note.normalizedTitle.split(' '),
          ...note.normalizedContent.split(' ').take(50)
        ]) {
          if (word.length >= 3 && _levenshtein(normalized, word) <= 1) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  bool _matchNoteType(Note note, String type) {
    switch (type) {
      case 'simple':
        return note.noteType == 'simple' || note.noteType.isEmpty;
      case 'pro':
      case 'code':
        return note.noteType == 'pro' ||
            note.noteType == 'code' ||
            note.isProfessional;
      case 'reminder':
        return note.reminderDateTime != null;
      case 'checklist':
        return note.noteType == 'checklist' || note.isChecklist;
      default:
        return false;
    }
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    final m = s1.length, n = s2.length;
    final dp = List.generate(
        m + 1,
        (i) => List.generate(
            n + 1,
            (j) => i == 0
                ? j
                : j == 0
                    ? i
                    : 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s1[i - 1] == s2[j - 1]
            ? dp[i - 1][j - 1]
            : 1 +
                [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                    .reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[m][n];
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    activeFilterNotifier.removeListener(_onFilterChanged);
    hasMoreNotifier.dispose();
    visibleCountNotifier.dispose();
    totalCountNotifier.dispose();
    isFilteringNotifier.dispose();
    if (externalFilteredNotifier == null) filteredNotesNotifier.dispose();
    super.dispose();
  }
}
