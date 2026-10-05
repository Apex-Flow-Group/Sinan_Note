// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart'
    show ChangeNotifier, ScrollController, TextEditingController, ValueNotifier;
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/domain/models/note.dart';

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
    final searchQuery = searchController.text;
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
    final searchQuery = searchController.text;
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
        } else if (activeFilter == 'category:none') {
          if (note.categoryIds.isNotEmpty) return false;
        }
      }

      return note.matches(searchQuery, typoTolerant: true);
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
      case 'rich':
        return note.noteType == 'rich';
      default:
        return false;
    }
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

