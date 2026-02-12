// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../services/unified_notification_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../models/note.dart';
import '../../models/note_mode.dart';  // ✏️ Import NoteMode
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../screens/shared/note_editor.dart';  // ✏️ Import Editor
import '../common/breathing_search_field.dart';
import '../common/custom_share_sheet.dart';  // 📤 Import share widget
import 'selection_action_bar.dart';
import 'smooth_search_header_delegate.dart';

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
            expandedHeight: 80.0,
            isDark: isDark,
            selectionMode: selectedIds.isNotEmpty,
            isSearchActive: widget.isSearchActive,
            selectionBar: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: SelectionActionBar(
                    selectedIdsNotifier: widget.selectedNoteIdsNotifier,  // 🔥 Pass notifier directly
                    isDark: isDark,
                    allPinned: false,
                    onClear: () {
                      widget.selectedNoteIdsNotifier.value = {};
                    },
                    onRename: selectedIds.length == 1 ? () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final noteId = selectedIds.first;
                      final note = provider.notes.firstWhere((n) => n.id == noteId);
                      
                      // Clear selection first
                      widget.selectedNoteIdsNotifier.value = {};
                      
                      // Determine note mode
                      NoteMode mode = NoteMode.simple;
                      if (note.isChecklist) {
                        mode = NoteMode.checklist;
                      } else if (note.noteType == 'code' || note.isProfessional) {
                        mode = NoteMode.code;
                      } else if (note.reminderDateTime != null) {
                        mode = NoteMode.reminder;
                      }
                      
                      // Open editor
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditorImmersive(
                            note: note,
                            mode: mode,
                          ),
                        ),
                      );
                    } : null,
                    onPin: () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;
                      final notesToRestore = <Note>[];
                      
                      // IMMEDIATE: Execute action first (Google Keep style)
                      for (final id in ids) {
                        final note = provider.notes.firstWhere((n) => n.id == id);
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
                          message: '$count ${AppLocalizations.of(context)!.notesPinned}',
                          actionKey: 'bulk_pin',
                          type: NotificationType.success,
                          onExecute: () {}, // Empty - action already executed
                          onUndo: () async {
                            for (final note in notesToRestore) {
                              await provider.updateNote(note);
                            }
                          },
                          undoLabel: AppLocalizations.of(context)!.undo,
                        );
                      }
                    },
                    onArchive: () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;
                      
                      // IMMEDIATE: Execute batch action
                      await provider.archiveNotes(ids);
                      widget.selectedNoteIdsNotifier.value = {};
                      
                      if (context.mounted) {
                        UnifiedNotificationService().showWithUndo(
                          context: context,
                          message: '$count ${AppLocalizations.of(context)!.notesArchived}',
                          actionKey: 'bulk_archive',
                          type: NotificationType.success,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.unarchiveNotes(ids);
                          },
                          undoLabel: AppLocalizations.of(context)!.undo,
                        );
                      }
                    },
                    onDelete: () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;
                      
                      // IMMEDIATE: Execute batch action
                      await provider.trashNotes(ids);
                      widget.selectedNoteIdsNotifier.value = {};
                      
                      if (context.mounted) {
                        UnifiedNotificationService().showWithUndo(
                          context: context,
                          message: '$count ${AppLocalizations.of(context)!.notesDeleted}',
                          actionKey: 'bulk_delete',
                          type: NotificationType.info,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.restoreNotes(ids);
                          },
                          undoLabel: AppLocalizations.of(context)!.undo,
                        );
                      }
                    },
                    onShare: selectedIds.length == 1 ? () {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final noteId = selectedIds.first;
                      final note = provider.notes.firstWhere((n) => n.id == noteId);
                      
                      // Clear selection first to prevent multiple taps
                      widget.selectedNoteIdsNotifier.value = {};
                      
                      // 📤 Use CustomShareSheet widget
                      CustomShareSheet.show(
                        context,
                        '${note.title}\n\n${note.content}',
                        subject: note.title,
                      );
                    } : null,
                  ),
                ),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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
                        child: BreathingSearchField(
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
