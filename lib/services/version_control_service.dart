// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:crypto/crypto.dart';

/// Ultra-Smart Version Control Service
/// Philosophy: ONE meaningful version per editing session
class VersionControlService {
  // Ultra-strict settings
  static const int _minSignificantChange = 100; // 100 chars minimum
  static const double _minChangePercentage = 0.10; // 10% change minimum
  static const int _maxVersionsPerNote = 5; // Keep only 5 versions max

  // Session tracking (in-memory)
  static final Map<int, String> _sessionSnapshots = {};
  static final Map<int, DateTime> _sessionStartTimes = {};

  final SqliteDatabaseService _db = SqliteDatabaseService();

  /// Start editing session - Take snapshot
  void startEditingSession(int noteId, String title, String content) {
    _sessionSnapshots[noteId] = _generateHash(title + content);
    _sessionStartTimes[noteId] = DateTime.now();
  }

  /// End editing session - Save ONLY if significant change
  Future<void> endEditingSession({
    required int noteId,
    required String title,
    required String content,
    bool isLocked = false,
  }) async {
    // 🔒 SECURITY: Never save locked notes
    if (isLocked) {
      _cleanupSession(noteId);
      return;
    }

    final currentHash = _generateHash(title + content);
    final sessionHash = _sessionSnapshots[noteId];

    // No session? Skip
    if (sessionHash == null) {
      return;
    }

    // No change? Skip
    if (currentHash == sessionHash) {
      _cleanupSession(noteId);
      return;
    }

    // Get last version to compare
    final lastVersion = await _db.getLastNoteVersion(noteId);

    if (lastVersion != null) {
      // Calculate semantic difference
      final significance = _calculateSignificance(
        oldTitle: lastVersion.title,
        oldContent: lastVersion.content,
        newTitle: title,
        newContent: content,
      );

      // Not significant? Skip
      if (!significance.isSignificant) {
        _cleanupSession(noteId);
        return;
      }
    }

    // ✅ Save ONE version for this session
    final newVersion = NoteVersion.create(
      noteId: noteId,
      title: title,
      content: content,
      timestamp: DateTime.now(),
      action: 'session_end',
    );

    await _db.logNoteVersion(newVersion);
    await _pruneOldVersions(noteId);

    _cleanupSession(noteId);
  }

  /// Calculate if change is significant (ULTRA SMART)
  _ChangeSignificance _calculateSignificance({
    required String oldTitle,
    required String oldContent,
    required String newTitle,
    required String newContent,
  }) {
    // 1. Character-level change
    final oldLength = (oldTitle + oldContent).length;
    final newLength = (newTitle + newContent).length;
    final lengthDiff = (newLength - oldLength).abs();

    // Too small change?
    if (lengthDiff < _minSignificantChange) {
      return _ChangeSignificance(
        isSignificant: false,
        reason: 'Only $lengthDiff chars changed (min: $_minSignificantChange)',
      );
    }

    // 2. Percentage change
    final changePercentage = oldLength > 0 ? lengthDiff / oldLength : 1.0;
    if (changePercentage < _minChangePercentage) {
      return _ChangeSignificance(
        isSignificant: false,
        reason:
            '${(changePercentage * 100).toStringAsFixed(1)}% changed (min: ${(_minChangePercentage * 100).toStringAsFixed(0)}%)',
      );
    }

    // 3. Word-level change (semantic)
    final oldWords = _extractWords(oldContent);
    final newWords = _extractWords(newContent);
    final addedWords = newWords.difference(oldWords).length;
    final removedWords = oldWords.difference(newWords).length;
    final totalWordChange = addedWords + removedWords;

    // Significant word change?
    if (totalWordChange > 10) {
      return _ChangeSignificance(
        isSignificant: true,
        reason: '$totalWordChange words changed (+$addedWords, -$removedWords)',
      );
    }

    // 4. Line-level change
    final oldLines =
        oldContent.split('\n').where((l) => l.trim().isNotEmpty).length;
    final newLines =
        newContent.split('\n').where((l) => l.trim().isNotEmpty).length;
    final lineDiff = (newLines - oldLines).abs();

    if (lineDiff > 3) {
      return _ChangeSignificance(
        isSignificant: true,
        reason: '$lineDiff lines changed',
      );
    }

    // Default: Significant if passed char/percentage checks
    return _ChangeSignificance(
      isSignificant: true,
      reason:
          '$lengthDiff chars, ${(changePercentage * 100).toStringAsFixed(1)}% changed',
    );
  }

  /// Extract unique words for semantic comparison
  Set<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // Ignore short words
        .toSet();
  }

  /// Generate MD5 hash for content comparison
  String _generateHash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// Cleanup session data
  void _cleanupSession(int noteId) {
    _sessionSnapshots.remove(noteId);
    _sessionStartTimes.remove(noteId);
  }

  /// Prune old versions (keep only newest X versions)
  Future<void> _pruneOldVersions(int noteId) async {
    await _db.keepMaxVersions(noteId, _maxVersionsPerNote);
  }

  /// Legacy support: Smart log version (for manual saves)
  Future<void> smartLogVersion({
    required int noteId,
    required String title,
    required String content,
    required bool isManualAction,
    bool isLocked = false,
    String noteType = 'simple',
    bool forceLog = false,
  }) async {
    // 🔒 SECURITY: Skip locked notes
    if (isLocked) return;

    // Only save manual actions (user explicitly saved)
    if (!isManualAction) return;

    // Check if different from last version
    final lastVersion = await _db.getLastNoteVersion(noteId);
    if (lastVersion != null && !forceLog) {
      final currentHash = _generateHash(title + content);
      final lastHash = _generateHash(lastVersion.title + lastVersion.content);
      if (currentHash == lastHash) return;
    }

    // ✅ Save manual version
    final newVersion = NoteVersion.create(
      noteId: noteId,
      title: title,
      content: content,
      timestamp: DateTime.now(),
      action: 'manual_save',
      noteType: noteType,
    );

    await _db.logNoteVersion(newVersion);
    await _pruneOldVersions(noteId);
  }
}

/// Change significance result
class _ChangeSignificance {
  final bool isSignificant;
  final String reason;

  _ChangeSignificance({
    required this.isSignificant,
    required this.reason,
  });
}
