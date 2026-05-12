// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';

class SmartSearchService {
  static final SmartSearchService _instance = SmartSearchService._();
  factory SmartSearchService() => _instance;
  SmartSearchService._();

  final _dbService = SqliteDatabaseService();

  /// Smart search with fuzzy matching
  Future<SearchResult> search(String query, {int limit = 100}) async {
    if (query.trim().isEmpty) {
      return SearchResult(notes: [], suggestion: null);
    }

    final normalizedQuery = Note.normalize(query);
    final notes = await _searchDirect(normalizedQuery, limit);

    if (notes.isEmpty) {
      final suggestion = await _findSuggestion(normalizedQuery);
      return SearchResult(notes: [], suggestion: suggestion);
    }

    return SearchResult(notes: notes, suggestion: null);
  }

  Future<List<Note>> _searchDirect(String normalizedQuery, int limit) async {
    await _dbService.database;

    // Use existing searchNotes method from database service
    return await _dbService.searchNotes(normalizedQuery, limit: limit);
  }

  Future<String?> _findSuggestion(String query) async {
    if (query.length < 2) return null;

    final prefix = query.substring(0, 2);

    // Get all active notes (simple query)
    final allNotes = await _dbService.getNotes(limit: 500);

    // Filter by prefix in memory
    final filteredNotes = allNotes
        .where((note) =>
            note.normalizedTitle.startsWith(prefix) ||
            note.normalizedContent.contains(prefix))
        .toList();

    final words = <String>{};
    for (final note in filteredNotes) {
      words.addAll(note.normalizedTitle.split(' '));
      words.addAll(note.normalizedContent.split(' ').take(50));
    }

    String? bestMatch;
    int minDistance = 2;

    for (final word in words) {
      if (word.length < 2 || !word.startsWith(prefix)) continue;
      final distance = _levenshtein(query, word);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = word;
      }
    }

    return bestMatch;
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }
}

class SearchResult {
  final List<Note> notes;
  final String? suggestion;

  SearchResult({required this.notes, this.suggestion});
}
