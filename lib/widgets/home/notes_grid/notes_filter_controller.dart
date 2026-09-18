// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart'
    show
        ChangeNotifier,
        ScrollController,
        TextEditingController,
        ValueNotifier,
        visibleForTesting;

import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/models/note.dart';

class NotesFilterController extends ChangeNotifier {
  static const int _pageSize = 100;
  static const double _loadThreshold = 0.95;

  /// حدود البحث الضبابي — استعلام أقصر من هذا يُطابق حرفياً فقط
  static const int _minFuzzyQueryLength = 4;
  static const int _minFuzzyWordLength = 3;
  static const int _fuzzyTitleWords = 24;
  static const int _fuzzyContentWords = 50;
  static const int _space = 0x20;

  /// الكتابة السريعة لا تعيد بناء الشبكة عند كل حرف — الفلترة نفسها رخيصة،
  /// لكن إعادة بناء البطاقات ليست كذلك.
  static const Duration _searchDebounce = Duration(milliseconds: 110);

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
  Timer? _searchDebounceTimer;

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

    // فهرس واحد بدل مسح القائمة لكل عنصر — الإشعار يصل مع كل تعديل ومزامنة
    final incoming = <int?, Note>{for (final note in newNotes) note.id: note};

    var anyUpdated = false;
    for (var i = 0; i < _allFiltered.length; i++) {
      final current = _allFiltered[i];
      final updated = incoming[current.id];
      if (updated == null) continue;
      if (updated.updatedAt != current.updatedAt ||
          updated.colorIndex != current.colorIndex) {
        _allFiltered[i] = updated;
        anyUpdated = true;
      }
    }
    for (var i = 0; i < _sourceNotes.length; i++) {
      final updated = incoming[_sourceNotes[i].id];
      if (updated != null) _sourceNotes[i] = updated;
    }

    if (anyUpdated) {
      filteredNotesNotifier.value =
          List.of(_allFiltered.sublist(0, _visibleCount));
    }
  }

  /// يطبّق البحث والفلاتر على قائمة جاهزة بلا حاجة لمزوّدات.
  ///
  /// يعبّئ المصدر أيضاً حتى يعمل أي تغيير لاحق في البحث كما في الإنتاج.
  @visibleForTesting
  void filterFor(List<Note> notes) {
    _sourceNotes = List.of(notes);
    _syncFilteredNotes(_sourceNotes, force: true);
  }

  /// يحاكي وصول إشعار من [NotesProvider] بقائمة محدّثة.
  @visibleForTesting
  void applyProviderNotes(List<Note> notes) => _onProviderChanged(notes);

  void _onSearchChanged() {
    final query = searchController.text;
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;

    _searchDebounceTimer?.cancel();
    // إفراغ الحقل يستجيب فوراً — المستخدم ينتظر رجوع القائمة كاملة
    if (query.isEmpty) {
      _syncFilteredNotes(_sourceNotes);
      return;
    }
    _searchDebounceTimer = Timer(_searchDebounce, () {
      _syncFilteredNotes(_sourceNotes);
    });
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
    // تطبيع الاستعلام مرة واحدة — كان يُحسب لكل ملاحظة على حِدة
    final normalized = searchQuery.isEmpty ? '' : Note.normalize(searchQuery);
    final allowFuzzy = normalized.length >= _minFuzzyQueryLength;

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

      if (searchQuery.isEmpty) return true;

      if (note.normalizedTitle.contains(normalized) ||
          note.normalizedContent.contains(normalized)) {
        return true;
      }

      if (!allowFuzzy) return false;
      return _anyWordNearQuery(
            note.normalizedTitle,
            normalized,
            _fuzzyTitleWords,
          ) ||
          _anyWordNearQuery(
            note.normalizedContent,
            normalized,
            _fuzzyContentWords,
          );
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

  /// هل في [text] كلمة تبعد عن [query] تحريراً واحداً على الأكثر؟
  ///
  /// يمسح الكلمات في مكانها بلا اقتطاع نصوص ولا مصفوفات — البحث يُعاد عند كل
  /// حرف يكتبه المستخدم، على كل الملاحظات.
  static bool _anyWordNearQuery(String text, String query, int maxWords) {
    var scanned = 0;
    var start = 0;
    final length = text.length;

    for (var i = 0; i <= length; i++) {
      if (i != length && text.codeUnitAt(i) != _space) continue;
      if (i - start >= _minFuzzyWordLength &&
          _withinOneEdit(query, text, start, i)) {
        return true;
      }
      scanned++;
      if (scanned >= maxWords) return false;
      start = i + 1;
    }
    return false;
  }

  /// مسافة تحرير ≤ 1 بين [query] والمقطع `[start, end)` من [text].
  ///
  /// اختلاف الطول بأكثر من حرف يُرفض فوراً، والمقارنة تتوقف عند ثاني اختلاف —
  /// فلا حاجة لمصفوفة Levenshtein كاملة لسؤال جوابه نعم أو لا.
  static bool _withinOneEdit(String query, String text, int start, int end) {
    final wordLength = end - start;
    if ((query.length - wordLength).abs() > 1) return false;

    var q = 0;
    var t = start;
    var edited = false;

    while (q < query.length && t < end) {
      if (query.codeUnitAt(q) == text.codeUnitAt(t)) {
        q++;
        t++;
        continue;
      }
      if (edited) return false;
      edited = true;
      if (query.length > wordLength) {
        q++;
      } else if (query.length < wordLength) {
        t++;
      } else {
        q++;
        t++;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
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
