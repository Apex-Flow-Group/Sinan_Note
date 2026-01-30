// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/utils/logger.dart';
import 'storage/isar_database_service.dart';
import '../../models/note_version.dart';

/// Smart Version Control Service
/// Implements 3 intelligence gates to prevent data obesity
class VersionControlService {
  // Intelligence settings
  static const int _minCharsChange = 15; // Minimum change threshold
  static const int _minTimeSeconds = 300; // 5 minutes between auto-saves
  static const int _maxVersionsPerNote = 20; // Maximum versions to keep

  final IsarDatabaseService _db = IsarDatabaseService();

  /// Main function to replace direct logNoteVersion calls
  /// Applies 3 intelligence gates before saving
  Future<void> smartLogVersion({
    required int noteId,
    required String title,
    required String content,
    required bool isManualAction,
  }) async {
    // 1. Generate content hash (fingerprint)
    final String currentHash = _generateHash(title + content);

    // 2. Get last version to check if save is needed
    final lastVersion = await _db.getLastNoteVersion(noteId);

    if (lastVersion != null) {
      // Gate A: Duplication check - Is content identical?
      final String lastHash = _generateHash(lastVersion.title + lastVersion.content);
      if (currentHash == lastHash) {
        AppLogger.debug('Version skipped: Content identical', 'VersionControl');
        return;
      }

      // Gate B: Importance filter (auto-save only)
      if (!isManualAction) {
        final timeDiff = DateTime.now().difference(lastVersion.timestamp).inSeconds;
        final contentDiff = (content.length - lastVersion.content.length).abs();

        // Skip if change is too small and time is too short
        if (timeDiff < _minTimeSeconds && contentDiff < _minCharsChange) {
          AppLogger.debug('Version skipped: Minor change ($contentDiff chars) in short time', 'VersionControl');
          return;
        }
      }
    }

    // ✅ Passed all gates: Create new version
    final newVersion = NoteVersion.create(
      noteId: noteId,
      title: title,
      content: content,
      timestamp: DateTime.now(),
      action: isManualAction ? 'manual_save' : 'auto_save',
    );

    await _db.logNoteVersion(newVersion);
    AppLogger.success('Smart version saved (${isManualAction ? 'manual' : 'auto'})', 'VersionControl');

    // 3. Auto-cleanup: Remove old versions
    await _pruneOldVersions(noteId);
  }

  /// Generate MD5 hash for content comparison
  String _generateHash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// Prune old versions (keep only newest X versions)
  Future<void> _pruneOldVersions(int noteId) async {
    await _db.keepMaxVersions(noteId, _maxVersionsPerNote);
  }
}
