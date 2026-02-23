// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget لعرض عنصر واحد في قائمة الملاحظات (Master Panel)
/// 
/// يعرض:
/// - أيقونة نوع الملاحظة (نص/checklist/كود)
/// - عنوان الملاحظة
/// - تاريخ آخر تعديل
/// - تمييز بصري للملاحظة المختارة
class NoteListTile extends StatelessWidget {
  /// الملاحظة المراد عرضها
  final Note note;
  
  /// هل هذه الملاحظة مختارة حالياً
  final bool isSelected;
  
  /// دالة تُستدعى عند النقر على الملاحظة
  final VoidCallback onTap;
  
  /// دالة تُستدعى عند الضغط الطويل أو النقر بزر الماوس الأيمن (اختياري)
  final VoidCallback? onContextMenu;

  const NoteListTile({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final tile = ListTile(
      // عنوان الملاحظة
      title: Text(
        note.title.isEmpty ? l10n.untitled : note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      
      // تاريخ آخر تعديل
      subtitle: Text(
        _formatDate(note.updatedAt, context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      
      // أيقونة نوع الملاحظة
      leading: Icon(_getNoteIcon(note.noteType)),
      
      // تمييز الملاحظة المختارة
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      
      // معالجة النقر
      onTap: onTap,
      
      // معالجة الضغط الطويل
      onLongPress: onContextMenu,
    );
    
    // إذا كان هناك context menu، نضيف دعم right-click
    if (onContextMenu != null) {
      return GestureDetector(
        onSecondaryTap: onContextMenu,
        child: tile,
      );
    }
    
    return tile;
  }

  /// تحديد الأيقونة المناسبة حسب نوع الملاحظة
  IconData _getNoteIcon(String noteType) {
    switch (noteType) {
      case 'code':
      case 'professional':
        return Icons.code;
      case 'checklist':
        return Icons.checklist;
      case 'reminder':
        return Icons.alarm;
      case 'simple':
      default:
        return Icons.note;
    }
  }

  /// تنسيق التاريخ بشكل مقروء
  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // إذا كان اليوم
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    }
    
    // إذا كان بالأمس
    if (difference.inDays == 1) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    
    // إذا كان خلال الأسبوع الماضي
    if (difference.inDays < 7) {
      return isArabic ? '${difference.inDays} أيام' : '${difference.inDays} days ago';
    }
    
    // تاريخ كامل
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
