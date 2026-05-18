// Copyright © 2025 Apex Flow Group. All rights reserved.

class BackupMessages {
  static String buildSuccessMessage({
    required String lang,
    required int totalNotes,
    required int lockedCount,
    required String operation, // 'restore', 'merge', 'replace', 'import'
  }) {
    final unlockedCount = totalNotes - lockedCount;

    if (lockedCount > 0) {
      if (lang == 'ar') {
        switch (operation) {
          case 'restore':
            return 'تم استعادة $totalNotes ملاحظة\n($unlockedCount عادية، $lockedCount مشفرة)';
          case 'merge':
            return 'تم الدمج: $totalNotes ملاحظة ($unlockedCount عادية، $lockedCount مشفرة)';
          case 'replace':
            return 'تم الاستبدال: $totalNotes ملاحظة ($unlockedCount عادية، $lockedCount مشفرة)';
          case 'import':
            return 'تم استيراد $totalNotes ملاحظة ($unlockedCount عادية، $lockedCount مشفرة)';
          default:
            return 'تم: $totalNotes ملاحظة ($unlockedCount عادية، $lockedCount مشفرة)';
        }
      } else {
        switch (operation) {
          case 'restore':
            return 'Restored $totalNotes notes\n($unlockedCount normal, $lockedCount encrypted)';
          case 'merge':
            return 'Merged: $totalNotes notes ($unlockedCount normal, $lockedCount encrypted)';
          case 'replace':
            return 'Replaced: $totalNotes notes ($unlockedCount normal, $lockedCount encrypted)';
          case 'import':
            return 'Imported $totalNotes notes ($unlockedCount normal, $lockedCount encrypted)';
          default:
            return 'Done: $totalNotes notes ($unlockedCount normal, $lockedCount encrypted)';
        }
      }
    }

    // No locked notes
    if (lang == 'ar') {
      return 'تم $operation $totalNotes ملاحظة/مذكرات.';
    }
    return 'Successfully ${operation}d $totalNotes notes.';
  }

  static String getCancelMessage(String lang, String operation) {
    if (lang == 'ar') {
      return operation == 'import' ? 'تم إلغاء الاستيراد' : 'تم إلغاء الاستعادة';
    }
    return operation == 'import' ? 'Import cancelled' : 'Restore cancelled';
  }
}




