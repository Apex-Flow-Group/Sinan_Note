// Copyright © 2025 Apex Flow Group. All rights reserved.

class NoteException implements Exception {
  final String message;
  final dynamic originalError;

  NoteException(this.message, [this.originalError]);

  @override
  String toString() =>
      'NoteException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class DatabaseException extends NoteException {
  DatabaseException(super.message, [super.originalError]);
}

class EncryptionException extends NoteException {
  EncryptionException(super.message, [super.originalError]);
}

class ValidationException extends NoteException {
  ValidationException(super.message, [super.originalError]);
}
