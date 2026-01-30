// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../models/note.dart';
import '../storage/isar_database_service.dart';
import '../security/encryption_service.dart';
import 'note_state_service.dart';

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
      try {
        final decryptedTitle = note.isChecklist ? note.title : await EncryptionService.decrypt(note.title);
        final decryptedContent = note.isChecklist ? note.content : await EncryptionService.decrypt(note.content);
        decryptedNotes.add(note.copyWith(title: decryptedTitle, content: decryptedContent));
      } catch (e) {
        decryptedNotes.add(note);
      }
    }
    return decryptedNotes;
  }
  
  Future<void> toggleLockStatus(int id, bool lockStatus, IsarDatabaseService dbService) async {
    final note = await dbService.getNoteById(id);
    if (note == null) return;
    
    String finalTitle = note.title;
    String finalContent = note.content;
    
    if (lockStatus && !note.isChecklist) {
      if (note.title.isNotEmpty) finalTitle = await EncryptionService.encrypt(note.title);
      if (note.content.isNotEmpty) finalContent = await EncryptionService.encrypt(note.content);
    } else if (!lockStatus && !note.isChecklist) {
      finalTitle = await EncryptionService.decrypt(note.title);
      finalContent = await EncryptionService.decrypt(note.content);
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
}
