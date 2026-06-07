// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';import 'package:encrypt/encrypt.dart'; import 'package:sinan_note/models/note.dart'; import 'package:sinan_note/services/note_services/note_db_interface.dart'; import 'package:sinan_note/services/note_services/note_state_service.dart'; import 'package:sinan_note/services/security/vault_service.dart';
class NoteSecurityService {
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  static const _sessionDuration = Duration(minutes: 5);

  bool get isVaultUnlocked {
    if (!_isVaultUnlocked || _vaultUnlockedAt == null) return false;
    final elapsed = DateTime.now().difference(_vaultUnlockedAt!);
    if (elapsed > _sessionDuration) {
      _isVaultUnlocked = false;
      _vaultUnlockedAt = null;
      return false;
    }
    return true;
  }

  void unlockVault() {
    _isVaultUnlocked = true;
    _vaultUnlockedAt = DateTime.now();
  }

  void lockVault() {
    _isVaultUnlocked = false;
    _vaultUnlockedAt = null;
  }

  Future<List<Note>> fetchAndDecryptLockedNotes(
      NoteDbInterface dbService) async {
    final encryptedNotes = await dbService.getLockedNotes();
    if (encryptedNotes.isEmpty) return [];

    // قراءة المفتاح مرة واحدة فقط — بدل من قراءته لكل نوت
    Key? masterKey;
    try {
      masterKey = await VaultService.getMasterKey();
    } catch (_) {
      return encryptedNotes;
    }

    // فك التشفير بشكل متوازي بنفس المفتاح
    final results = await Future.wait(
      encryptedNotes.map((note) => _decryptNoteWithKey(note, masterKey!)),
    );

    VaultService.wipeMasterKey(masterKey);
    return results;
  }

  Future<Note> _decryptNoteWithKey(Note note, Key masterKey) async {
    try {
      final decryptedTitle = VaultService.decryptWithKey(note.title, masterKey);
      var decryptedContent =
          VaultService.decryptWithKey(note.content, masterKey);

      if (note.isChecklist || note.noteType == 'checklist') {
        decryptedContent = _normalizeChecklistJson(decryptedContent);
      }

      return note.copyWith(title: decryptedTitle, content: decryptedContent);
    } catch (_) {
      return note;
    }
  }

  Future<void> toggleLockStatus(
      int id, bool lockStatus, NoteDbInterface dbService) async {
    final note = await dbService.getNoteById(id);
    if (note == null) return;

    String finalTitle = note.title;
    String finalContent = note.content;

    if (lockStatus) {
      // 🔒 Encrypting
      if (note.title.isNotEmpty) {
        finalTitle = await VaultService.encryptWithMasterKey(note.title);
      }
      if (note.content.isNotEmpty) {
        // ✅ For checklist: validate JSON before encryption
        if (note.isChecklist || note.noteType == 'checklist') {
          finalContent = _normalizeChecklistJson(note.content);
        }
        finalContent = await VaultService.encryptWithMasterKey(finalContent);
      }
    } else {
      // 🔓 Decrypting
      if (note.title.isNotEmpty) {
        finalTitle = await VaultService.decryptWithMasterKey(note.title);
      }
      if (note.content.isNotEmpty) {
        finalContent = await VaultService.decryptWithMasterKey(note.content);
        // ✅ For checklist: validate JSON after decryption
        if (note.isChecklist || note.noteType == 'checklist') {
          finalContent = _normalizeChecklistJson(finalContent);
        }
      }
    }

    final updatedNote = note.copyWith(
      title: finalTitle,
      content: finalContent,
      isLocked: lockStatus,
      updatedAt: DateTime.now(),
    );

    await dbService.updateNote(updatedNote);
  }

  void clearLockedSession(NoteStateService stateService) {
    stateService.clearLockedNotes();
  }

  /// Normalize checklist JSON: decode then re-encode to ensure clean format.
  /// Trims whitespace before decoding (handles post-decryption artifacts).
  String _normalizeChecklistJson(String content) {
    try {
      final decoded = jsonDecode(content.trim());
      return jsonEncode(decoded);
    } catch (_) {
      return content;
    }
  }
}

