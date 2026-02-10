🔐 تقرير شامل: نظام الخزنة والتشفير والمزامنة مع Google Drive
📋 جدول المحتويات
نظرة عامة
نظام التشفير
نظام الخزنة (Vault)
المزامنة مع Google Drive
المشاكل الحرجة
الحلول المقترحة
🎯 نظرة عامة
البنية الحالية
التطبيق يستخدم نظامين منفصلين للتشفير:

النظام القديم (EncryptionService):

تشفير AES-256 بسيط
مفتاح واحد مخزن في FlutterSecureStorage
يستخدم للملاحظات المقفلة القديمة
النظام الجديد (VaultService):

نظام خزنة متقدم مع Recovery Code
Master Key مشفر بكلمة المرور
دعم البصمة البيومترية
نظام استرجاع متقدم
🔐 نظام التشفير
1. EncryptionService (النظام القديم)
الموقع: 
encryption_service.dart

الآلية:

// توليد/استرجاع المفتاح
static Future<Key> _getOrCreateKey() async {
  String? keyString = await _storage.read(key: 'sinan_vault_key');
  if (keyString == null) {
    final key = Key.fromSecureRandom(32); // 32 bytes = AES-256
    await _storage.write(key: 'sinan_vault_key', value: key.base64);
    return key;
  }
  return Key.fromBase64(keyString);
}

// التشفير
static Future<String> encrypt(String plainText) async {
  final key = await _getOrCreateKey();
  final iv = IV.fromSecureRandom(16); // IV عشوائي لكل عملية
  final encrypter = Encrypter(AES(key));
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  return '${iv.base64}:${encrypted.base64}'; // صيغة: "iv:ciphertext"
}
المميزات:

✅ تشفير AES-256 قوي
✅ IV عشوائي لكل عملية (يمنع تحليل الأنماط)
✅ المفتاح محمي في Android Keystore
العيوب:

❌ لا يوجد نظام استرجاع
❌ مفتاح واحد فقط
❌ لا يدعم تغيير كلمة المرور
❌ لا يوجد Recovery Code
2. VaultService (النظام الجديد)
الموقع: 
vault_service.dart

الآلية المتقدمة:

// إنشاء الخزنة
static Future<String> setupVault(String password) async {
  // 1. توليد Master Key (32 bytes)
  final masterKey = Key.fromSecureRandom(32);
  
  // 2. توليد Recovery Code (SN-XXXX-XXXX-XXXX)
  final recoveryCode = generateRecoveryCode();
  
  // 3. تشفير Master Key بكلمة المرور
  final encryptedWithPassword = await _encryptMasterKey(masterKey, password);
  
  // 4. تشفير Master Key بـ Recovery Code
  final encryptedWithRecovery = await _encryptMasterKey(masterKey, recoveryCode);
  
  // 5. حفظ النسختين المشفرتين
  await _storage.write(key: 'vault_master_key_password', value: encryptedWithPassword);
  await _storage.write(key: 'vault_master_key_recovery', value: encryptedWithRecovery);
  
  // 6. حفظ Hash للتحقق
  await _storage.write(key: 'vault_password_hash', value: _hash(password));
  await _storage.write(key: 'vault_recovery_hash', value: _hash(recoveryCode));
  
  return recoveryCode;
}
المميزات:

✅ Master Key محمي بطريقتين (Password + Recovery Code)
✅ نظام استرجاع متقدم
✅ دعم تغيير كلمة المرور
✅ دعم البصمة البيومترية
✅ Recovery Code بصيغة SN-XXXX-XXXX-XXXX
العيوب:

⚠️ لا يتم رفع Master Key إلى Google Drive
⚠️ لا يتم رفع Recovery Code إلى Google Drive
⚠️ عند تنزيل Backup من Drive، لا يمكن فك التشفير
🗄️ نظام الخزنة (Vault)
البنية الهرمية
┌─────────────────────────────────────────┐
│         VaultEntryScreen                │
│  (نقطة الدخول - تحديد المسار)           │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌─────────────┐   ┌──────────────────┐
│ Setup Vault │   │ Unlock Vault     │
│ (جديد)      │   │ (موجود)         │
└─────────────┘   └──────────────────┘
                          │
                  ┌───────┴────────┐
                  │                │
                  ▼                ▼
          ┌──────────────┐  ┌─────────────┐
          │ Password     │  │ Biometric   │
          └──────────────┘  └─────────────┘
                  │                │
                  └────────┬───────┘
                           ▼
                  ┌──────────────────┐
                  │ LockedNotesScreen│
                  └──────────────────┘
