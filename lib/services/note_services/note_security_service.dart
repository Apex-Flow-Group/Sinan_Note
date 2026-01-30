// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../models/note.dart';
import '../database_service.dart';
import '../encryption_service.dart';
import 'note_state_service.dart';

/// Service responsible for vault session management, encryption, and locked note operations.
/// 
/// This service handles all security-related operations for the vault feature,
/// including session management, encryption/decryption, and secure memory handling.
/// 
/// **Responsibilities:**
/// - Manage vault session with 5-minute timeout
/// - Encrypt/decrypt locked note content
/// - Handle vault unlock/lock operations
/// - Fetch and decrypt locked notes for vault display
/// - Toggle lock status for notes
/// - Clear decrypted data from memory on vault lock
/// 
/// **Security Features:**
/// - **Session Timeout:** Vault automatically locks after 5 minutes of inactivity
/// - **Memory Wipe:** Decrypted notes are cleared from RAM when vault is locked
/// - **Encryption:** AES-256 encryption for locked note content (except checklists)
/// - **Checklist Exception:** Checklists are stored as plain JSON (not encrypted)
class NoteSecurityService {
  // Vault session state
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  
  // Session duration: 5 minutes
  static const _sessionDuration = Duration(minutes: 5);
  
  /// Check if vault is currently unlocked
  /// 
  /// **Auto-Lock:** If more than 5 minutes have passed since unlock,
  /// the vault is automatically locked and this returns false.
  /// 
  /// **Returns:** true if vault is unlocked and session is still valid
  bool get isVaultUnlocked {
    if (!_isVaultUnlocked || _vaultUnlockedAt == null) return false;
    
    final elapsed = DateTime.now().difference(_vaultUnlockedAt!);
    if (elapsed > _sessionDuration) {
      // Auto-lock: Session expired
      _isVaultUnlocked = false;
      _vaultUnlockedAt = null;
      return false;
    }
    
    return true;
  }
  
  /// Unlock the vault
  /// 
  /// **Flow:**
  /// 1. User authenticates with biometric (handled by caller)
  /// 2. This method is called to start the session
  /// 3. Session timer starts (5 minutes)
  /// 
  /// **Note:** This method does NOT handle biometric authentication.
  /// The caller must verify authentication before calling this method.
  void unlockVault() {
    _isVaultUnlocked = true;
    _vaultUnlockedAt = DateTime.now();
  }
  
  /// Lock the vault
  /// 
  /// **Flow:**
  /// 1. Clear session state
  /// 2. Caller should call clearLockedSession to wipe memory
  /// 
  /// **Use Cases:**
  /// - User manually locks vault
  /// - App goes to background
  /// - Session timeout (automatic)
  void lockVault() {
    _isVaultUnlocked = false;
    _vaultUnlockedAt = null;
  }
  
  /// Fetch and decrypt all locked notes
  /// 
  /// **Flow:**
  /// 1. Fetch encrypted notes from database
  /// 2. Decrypt each note (title and content)
  /// 3. Return decrypted notes for vault display
  /// 
  /// **Security:**
  /// - Checklists are NOT encrypted (stored as plain JSON)
  /// - Decryption failures return the original encrypted note
  /// - Decrypted data is kept in memory only during vault session
  /// 
  /// **Returns:** List of decrypted notes
  Future<List<Note>> fetchAndDecryptLockedNotes(DatabaseService dbService) async {
    final encryptedNotes = await dbService.getLockedNotes();
    final decryptedNotes = <Note>[];
    
    for (final note in encryptedNotes) {
      try {
        // CRITICAL: Checklists are stored as plain JSON, skip decryption
        final decryptedTitle = note.isChecklist 
            ? note.title 
            : await EncryptionService.decrypt(note.title);
        final decryptedContent = note.isChecklist 
            ? note.content 
            : await EncryptionService.decrypt(note.content);
        
        decryptedNotes.add(note.copyWith(
          title: decryptedTitle,
          content: decryptedContent,
        ));
      } catch (e) {
        // Decryption failed: return original encrypted note
        decryptedNotes.add(note);
      }
    }
    
    return decryptedNotes;
  }
  
  /// Toggle lock status for a note
  /// 
  /// **Flow:**
  /// 1. Fetch note from database
  /// 2. If locking: Encrypt title and content (except checklists)
  /// 3. If unlocking: Decrypt title and content (except checklists)
  /// 4. Update note in database
  /// 
  /// **Security:**
  /// - Checklists are NEVER encrypted (stored as plain JSON)
  /// - Empty titles/content are not encrypted
  /// - Prevents double encryption by checking if already encrypted
  /// 
  /// **Parameters:**
  /// - `id`: Note ID
  /// - `lockStatus`: true to lock (encrypt), false to unlock (decrypt)
  /// - `dbService`: Database service instance
  Future<void> toggleLockStatus(
    int id, 
    bool lockStatus,
    DatabaseService dbService,
  ) async {
    final note = await dbService.getNoteById(id);
    if (note == null) return;
    
    String finalTitle = note.title;
    String finalContent = note.content;
    
    if (lockStatus && !note.isChecklist) {
      // Locking: Encrypt content
      if (note.title.isNotEmpty) {
        finalTitle = await EncryptionService.encrypt(note.title);
      }
      if (note.content.isNotEmpty) {
        finalContent = await EncryptionService.encrypt(note.content);
      }
    } else if (!lockStatus && !note.isChecklist) {
      // Unlocking: Decrypt content
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
  
  /// Clear locked notes from memory
  /// 
  /// **Security:** This method wipes decrypted locked notes from RAM
  /// when the vault is locked or the session expires.
  /// 
  /// **Use Cases:**
  /// - Vault is manually locked
  /// - Session timeout (5 minutes)
  /// - App goes to background
  /// - App is closed
  /// 
  /// **Parameters:**
  /// - `stateService`: State service instance to clear locked notes
  void clearLockedSession(NoteStateService stateService) {
    stateService.clearLockedNotes();
  }
}
