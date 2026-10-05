// Copyright © 2025 Apex Flow Group. All rights reserved.

/// أخطاء المجال المُنمّطة. طبقة البيانات ترميها، والواجهة تترجمها لنصوص
/// المستخدم من ملفات .arb — لا نصوص معروضة هنا.
class NoteException implements Exception {
  const NoteException(this.message, [this.originalError]);

  /// وصف تقني للسجلات، لا للمستخدم.
  final String message;
  final Object? originalError;

  @override
  String toString() =>
      '$runtimeType: $message${originalError != null ? ' ($originalError)' : ''}';
}

class DatabaseException extends NoteException {
  const DatabaseException(super.message, [super.originalError]);
}

class EncryptionException extends NoteException {
  const EncryptionException(super.message, [super.originalError]);
}

class ValidationException extends NoteException {
  const ValidationException(super.message, [super.originalError]);
}

/// الخزنة مقفلة أو غير مُعدّة: لا مفتاح في الذاكرة.
class VaultLockedException extends NoteException {
  const VaultLockedException(super.message);
}

/// تعذّر فك تشفير قيمة: مفتاح خاطئ أو بيانات معبوث بها أو تالفة.
class VaultDecryptionException extends NoteException {
  const VaultDecryptionException(super.message);
}

/// تعذّرت المزامنة: لا اتصال، أو لم يُسجَّل الدخول، أو فشل Drive. لا يُقرأ
/// أبداً على أنه "لا نسخة في السحابة".
class SyncException extends NoteException {
  const SyncException(super.message, [super.originalError]);
}
