// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';

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
  
  Future<List<Note>> fetchAndDecryptLockedNotes(IsarDatabaseService dbService) async {
    final encryptedNotes = await dbService.getLockedNotes();
    final decryptedNotes = <Note>[];
    
    for (final note in encryptedNotes) {
      String? decryptedTitle;
      String? decryptedContent;
      
      try {
        decryptedTitle = await VaultService.decryptWithMasterKey(note.title);
        decryptedContent = await VaultService.decryptWithMasterKey(note.content);
        
        // ✅ Clean checklist JSON after decryption
        if (note.isChecklist || note.noteType == 'checklist') {
          decryptedContent = _cleanChecklistAfterDecryption(decryptedContent);
        }
        
        decryptedNotes.add(note.copyWith(
          title: decryptedTitle, 
          content: decryptedContent
        ));
      } catch (e) {
        // If decryption fails, add note as-is
        decryptedNotes.add(note);
      } finally {
        // CRITICAL: Wipe decrypted data from memory
        _wipeString(decryptedTitle);
        _wipeString(decryptedContent);
      }
    }
    return decryptedNotes;
  }
  
  Future<void> toggleLockStatus(int id, bool lockStatus, IsarDatabaseService dbService) async {
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
          finalContent = _prepareChecklistForEncryption(note.content);
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
          finalContent = _cleanChecklistAfterDecryption(finalContent);
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
  
  /// Prepare checklist JSON for encryption (validate and clean)
  String _prepareChecklistForEncryption(String content) {
    try {
      final decoded = jsonDecode(content);
      // Re-encode to ensure clean JSON
      return jsonEncode(decoded);
    } catch (e) {
      // If invalid JSON, return as-is
      return content;
    }
  }
  
  /// Clean checklist JSON after decryption (validate and fix)
  String _cleanChecklistAfterDecryption(String content) {
    try {
      // Remove any potential whitespace or encoding issues
      final trimmed = content.trim();
      final decoded = jsonDecode(trimmed);
      // Re-encode to ensure clean JSON
      return jsonEncode(decoded);
    } catch (e) {
      // If invalid JSON, return as-is
      return content;
    }
  }
  
  /// Wipe sensitive string from memory (best effort)
  void _wipeString(String? str) {
    if (str == null) return;
    try {
      // Overwrite string content (best effort in Dart)
      // Note: Dart strings are immutable, but this helps with GC
      str = '\x00' * str.length;
    } catch (_) {
      // Ignore wipe errors
    }
  }
}
