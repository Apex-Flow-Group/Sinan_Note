// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notes_provider.dart';
import '../../services/toast_service.dart';
import '../../models/note.dart';
import '../../l10n/l10n_migration_helper.dart';
import '../breathing_search_field.dart';
import 'selection_action_bar.dart';
import 'smooth_search_header_delegate.dart';

class SmartHeader extends StatefulWidget {
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueNotifier<String> viewTypeNotifier;
  final VoidCallback onViewToggle;
  final VoidCallback onMenuTap;
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
  });

  @override
  State<SmartHeader> createState() => _SmartHeaderState();
}

class _SmartHeaderState extends State<SmartHeader> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    selectedCount: selectedIds.length,
                    isDark: isDark,
                    allPinned: false,
                    onClear: () {
                      widget.selectedNoteIdsNotifier.value = {};
                    },
                    onRename: null,
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
                        ToastService().showUndoToast(
                          context: context,
                          message: '$count ${context.l10n.notesPinned}',
                          actionKey: 'bulk_pin',
                          type: ToastType.success,
                          onExecute: () {}, // Empty - action already executed
                          onUndo: () async {
                            for (final note in notesToRestore) {
                              await provider.updateNote(note);
                            }
                          },
                          undoLabel: context.l10n.undo,
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
                        ToastService().showUndoToast(
                          context: context,
                          message: '$count ${context.l10n.notesArchived}',
                          actionKey: 'bulk_archive',
                          type: ToastType.success,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.unarchiveNotes(ids);
                          },
                          undoLabel: context.l10n.undo,
                        );
                      }
                    },
                    onDelete: () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      final ids = List<int>.from(selectedIds);
                      final count = ids.length;
                      
                      debugPrint('🎯 onDelete: selectedIds=$selectedIds, count=$count');
                      
                      // IMMEDIATE: Execute batch action
                      await provider.trashNotes(ids);
                      widget.selectedNoteIdsNotifier.value = {};
                      
                      if (context.mounted) {
                        ToastService().showUndoToast(
                          context: context,
                          message: '$count ${context.l10n.notesDeleted}',
                          actionKey: 'bulk_delete',
                          type: ToastType.info,
                          onExecute: () {},
                          onUndo: () async {
                            await provider.restoreNotes(ids);
                          },
                          undoLabel: context.l10n.undo,
                        );
                      }
                    },
                    onShare: null,
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
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).colorScheme.surfaceBright : Theme.of(context).colorScheme.surfaceContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isSearchActive ? Icons.arrow_back : Icons.menu,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: widget.onMenuTap,
                          splashRadius: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BreathingSearchField(
                          controller: widget.searchController,
                          focusNode: widget.searchFocusNode,
                          hintText: l10n.searchNotes,
                          viewTypeNotifier: widget.viewTypeNotifier,
                          onViewToggle: widget.onViewToggle,
                          onFilterTap: () {},
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