الشاشات الرئيسية
1. VaultEntryScreen
الوظيفة: تحديد المسار المناسب

Future<void> _checkVaultStatus() async {
  final hasNewVault = await VaultService.isVaultSetup();
  
  if (!hasNewVault) {
    // لا توجد خزنة → إنشاء جديدة
    Navigator.push(context, LockedNotesIntroScreen());
  } else {
    // توجد خزنة → فتح
    final biometricEnabled = await VaultService.isBiometricEnabled();
    if (biometricEnabled) {
      await _authenticateWithBiometric();
    } else {
      Navigator.push(context, VaultUnlockScreen());
    }
  }
}
2. VaultUnlockScreen
الوظيفة: فتح الخزنة بكلمة المرور أو Recovery Code

الأوضاع:

Password Mode: إدخال كلمة المرور
Recovery Mode: إدخال Recovery Code
New Password Mode: تعيين كلمة مرور جديدة بعد الاسترجاع
3. LockedNotesScreen
الوظيفة: عرض وإدارة الملاحظات المقفلة

المميزات:

إنشاء ملاحظات مقفلة جديدة
استيراد ملاحظات من القائمة الرئيسية
فتح قفل الملاحظات
إعدادات الخزنة (تغيير كلمة المرور، تفعيل البصمة)
☁️ المزامنة مع Google Drive
الموقع
google_drive_service.dart

الوظائف الحالية
1. رفع قاعدة البيانات
static Future<bool> uploadDatabase(
  dynamic context, 
  {bool uploadMasterKey = false, bool uploadVault = false}
) async {
  // 1. جلب جميع الملاحظات
  final notes = await dbService.getAllNotes();
  
  // 2. تحويل إلى JSON
  final json = jsonEncode(notes.map((n) => n.toMap()).toList());
  
  // 3. رفع إلى Drive
  final media = drive.Media(backupFile.openRead(), await backupFile.length());
  await _driveApi!.files.create(driveFile, uploadMedia: media);
  
  // ⚠️ TODO: Implement master key and vault upload logic
  if (uploadMasterKey) {
    AppLogger.info('Master key upload requested', 'GoogleDrive');
  }
  if (uploadVault) {
    AppLogger.info('Vault upload requested', 'GoogleDrive');
  }
}
المشكلة الحرجة:

// TODO: Implement master key and vault upload logic
لا يتم رفع Master Key أو معلومات الخزنة!

2. تنزيل قاعدة البيانات
static Future<bool> downloadDatabase(dynamic context) async {
  // 1. تنزيل الملف من Drive
  final response = await _driveApi!.files.get(file.id!, downloadOptions: ...);
  
  // 2. قراءة JSON
  final json = await tempFile.readAsString();
  final List<dynamic> data = jsonDecode(json);
  
  // 3. حفظ في قاعدة البيانات
  await isar.writeTxn(() async {
    await isar.notes.clear();
    for (var noteMap in data) {
      final note = Note.fromMap(noteMap);
      await isar.notes.put(note);
    }
  });
}
المشكلة:

الملاحظات المقفلة مشفرة بـ Master Key
عند التنزيل على جهاز جديد، لا يوجد Master Key
النتيجة: لا يمكن فك تشفير الملاحظات المقفلة
3. الدمج الذكي
static Future<bool> mergeWithDrive(
  dynamic context, 
  {bool uploadMasterKey = false, bool uploadVault = false}
) async {
  // 1. تنزيل من Drive
  final driveNotes = await _downloadNotesFromDrive();
  
  // 2. جلب المحلية
  final localNotes = await dbService.getAllNotes();
  
  // 3. عرض Dialog للمستخدم
  final action = await _showMergeDialog(context, localNotes.length, driveNotes.length);
  
  // 4. تنفيذ الإجراء
  if (action == 'merge') {
    // دمج ذكي: أخذ الأحدث من كل ملاحظة
    final Map<int, Note> mergedMap = {};
    for (var note in localNotes) {
      mergedMap[note.id!] = note;
    }
    for (var driveNote in driveNotes) {
      if (mergedMap.containsKey(driveNote.id!)) {
        if (driveNote.updatedAt.isAfter(mergedMap[driveNote.id!]!.updatedAt)) {
          mergedMap[driveNote.id!] = driveNote;
        }
      } else {
        mergedMap[driveNote.id!] = driveNote;
      }
    }
  }
}
⚠️ المشاكل الحرجة
1. عدم رفع Master Key إلى Drive
الكود الحالي:

