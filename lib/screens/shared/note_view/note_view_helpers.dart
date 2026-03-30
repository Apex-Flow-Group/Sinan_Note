// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:flutter/widgets.dart';

class NoteViewHelpers {
  /// @deprecated استخدم TextDirectionUtils.getDirection مباشرة
  static bool getDirection(String text) {
    return TextDirectionUtils.getDirection(text) == TextDirection.rtl;
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
