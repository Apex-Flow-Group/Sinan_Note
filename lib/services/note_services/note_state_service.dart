// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import '../../models/note.dart';

class NoteStateService {
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = [];
  bool _isInitialDataLoaded = false;
  Timer? _sortDebounce;
  
  bool get isInitialDataLoaded => _isInitialDataLoaded;
  
  List<Note> get activeNotes {
    return _allNotes
        .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
        .toList();
  }
  
  List<Note> get archivedNotes {
    return _allNotes
        .where((n) => n.isArchived && !n.isTrashed && !n.isLocked)
        .toList();
  }
  
  List<Note> get trashedNotes {
    return _allNotes.where((n) => n.isTrashed && !n.isLocked).toList();
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
    sortNotes(immediate: true);
  }
  
  void updateNote(Note note) {
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = note;
      _allNotes = List.from(_allNotes);
    } else {
      _allNotes.add(note);
      _allNotes = List.from(_allNotes);
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
  }
  
  void removeNote(int id) {
    _allNotes.removeWhere((n) => n.id == id);
    _lockedNotes.removeWhere((n) => n.id == id);
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
    
    final lowerQuery = query.toLowerCase();
    return _allNotes
        .where((n) =>
            !n.isLocked &&
            !n.isTrashed &&
            (n.title.toLowerCase().contains(lowerQuery) ||
                n.content.toLowerCase().contains(lowerQuery)))
        .toList();
  }
  
  void sortNotes({bool immediate = false}) {
    if (immediate) {
      _performSort();
      return;
    }
    
    _sortDebounce?.cancel();
    _sortDebounce = Timer(const Duration(milliseconds: 50), _performSort);
  }
  
  void _performSort() {
    _allNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
  
  void batchUpdateNotes(List<int> ids, Note Function(Note) transform) {
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) ? transform(n) : n
    ).toList();
  }
  
  void dispose() {
    _sortDebounce?.cancel();
  }
}
