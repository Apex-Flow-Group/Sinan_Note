// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';

class NoteStateService {
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = [];
  bool _isInitialDataLoaded = false;
  Timer? _sortDebounce;

  /// Callback to refresh notes from database after sync
  Future<void> Function()? onSyncCompleted;
  Future<void> Function()? onCategoriesRefreshNeeded;

  // Cache
  List<Note>? _cachedActiveNotes;
  List<Note>? _cachedArchivedNotes;
  List<Note>? _cachedTrashedNotes;
  bool _cacheInvalidated = true;

  bool get isInitialDataLoaded => _isInitialDataLoaded;

  List<Note> get activeNotes {
    if (_cachedActiveNotes != null && !_cacheInvalidated) {
      return _cachedActiveNotes!;
    }
    _cachedActiveNotes = _allNotes
        .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
        .toList();
    _cacheInvalidated = false;
    return _cachedActiveNotes!;
  }

  List<Note> get archivedNotes {
    if (_cachedArchivedNotes != null && !_cacheInvalidated) {
      return _cachedArchivedNotes!;
    }
    _cachedArchivedNotes = _allNotes
        .where((n) => n.isArchived && !n.isTrashed && !n.isLocked)
        .toList();
    return _cachedArchivedNotes!;
  }

  List<Note> get trashedNotes {
    if (_cachedTrashedNotes != null && !_cacheInvalidated) {
      return _cachedTrashedNotes!;
    }
    _cachedTrashedNotes =
        _allNotes.where((n) => n.isTrashed && !n.isLocked).toList();
    return _cachedTrashedNotes!;
  }

  List<Note> get reminderNotes {
    return _allNotes
        .where((n) =>
            n.reminderDateTime != null &&
            !n.isLocked &&
            !n.isTrashed &&
            n.reminderDateTime!.isAfter(DateTime.now()))
        .toList();
  }

  List<Note> get lockedNotes => _lockedNotes;

  void updateAllNotes(List<Note> notes) {
    _allNotes = notes;
    _isInitialDataLoaded = true;
    _invalidateCache();
    sortNotes(immediate: true);
  }

  void updateNote(Note note) {
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = note;
    } else {
      _allNotes.add(note);
    }
    sortNotes(immediate: true);
    _allNotes = List.from(_allNotes);
    _invalidateCache();
    _silentSync();
  }

  Note? getNoteById(int id) {
    try {
      return _allNotes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void addNote(Note note) {
    if (note.isLocked) {
      _lockedNotes.insert(0, note);
    } else {
      _allNotes.insert(0, note);
      sortNotes(immediate: true);
      _allNotes = List.from(_allNotes);
    }
    _invalidateCache();
    _silentSync();
  }

  void removeNote(int id) {
    _allNotes.removeWhere((n) => n.id == id);
    _lockedNotes.removeWhere((n) => n.id == id);
    _invalidateCache();
    GoogleDriveService.markDirty();
    _silentSync();
  }

  void updateLockedNotes(List<Note> notes) {
    _lockedNotes = notes;
  }

  void clearLockedNotes() {
    _lockedNotes = [];
  }

  List<Note> searchNotes(String query) {
    if (query.trim().isEmpty) {
      return activeNotes;
    }

    // ✅ Use cached notes for search (faster)
    final lowerQuery = query.toLowerCase();
    final results = activeNotes
        .where((n) =>
            n.title.toLowerCase().contains(lowerQuery) ||
            n.content.toLowerCase().contains(lowerQuery))
        .take(100) // ✅ Limit to 100 results
        .toList();

    return results;
  }

  void sortNotes({bool immediate = false}) {
    if (immediate) {
      _performSort();
      return;
    }

    _sortDebounce?.cancel();
    _sortDebounce = Timer(const Duration(milliseconds: 50), () {
      if (_allNotes.isNotEmpty) _performSort();
    });
  }

  void _performSort() {
    _allNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void batchUpdateNotes(List<int> ids, Note Function(Note) transform) {
    _allNotes =
        _allNotes.map((n) => ids.contains(n.id) ? transform(n) : n).toList();
    _invalidateCache();
    _silentSync();
  }

  void dispose() {
    _sortDebounce?.cancel();
    _syncDebounce?.cancel();
  }

  /// Invalidate cache
  void _invalidateCache() {
    _cacheInvalidated = true;
    _cachedActiveNotes = null;
    _cachedArchivedNotes = null;
    _cachedTrashedNotes = null;
  }

  /// 🔄 Silent background sync with debouncing
  bool _isSyncing = false;
  Timer? _syncDebounce;

  void _silentSync() {
    // تعليم أن هناك تغييرات تحتاج رفع
    GoogleDriveService.markDirty();

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 5), () async {
      if (_isSyncing) return;
      if (!GoogleDriveService.isSignedIn) return;
      if (!GoogleDriveService.autoSyncEnabled.value) return;

      try {
        _isSyncing = true;
        await GoogleDriveService.smartSyncOnStartup();
        // ✅ Refresh notes from database after sync completes
        if (onSyncCompleted != null) {
          await onSyncCompleted!();
        }
        if (onCategoriesRefreshNeeded != null) {
          await onCategoriesRefreshNeeded!();
        }
      } catch (_) {
      } finally {
        _isSyncing = false;
      }
    });
  }
}
