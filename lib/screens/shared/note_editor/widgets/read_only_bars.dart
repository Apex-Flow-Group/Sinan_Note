// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/services/widget_service.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';
import 'package:sinan_note/widgets/editor/category_picker_sheet.dart';

Map<String, int> _parseChecklistStats(String content) {
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map && decoded['items'] is List) {
      final items = decoded['items'] as List;
      final total = items.length;
      final completed = items.where((i) => i['isDone'] == true).length;
      return {'total': total, 'completed': completed};
    }
  } catch (_) {}
  return {'total': 0, 'completed': 0};
}

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
    VoidCallback? onReminder,
    VoidCallback? onReadingMode,
    bool showMarkdown = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
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
            toolbarHeight: 48,
            title: Text(
              note.title.isEmpty ? l10n.viewNote : note.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (onReadingMode != null)
                IconButton(
                  icon: const Icon(Icons.menu_book_rounded),
                  tooltip: AppLocalizations.of(context)!.readingMode,
                  onPressed: onReadingMode,
                ),
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
              if (!note.isTrashed && onReminder != null)
                IconButton(
                  icon: Icon(
                    note.reminderDateTime != null
                        ? Icons.alarm_on_rounded
                        : Icons.alarm_add_rounded,
                    color: note.reminderDateTime != null ? Colors.orange : null,
                  ),
                  tooltip: l10n.reminder,
                  onPressed: onReminder,
                ),
              if (!note.isTrashed)
                _CategoryButton(note: note, onRefresh: onRefresh),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom bar: تحويل + more + تعديل ───────────────────────────
  static Widget buildActionBar({
    required BuildContext context,
    required Note note,
    required Color barColor,
    required Animation<double> fadeAnimation,
    required VoidCallback onShare,
    required VoidCallback onArchive,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
    VoidCallback? onColorChange,
    void Function(String)? onConvert,
    String currentNoteType = 'simple',
    bool isChecklist = false,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(
                        l10n.edit,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onColorChange != null)
                    IconButton(
                      icon: const Icon(Icons.palette_outlined),
                      tooltip: l10n.noteColors,
                      onPressed: onColorChange,
                      padding: const EdgeInsets.all(6),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  if (onColorChange != null) const SizedBox(width: 4),
                  if (onConvert != null)
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      tooltip: l10n.convertTo,
                      onPressed: () => _showConvertSheet(
                        context,
                        currentNoteType: currentNoteType,
                        isChecklist: isChecklist,
                        onConvert: onConvert,
                        l10n: l10n,
                      ),
                      padding: const EdgeInsets.all(6),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  if (onConvert != null) const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showMoreSheet(
                        context,
                        note: note,
                        onShare: onShare,
                        onArchive: onArchive,
                        onDelete: onDelete,
                        l10n: l10n,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.more_vert_rounded, size: 22),
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

  static void _showMoreSheet(
    BuildContext context, {
    required Note note,
    required VoidCallback onShare,
    required VoidCallback onArchive,
    required VoidCallback onDelete,
    required AppLocalizations l10n,
  }) {
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.blue),
              title: Text(l10n.actionShare),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: Icon(
                note.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                color: Colors.green,
              ),
              title:
                  Text(note.isArchived ? l10n.unarchive : l10n.actionArchive),
              onTap: () {
                Navigator.pop(context);
                onArchive();
              },
            ),
            _WidgetPinTile(note: note),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(l10n.actionDelete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  static void _showConvertSheet(
    BuildContext context, {
    required String currentNoteType,
    required bool isChecklist,
    required void Function(String) onConvert,
    required AppLocalizations l10n,
  }) {
    final options = <_ConvertOption>[];
    if (isChecklist) {
      options
          .add(_ConvertOption(Icons.note_rounded, l10n.simpleNotes, 'simple'));
      options.add(
          _ConvertOption(Icons.text_fields_rounded, l10n.richText, 'rich'));
    } else if (currentNoteType == 'simple') {
      options.add(
          _ConvertOption(Icons.text_fields_rounded, l10n.richText, 'rich'));
      options.add(
          _ConvertOption(Icons.code_rounded, l10n.professionalNotes, 'code'));
      options.add(
          _ConvertOption(Icons.checklist_rounded, l10n.checklist, 'checklist'));
    } else if (currentNoteType == 'rich') {
      options
          .add(_ConvertOption(Icons.note_rounded, l10n.simpleNotes, 'simple'));
      options.add(
          _ConvertOption(Icons.code_rounded, l10n.professionalNotes, 'code'));
      options.add(
          _ConvertOption(Icons.checklist_rounded, l10n.checklist, 'checklist'));
    } else if (currentNoteType == 'code' ||
        currentNoteType == 'pro' ||
        currentNoteType == 'professional') {
      options
          .add(_ConvertOption(Icons.note_rounded, l10n.simpleNotes, 'simple'));
      options.add(
          _ConvertOption(Icons.text_fields_rounded, l10n.richText, 'rich'));
    }
    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ...options.map((opt) => ListTile(
                  leading: Icon(opt.icon, color: Colors.teal),
                  title: Text(opt.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    onConvert(opt.type);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Bottom bar المهملات — لم يعد مستخدماً (استُبدل بـ bottomSheet) ──
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

// ─── عنصر تثبيت الويدجت في القائمة ──────────────────────────────
class _WidgetPinTile extends StatelessWidget {
  final Note note;
  const _WidgetPinTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.widgets_outlined, color: Colors.purple),
      title: Text(l10n.pinToWidget),
      onTap: () async {
        Navigator.pop(context);
        if (note.id == null) return;

        final isChecklistNote =
            note.isChecklist || note.noteType == 'checklist';
        if (isChecklistNote) {
          final stats = _parseChecklistStats(note.content);
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
        UnifiedNotificationService().show(
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

class _ConvertOption {
  final IconData icon;
  final String label;
  final String type;
  const _ConvertOption(this.icon, this.label, this.type);
}