// TODO: Implement master key and vault upload logic
if (uploadMasterKey) {
  AppLogger.info('Master key upload requested', 'GoogleDrive');
}
السيناريو الكارثي:

المستخدم ينشئ خزنة على الجهاز A
يضيف 100 ملاحظة مقفلة
يرفع Backup إلى Drive
يفتح التطبيق على الجهاز B
ينزل Backup من Drive
النتيجة: الملاحظات المقفلة مشفرة ولا يمكن فك تشفيرها!
2. تعارض الخزنات (Vault Conflict)
الشاشة: VaultConflictScreen

السيناريو:

الجهاز A: خزنة بـ Master Key #1
الجهاز B: خزنة بـ Master Key #2
Drive: ملاحظات مشفرة بـ Master Key #1
الحل الحالي:

// TODO: Implement these methods with actual Drive API
Future<bool> _verifyOldRecoveryCode(String code) async {
  await Future.delayed(const Duration(seconds: 1));
  return true; // Placeholder
}
المشكلة: الحل غير مكتمل!

3. عدم تخزين Recovery Code في Drive
المشكلة:

Recovery Code يُعرض مرة واحدة فقط عند إنشاء الخزنة
إذا فقد المستخدم الكود، لا يمكن استرجاعه
لا يتم رفعه إلى Drive
💡 الحلول المقترحة
الحل 1: رفع Master Key المشفر إلى Drive
الفكرة: رفع Master Key مشفر بـ Recovery Code

static Future<bool> uploadVaultData(String recoveryCode) async {
  // 1. قراءة Master Key المشفر بـ Recovery Code
  final encryptedMasterKey = await _storage.read(key: 'vault_master_key_recovery');
  
  // 2. إنشاء ملف vault_data.json
  final vaultData = {
    'version': '2.0',
    'encrypted_master_key': encryptedMasterKey,
    'recovery_hash': await _storage.read(key: 'vault_recovery_hash'),
    'created_at': DateTime.now().toIso8601String(),
  };
  
  // 3. رفع إلى Drive
  final json = jsonEncode(vaultData);
  final tempFile = File('${tempDir.path}/vault_data.json');
  await tempFile.writeAsString(json);
  
  final media = drive.Media(tempFile.openRead(), await tempFile.length());
  final driveFile = drive.File()
    ..name = 'vault_data.json'
    ..mimeType = 'application/json';
  
  await _driveApi!.files.create(driveFile, uploadMedia: media);
  
  return true;
}
المميزات:

✅ Master Key محمي بـ Recovery Code
✅ يمكن استرجاعه على أي جهاز
✅ آمن (يحتاج Recovery Code لفك التشفير)
الحل 2: تنزيل واسترجاع Master Key
static Future<bool> downloadAndRestoreVault(String recoveryCode) async {
  // 1. تنزيل vault_data.json من Drive
  final file = await _findFile('vault_data.json');
  if (file == null) throw Exception('No vault data found');
  
  final response = await _driveApi!.files.get(file.id!, downloadOptions: ...);
  final json = await tempFile.readAsString();
  final vaultData = jsonDecode(json);
  
  // 2. التحقق من Recovery Code
  final storedHash = vaultData['recovery_hash'];
  if (storedHash != _hash(recoveryCode)) {
    throw Exception('Invalid recovery code');
  }
  
  // 3. فك تشفير Master Key
  final encryptedMasterKey = vaultData['encrypted_master_key'];
  final masterKey = await _decryptMasterKey(encryptedMasterKey, recoveryCode);
  
  // 4. حفظ Master Key محلياً
  await _storage.write(key: 'vault_master_key', value: masterKey.base64);
  
  // 5. طلب كلمة مرور جديدة
  // (يتم في VaultMigrationScreen)
  
  return true;
}
الحل 3: دمج الخزنات (Vault Merge)
السيناريو: جهازين بخزنات مختلفة

