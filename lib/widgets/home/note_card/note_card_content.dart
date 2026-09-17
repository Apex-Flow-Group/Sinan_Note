// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/services/notification_service.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/home/note_card/hidden_categories_chip.dart';
import 'package:sinan_note/widgets/home/note_card_actions.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

/// محتوى البطاقة: العنوان، المعاينة، وشارات التذكير والنوع والكتالوجات.
///
/// كل النصوص والألوان تُمرَّر محسوبة مسبقاً — هذا الودجت لا يفكّ محتوى ملاحظة
/// ولا يكشف اتجاه نص، حتى يبقى ارتفاعه ثابتاً بين مرات إعادة البناء.
class NoteCardContent extends StatelessWidget {
  const NoteCardContent({
    super.key,
    required this.note,
    required this.viewType,
    required this.source,
    required this.title,
    required this.preview,
    required this.titleDirection,
    required this.previewDirection,
    required this.titleColor,
    required this.contentColor,
    required this.isChecklist,
    required this.checklistItems,
    required this.fileExtension,
    required this.selectionMode,
    required this.isFiltering,
    required this.onNoteChanged,
  });

  final Note note;
  final ViewType viewType;
  final String source;
  final String title;
  final String preview;
  final ui.TextDirection titleDirection;
  final ui.TextDirection previewDirection;
  final Color titleColor;
  final Color contentColor;
  final bool isChecklist;
  final List<ChecklistItem> checklistItems;
  final String fileExtension;
  final bool selectionMode;
  final bool isFiltering;
  final VoidCallback onNoteChanged;

  bool get _isCompact => viewType == ViewType.listCompact;

  /// المحتوى مقروء فقط في شاشة المقفلة حيث يكون مفكوك التشفير.
  bool get _hidesContent => note.isLocked && source != 'locked';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _buildTitleBlock(context)),
            _buildTrailingIcons(context),
          ],
        ),
        if (note.reminderDateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: NoteReminderBadge(
              note: note,
              onNoteChanged: onNoteChanged,
            ),
          ),
        if (fileExtension.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _TypeBadge(
              noteType: note.noteType,
              label: fileExtension,
            ),
          ),
        if (!_isCompact) _buildCategoriesChip(context),
      ],
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    final titleText = Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: titleColor,
      ),
      maxLines: _isCompact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );

    if (_isCompact) {
      return Directionality(textDirection: titleDirection, child: titleText);
    }

    return Directionality(
      textDirection: titleDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleText,
          const SizedBox(height: 8),
          _buildPreview(context),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_hidesContent) {
      final l10n = AppLocalizations.of(context)!;
      return Text(
        l10n.protectedContent,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: contentColor.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (isChecklist) {
      return NoteCardUtils.buildChecklistPreviewFromItems(
        checklistItems,
        titleColor,
      );
    }

    return Text(
      preview,
      textDirection: previewDirection,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, color: contentColor),
    );
  }

  Widget _buildTrailingIcons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note.isPinned)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.push_pin,
              size: 18,
              color: titleColor.withValues(alpha: 0.7),
            ),
          ),
        if (note.isLocked)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.lock, size: 20, color: titleColor),
          ),
        if (note.isLocked && !selectionMode)
          NoteCardActions.buildLockedNoteMenu(
            context,
            note,
            titleColor,
            onNoteChanged,
          ),
      ],
    );
  }

  Widget _buildCategoriesChip(BuildContext context) {
    final hideProFromHome = context.read<CategoriesProvider>().hideProFromHome;
    final showChip = note.isHiddenFromHome ||
        (isFiltering && note.isProfessional && hideProFromHome);
    if (!showChip) return const SizedBox.shrink();

    return HiddenCategoriesChip(
      note: note,
      titleColor: titleColor,
      isProHidden:
          note.isProfessional && hideProFromHome && !note.isHiddenFromHome,
    );
  }
}

/// شارة موعد التذكير مع زر إلغائه.
class NoteReminderBadge extends StatelessWidget {
  const NoteReminderBadge({
    super.key,
    required this.note,
    required this.onNoteChanged,
  });

  final Note note;
  final VoidCallback onNoteChanged;

  Future<void> _removeReminder(BuildContext context) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    await NotificationService().cancelNotification(note.id!);
    await notesProvider.updateNote(
      note.copyWith(reminderDateTime: null, recurrenceRule: null),
    );
    onNoteChanged();

    if (!context.mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.reminderRemoved,
      type: NotificationType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = note.reminderDateTime!;
    final isExpired = due.isBefore(DateTime.now());
    final badgeColor = isExpired ? Colors.red : Colors.orange;
    final label = '${DateFormat('EEE, MMM d').format(due)}'
        ' • ${DateFormat('h:mm a').format(due)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.alarm_off : Icons.alarm,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (note.recurrenceRule != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.repeat, size: 12, color: badgeColor),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _removeReminder(context),
            child: Icon(
              Icons.close,
              size: 14,
              color: badgeColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة امتداد الملف لملاحظات الكود والماركداون.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.noteType, required this.label});

  final String noteType;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isMarkdown = noteType == 'markdown';
    final accent = isMarkdown ? Colors.orange : Colors.blue;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.code, size: 12, color: accent.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: accent.shade700,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
