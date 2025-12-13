// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../models/note_version.dart';
import '../../../services/database_service.dart';
import '../../../services/encryption_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/notes_provider.dart';

/// Handles all storage operations (save, load, encryption)
class EditorStorageController {
  final DatabaseService _db = DatabaseService();

  /// Convert Color to int (ARGB) - avoids deprecated .value
  int _colorToInt(Color color) {
    final int a = (color.a * 255).round();
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Load sticky settings from SharedPreferences
  Future<Map<String, dynamic>> loadStickySettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fontSize': prefs.getDouble('last_font_size') ?? 18.0,
      'noteColorIndex': prefs.getInt('last_note_color'),
    };
  }

  /// Save sticky settings to SharedPreferences
  Future<void> saveStickySettings({
    required double fontSize,
    required Color backgroundColor,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_font_size', fontSize);
      await prefs.setInt('last_note_color', _colorToInt(backgroundColor));
    } catch (e) {
      debugPrint('❌ Failed to save sticky settings: $e');
    }
  }

  /// Authenticate user for locked notes
  Future<Map<String, String>?> authenticateAndDecrypt(Note note) async {
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) return null;

    // CRITICAL: Checklists are plain JSON, skip decryption
    final decryptedTitle = note.isChecklist ? note.title : await EncryptionService.decrypt(note.title);
    final decryptedContent = note.isChecklist ? note.content : await EncryptionService.decrypt(note.content);

    return {
      'title': decryptedTitle,
      'content': decryptedContent,
    };
  }

  /// Decrypt note without authentication (for active vault session)
  Future<Map<String, String>?> decryptNoteWithoutAuth(Note note) async {
    try {
      // CRITICAL: Checklists are plain JSON, skip decryption
      final decryptedTitle = note.isChecklist ? note.title : await EncryptionService.decrypt(note.title);
      final decryptedContent = note.isChecklist ? note.content : await EncryptionService.decrypt(note.content);

      return {
        'title': decryptedTitle,
        'content': decryptedContent,
      };
    } catch (e) {
      debugPrint('❌ Decryption failed: $e');
      return null;
    }
  }

  /// Save note to database
  Future<int?> saveNoteToDatabase({
    required String content,
    required String title,
    required Color backgroundColor,
    required String noteType,
    required bool isLocked,
    required NotesProvider provider,
    DateTime? reminderDateTime,
    String? recurrenceRule,
    int? existingNoteId,
    Note? existingNote,
    NoteMode? mode,
  }) async {
    // Encrypt if locked
    String finalTitle = title;
    String finalContent = content;

    if (isLocked) {
      if (title.isNotEmpty) {
        finalTitle = await EncryptionService.encrypt(title);
      }
      if (content.isNotEmpty) {
        finalContent = await EncryptionService.encrypt(content);
      }
    }

    final note = Note(
      id: existingNoteId ?? existingNote?.id,
      title: finalTitle,
      content: finalContent,
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: _colorToInt(backgroundColor),
      isLocked: isLocked,
      noteType: noteType,
      reminderDateTime: reminderDateTime,
      recurrenceRule: recurrenceRule,
      isArchived: existingNote?.isArchived ?? false,
      isTrashed: existingNote?.isTrashed ?? false,
      isCompleted: existingNote?.isCompleted ?? false,
      isProfessional: existingNote?.isProfessional ?? (mode == NoteMode.code),
      isPinned: existingNote?.isPinned ?? false,
      isChecklist: existingNote?.isChecklist ?? (mode == NoteMode.checklist),
    );

    if (existingNoteId != null || existingNote != null) {
      final noteId = existingNoteId ?? existingNote!.id!;
      final version = NoteVersion(
        noteId: noteId,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        action: 'update',
      );
      await _db.logNoteVersion(version);
      await provider.updateNote(note);
      return noteId;
    } else {
      final newId = await provider.addNote(note);
      final version = NoteVersion(
        noteId: newId,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        action: 'create',
      );
      await _db.logNoteVersion(version);
      return newId;
    }
  }
}
