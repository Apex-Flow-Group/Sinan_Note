// Copyright © 2025 Apex Flow Group. All rights reserved.

enum NoteMode { simple, rich, code, reminder, checklist }

// Backward compatibility mapping for database
extension NoteModeExtension on NoteMode {
  String get dbValue {
    switch (this) {
      case NoteMode.code:
        return 'pro'; // Map to old 'professional' value
      default:
        return name;
    }
  }

  static NoteMode fromString(String value) {
    switch (value) {
      case 'pro':
      case 'professional':
        return NoteMode.code; // Map old values to new enum
      case 'rich':
        return NoteMode.rich;
      case 'reminder':
        return NoteMode.reminder;
      case 'checklist':
        return NoteMode.checklist;
      default:
        return NoteMode.simple;
    }
  }
}




