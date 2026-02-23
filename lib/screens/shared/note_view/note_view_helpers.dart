// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';

class NoteViewHelpers {
  static bool getDirection(String text) {
    return RegExp(r'[؀-ۿ]').hasMatch(text);
  }

  static Map<String, int> parseChecklistStats(String content) {
    try {
      final items = ChecklistFormatter.parseJson(content);
      final total = items.length;
      final completed = items.where((item) => item.isDone).length;
      return {'total': total, 'completed': completed};
    } catch (e) {
      return {'total': 0, 'completed': 0};
    }
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