static Future<bool> mergeVaults({
  required String localRecoveryCode,
  required String driveRecoveryCode,
}) async {
  // 1. فك تشفير الملاحظات المحلية
  final localNotes = await _decryptNotesWithRecoveryCode(localRecoveryCode);
  
  // 2. تنزيل وفك تشفير ملاحظات Drive
  final driveNotes = await _downloadAndDecryptNotesFromDrive(driveRecoveryCode);
  
  // 3. دمج الملاحظات
  final mergedNotes = _mergeNotesByTimestamp(localNotes, driveNotes);
  
  // 4. إنشاء Master Key جديد
  final newMasterKey = Key.fromSecureRandom(32);
  final newRecoveryCode = VaultService.generateRecoveryCode();
  
  // 5. إعادة تشفير جميع الملاحظات بالمفتاح الجديد
  final reEncryptedNotes = await _reEncryptNotes(mergedNotes, newMasterKey);
  
  // 6. حفظ محلياً
  await _saveNotes(reEncryptedNotes);
  
  // 7. رفع إلى Drive
  await uploadVaultData(newRecoveryCode);
  await uploadDatabase(context, uploadMasterKey: true, uploadVault: true);
  
  return true;
}
الحل 4: نظام النسخ الاحتياطي المشفر
الفكرة: رفع نسخة احتياطية مشفرة بـ Recovery Code

static Future<bool> createEncryptedBackup(String recoveryCode) async {
  // 1. جلب جميع الملاحظات المقفلة (مشفرة)
  final lockedNotes = await dbService.getLockedNotes();
  
  // 2. إنشاء حزمة Backup
  final backupData = {
    'version': '2.0',
    'timestamp': DateTime.now().toIso8601String(),
    'vault_data': {
      'encrypted_master_key': await _storage.read(key: 'vault_master_key_recovery'),
      'recovery_hash': await _storage.read(key: 'vault_recovery_hash'),
    },
    'notes': lockedNotes.map((n) => n.toMap()).toList(),
  };
  
  // 3. تشفير الحزمة بـ Recovery Code
  final json = jsonEncode(backupData);
  final encryptedBackup = await _encryptWithRecoveryCode(json, recoveryCode);
  
  // 4. رفع إلى Drive
  await _uploadEncryptedBackup(encryptedBackup);
  
  return true;
}
🎯 خطة التنفيذ المقترحة
المرحلة 1: إصلاح رفع Master Key (أولوية عالية)
تعديل uploadDatabase() لرفع vault_data.json
تخزين Master Key المشفر بـ Recovery Code
اختبار الرفع والتنزيل
المرحلة 2: إصلاح التنزيل والاسترجاع
تعديل downloadDatabase() للتحقق من وجود vault_data.json
إضافة شاشة طلب Recovery Code
فك تشفير Master Key واستعادته
المرحلة 3: حل تعارض الخزنات
إكمال VaultConflictScreen
تنفيذ دمج الخزنات
اختبار السيناريوهات المختلفة
المرحلة 4: تحسينات الأمان
تشفير Recovery Code في Drive
إضافة نظام نسخ احتياطي متعدد
إضافة تحذيرات للمستخدم
📊 ملخص الحالة الحالية
المكون	الحالة	الملاحظات
EncryptionService	✅ يعمل	نظام قديم، بسيط
VaultService	✅ يعمل	نظام جديد، متقدم
رفع Master Key	❌ غير مكتمل	TODO في الكود
تنزيل Master Key	❌ غير موجود	يحتاج تنفيذ
دمج الخزنات	⚠️ جزئي	Placeholder فقط
Recovery Code	✅ يعمل	محلياً فقط
البصمة البيومترية	✅ يعمل	كامل
تغيير كلمة المرور	✅ يعمل	كامل
🚨 التحذيرات الهامة
⚠️ خطر فقدان البيانات
السيناريو الحالي:

المستخدم → ينشئ خزنة → يضيف ملاحظات → يرفع Backup
         ↓
    يفقد الجهاز
         ↓
    يحمل التطبيق على جهاز جديد
         ↓
    ينزل Backup من Drive
         ↓
    ❌ لا يمكن فك تشفير الملاحظات المقفلة!
⚠️ عدم توافق الأجهزة المتعددة
المشكلة:

كل جهاز ينشئ Master Key خاص به
الملاحظات المقفلة لا تتزامن بشكل صحيح
تعارضات عند الدمج
✅ التوصيات النهائية
للتنفيذ الفوري:
إكمال رفع Master Key (أولوية قصوى)
إضافة شاشة استرجاع Recovery Code عند التنزيل
تحذير المستخدم بحفظ Recovery Code
للتحسين المستقبلي:
نظام نسخ احتياطي متعدد المستويات
تشفير end-to-end للمزامنة
دعم أجهزة متعددة بنفس الخزنة
تم إعداد التقرير بواسطة: Kiro AI
التاريخ: 10 فبراير 2026
الحالة: جاهز للتنفيذ 🚀