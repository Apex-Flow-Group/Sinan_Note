// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/shared/note_view/note_view_helpers.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:apex_note/widgets/editor/category_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// أشرطة وضع القراءة — نفس شكل العارض القديم
class ReadOnlyBars {
  // ─── AppBar العلوي ───────────────────────────────────────────────
  static PreferredSizeWidget buildTopBar({
    required BuildContext context,
    required Note note,
    required Color barColor,
    required Animation<double> fadeAnimation,
    required VoidCallback onEdit,
    required Future<void> Function() onRefresh,
    VoidCallback? onMarkdownToggle,
    bool showMarkdown = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: fadeAnimation,
            curve: Curves.easeOutCubic,
          )),
          child: AppBar(
            backgroundColor: barColor,
            title: Text(note.title.isEmpty ? l10n.viewNote : note.title),
            actions: [
              if (onMarkdownToggle != null)
                IconButton(
                  icon: Icon(
                    showMarkdown
                        ? Icons.text_fields_rounded
                        : Icons.auto_awesome_outlined,
                  ),
                  tooltip: showMarkdown ? 'Plain text' : 'Markdown',
                  onPressed: onMarkdownToggle,
                ),
              if (!note.isTrashed)
                _CategoryButton(note: note, onRefresh: onRefresh),
              if (!note.isTrashed)
                _WidgetPinButton(note: note),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom bar العادي (مشاركة / أرشفة / حذف / تعديل) ──────────
  static Widget buildActionBar({
    required BuildContext context,
    required Note note,
    required Color barColor,
    required Animation<double> fadeAnimation,
    required VoidCallback onShare,
    required VoidCallback onArchive,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: fadeAnimation,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
        decoration: BoxDecoration(color: barColor),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.share,
                  onPressed: onShare,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(note.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined),
                  tooltip: note.isArchived ? l10n.unarchive : l10n.archive,
                  onPressed: onArchive,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: l10n.delete,
                  onPressed: onDelete,
                ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 20),
                    label: Text(
                      l10n.edit,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // ─── Bottom bar المهملات (استعادة / حذف نهائي) ──────────────────
  static Widget buildRestoreBar({
    required BuildContext context,
    required Color barColor,
    required Animation<double> fadeAnimation,
    required VoidCallback onRestore,
    required VoidCallback onPermanentDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: fadeAnimation,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          decoration: BoxDecoration(color: barColor),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever_outlined, size: 20),
                    label: Text(l10n.permanentDelete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onPermanentDelete,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 20),
                    label: Text(l10n.restore),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onRestore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

// ─── زر الفئات ────────────────────────────────────────────────────
class _CategoryButton extends StatelessWidget {
  final Note note;
  final Future<void> Function() onRefresh;
  const _CategoryButton({required this.note, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        note.categoryIds.isEmpty
            ? Icons.label_outline_rounded
            : Icons.label_rounded,
        color: note.categoryIds.isEmpty
            ? null
            : Theme.of(context).colorScheme.primary,
      ),
      tooltip: AppLocalizations.of(context)!.categories,
      onPressed: () async {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        final result = await CategoryPickerSheet.show(
          context,
          note.categoryIds,
          isHiddenFromHome: note.isHiddenFromHome,
        );
        if (result == null) return;
        final updated = note.copyWith(
          categoryIds: result['categoryIds'] as List<int>,
          isHiddenFromHome: result['isHiddenFromHome'] as bool,
        );
        await provider.updateNote(updated);
        await onRefresh();
      },
    );
  }
}

// ─── زر تثبيت الويدجت ────────────────────────────────────────────
class _WidgetPinButton extends StatelessWidget {
  final Note note;
  const _WidgetPinButton({required this.note});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.widgets_outlined),
      tooltip: 'Pin to Widget',
      onPressed: () async {
        final messenger = UnifiedNotificationService();
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context);

        if (note.id == null) {
          messenger.show(
            context: context,
            message: 'Cannot pin unsaved note',
            type: NotificationType.error,
          );
          return;
        }

        final isChecklistNote =
            note.isChecklist || note.noteType == 'checklist';

        if (isChecklistNote) {
          final stats = NoteViewHelpers.parseChecklistStats(note.content);
          await WidgetService().updateChecklistWidget(
            note.id!,
            note.title.isEmpty ? 'Checklist' : note.title,
            note.content,
            note.colorIndex,
            totalItems: stats['total'] ?? 0,
            completedItems: stats['completed'] ?? 0,
          );
        } else {
          await WidgetService().updateNoteWidget(note);
        }

        if (!context.mounted) return;
        messenger.show(
          context: context,
          message:
              '${l10n.widgetPinned} ${isChecklistNote ? l10n.checklists : l10n.note}',
          type: NotificationType.success,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }
}
