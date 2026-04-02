// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/common/glowing_search_field.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:apex_note/widgets/home/note_conversion_sheet.dart';
import 'package:apex_note/widgets/home/selection_action_bar.dart';
import 'package:apex_note/widgets/home/smooth_search_header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SmartHeader extends StatefulWidget {
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueNotifier<String> viewTypeNotifier;
  final VoidCallback onViewToggle;
  final VoidCallback onMenuTap;
  final VoidCallback? onFilterTap;
  final bool isSearchActive;

  const SmartHeader({
    super.key,
    required this.selectedNoteIdsNotifier,
    required this.searchController,
    required this.searchFocusNode,
    required this.viewTypeNotifier,
    required this.onViewToggle,
    required this.onMenuTap,
    required this.isSearchActive,
    this.onFilterTap,
  });

  @override
  State<SmartHeader> createState() => _SmartHeaderState();
}

class _SmartHeaderState extends State<SmartHeader> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<Set<int>>(
      valueListenable: widget.selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        return SliverPersistentHeader(
          pinned: selectedIds.isNotEmpty,
          floating: selectedIds.isEmpty,
          delegate: SmoothSearchHeaderDelegate(
            expandedHeight: 68.0,
            selectionMode: selectedIds.isNotEmpty,
            isSearchActive: widget.isSearchActive,
            selectionBar: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: SelectionActionBar(
                    selectedIdsNotifier: widget.selectedNoteIdsNotifier,
                    isDark: isDark,
                    allPinned: false,
                    onClear: () {
                      widget.selectedNoteIdsNotifier.value = {};
                    },
                    onConvert: selectedIds.length == 1
                        ? () {
                            final provider = Provider.of<NotesProvider>(context,
                                listen: false);
                            final noteId = selectedIds.first;
                            final note = provider.notes
                                .firstWhere((n) => n.id == noteId);

                            widget.selectedNoteIdsNotifier.value = {};

                            NoteConversionSheet.show(context, note, () {});
                          }
                        : null,
                    onPin: () async {
                      final provider =
                          Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;
                      final notesToRestore = <Note>[];

                      for (final id in ids) {
                        final note =
                            provider.notes.firstWhere((n) => n.id == id);
                        notesToRestore.add(note);
                        final updatedNote = Note(
                          id: note.id,
                          title: note.title,
                          content: note.content,
                          createdAt: note.createdAt,
                          updatedAt: DateTime.now(),
                          colorIndex: note.colorIndex,
                          isArchived: note.isArchived,
                          isTrashed: note.isTrashed,
                          reminderDateTime: note.reminderDateTime,
                          isLocked: note.isLocked,
                          noteType: note.noteType,
                          recurrenceRule: note.recurrenceRule,
                          isCompleted: note.isCompleted,
                          isProfessional: note.isProfessional,
                          isPinned: !note.isPinned,
                          isChecklist: note.isChecklist,
                        );
                        await provider.updateNote(updatedNote);
                      }

                      widget.selectedNoteIdsNotifier.value = {};

                      if (context.mounted) {
                        UnifiedNotificationService().showWithUndo(
                          context: context,
                          message: '$count ${l10n.notesPinned}',
                          actionKey: 'bulk_pin',
                          type: NotificationType.success,
                          onExecute: () {},
                          onUndo: () async {
                            for (final note in notesToRestore) {
                              await provider.updateNote(note);
                            }
                          },
                          undoLabel: l10n.undo,
                        );
                      }
                    },
                    onArchive: () async {
                      final provider =
                          Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;

                      await provider.archiveNotes(ids);
                      widget.selectedNoteIdsNotifier.value = {};

                      if (context.mounted) {
                        UnifiedNotificationService().showWithUndo(
                          context: context,
                          message: '$count ${l10n.notesArchived}',
                          actionKey: 'bulk_archive',
                          type: NotificationType.success,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.unarchiveNotes(ids);
                          },
                          undoLabel: l10n.undo,
                        );
                      }
                    },
                    onDelete: () async {
                      final provider =
                          Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;

                      await provider.trashNotes(ids);
                      widget.selectedNoteIdsNotifier.value = {};

                      if (context.mounted) {
                        UnifiedNotificationService().showWithUndo(
                          context: context,
                          message: '$count ${l10n.notesDeleted}',
                          actionKey: 'bulk_delete',
                          type: NotificationType.info,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.restoreNotes(ids);
                          },
                          undoLabel: l10n.undo,
                        );
                      }
                    },
                    onShare: selectedIds.length == 1
                        ? () {
                            final provider = Provider.of<NotesProvider>(context,
                                listen: false);
                            final noteId = selectedIds.first;
                            final note = provider.notes
                                .firstWhere((n) => n.id == noteId);

                            widget.selectedNoteIdsNotifier.value = {};

                            final plainContent = NoteCardUtils.fixNoteContent(
                                note.content,
                                maxChars: note.content.length);
                            CustomShareSheet.show(
                              context,
                              '${note.title}\n\n$plainContent',
                              subject: note.title,
                              note: note,
                              onNoteCopied: () {
                                if (note.id != null) {
                                  Provider.of<NotesProvider>(context,
                                          listen: false)
                                      .duplicateNote(note.id!);
                                }
                              },
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.isSearchActive ? Icons.close : Icons.menu,
                        ),
                        onPressed: widget.onMenuTap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlowingSearchField(
                          controller: widget.searchController,
                          focusNode: widget.searchFocusNode,
                          hintText: l10n.searchNotes,
                          viewTypeNotifier: widget.viewTypeNotifier,
                          onViewToggle: widget.onViewToggle,
                          onFilterTap: widget.onFilterTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
