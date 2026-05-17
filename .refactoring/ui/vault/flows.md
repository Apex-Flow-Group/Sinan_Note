# 🗺️ خرائط تدفق الخزنة الكاملة

## خريطة الشاشات والانتقالات

```
SplashScreen
    │
    ├── (vault locked + biometric) ──► VaultEntryScreen
    │                                       │
    │                                       ├── (vault not setup) ──► LockedNotesIntroScreen
    │                                       │                              │
    │                                       │                              └── (setup done) ──► LockedNotesScreen
    │                                       │
    │                                       ├── (biometric enabled) ──► PinLockScreen / BiometricAuth
    │                                       │                              │
    │                                       │                              └── (success) ──► LockedNotesScreen
    │                                       │
    │                                       └── (password only) ──► VaultUnlockScreen
    │                                                                    │
    │                                                                    ├── (password ok) ──► LockedNotesScreen
    │                                                                    ├── (forgot) ──► recovery mode
    │                                                                    └── (recovery ok) ──► new password mode ──► LockedNotesScreen
    │
    └── (normal) ──► MainLayoutScreen
                          │
                          └── (vault icon) ──► VaultEntryScreen (نفس المسار أعلاه)
```

---

## تدفق إنشاء ملاحظة مقفلة

```
LockedNotesScreen._createLockedNote(mode)
    │
    ▼
NoteEditorImmersive(skipAuthentication: true, isLocked: true)
    │
    ▼ (حفظ)
NotesProvider.addNote(note)
    │ note.isLocked && content.isNotEmpty
    ▼
VaultService.encryptWithMasterKey(title)   ← يقرأ المفتاح من FlutterSecureStorage
VaultService.encryptWithMasterKey(content) ← يمسح المفتاح من الذاكرة بعدها
    │
    ▼
SqliteDatabaseService.insertNote(encryptedNote)
    │
    ▼
NoteStateService.addNote(note) ← يضيف للـ _lockedNotes (ليس _allNotes)
    │
    ▼
notifyListeners()
    │
    ▼
LockedNotesScreen._loadLockedNotes() ← يُعيد جلب وفك تشفير كل الملاحظات
```

---

## تدفق قراءة الملاحظات المقفلة

```
LockedNotesScreen._loadLockedNotes()
    │
    ▼
NotesProvider.fetchAndDecryptLockedNotes()
    │
    ▼
NoteSecurityService.fetchAndDecryptLockedNotes(_dbService)
    │
    ▼
SqliteDatabaseService.getLockedNotes() ← كل الملاحظات المشفرة من DB
    │
    ▼
VaultService.getMasterKey() ← قراءة واحدة فقط للمفتاح
    │
    ▼ (Future.wait — متوازي)
_decryptNoteWithKey(note, masterKey) × N
    │ VaultService.decryptWithKey(title, masterKey)  ← sync
    │ VaultService.decryptWithKey(content, masterKey) ← sync
    │ _normalizeChecklistJson() إذا كانت checklist
    ▼
VaultService.wipeMasterKey(masterKey) ← مسح المفتاح من الذاكرة
    │
    ▼
List<Note> decryptedNotes → LockedNotesScreen._decryptedNotes
```

---

## تدفق إعادة تعيين الخزنة (VaultResetService)

```
VaultResetScreen
    │
    ├── Step 1: تحقق بكلمة المرور الحالية
    │
    ├── Step 2: كلمة مرور جديدة
    │
    └── Step 3: executeReset(newPassword)
                    │
                    ├── 1. نسخ DB احتياطياً (backup_TIMESTAMP.isar)
                    ├── 2. قراءة المفتاح القديم
                    ├── 3. جلب كل الملاحظات المشفرة
                    ├── 4. فك تشفير كل الملاحظات (بالمفتاح القديم)
                    ├── 5. مسح المفتاح القديم من الذاكرة
                    ├── 6. VaultService.setupVault(newPassword) ← PBKDF2 ثقيل
                    ├── 7. إعادة تشفير كل الملاحظات (بالمفتاح الجديد)
                    ├── 8. مسح المفتاح الجديد من الذاكرة
                    └── 9. عرض كود الاسترداد الجديد
                    
                    ⚠️ عند الفشل: استعادة DB من النسخة الاحتياطية
```

---

## تدفق قفل التطبيق (SecurityController)

```
AppLifecycleState.paused
    │
    ▼
SecurityController._handlePause()
    │ يحفظ _pausedTime
    ▼
AppLifecycleState.resumed
    │
    ▼
SecurityController._handleResume()
    │ elapsed = now - _pausedTime
    │ if elapsed >= lockDelaySeconds → _isLocked = true → notifyListeners()
    ▼
MainLayoutScreen._onSecurityChanged()
    │ if isLocked → Navigator.pushReplacement(SplashScreen)
    ▼
SplashScreen → VaultEntryScreen (إذا كانت الخزنة مفتوحة)
```

---

## تدفق PIN + Rate Limiter

```
PinLockScreen._onPinComplete()
    │
    ├── (setup mode) ──► UnifiedLockService.setPin(pin) ← PBKDF2 100k iterations
    │
    └── (verify mode)
            │
            ▼
        RateLimiterService.getRemainingLockTime()
            │ locked? → عرض الوقت المتبقي
            │ not locked?
            ▼
        UnifiedLockService.verifyPin(pin) ← PBKDF2 100k iterations
            │
            ├── (valid) ──► RateLimiterService.reset() → markAuthenticated() → onSuccess()
            │
            └── (invalid) ──► RateLimiterService.recordFailedAttempt()
                                    │
                                    ├── attempts < 5 → عرض المحاولات المتبقية
                                    └── attempts >= 5 → قفل 5/15/60 دقيقة
```
