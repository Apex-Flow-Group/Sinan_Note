// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notes_provider.dart';
import '../../services/toast_service.dart';
import '../../models/note.dart';
import '../../models/note_mode.dart';  // ✏️ Import NoteMode
import '../../l10n/l10n_migration_helper.dart';
import '../../screens/note_editor.dart';  // ✏️ Import Editor
import '../breathing_search_field.dart';
import '../custom_share_sheet.dart';  // 📤 Import share widget
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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Debug: Print colors
    debugPrint('🎨 isDark: $isDark');
    debugPrint('🎨 surfaceBright: ${Theme.of(context).colorScheme.surfaceBright}');
    debugPrint('🎨 surfaceContainer: ${Theme.of(context).colorScheme.surfaceContainer}');
    debugPrint('🎨 surface: ${Theme.of(context).colorScheme.surface}');

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
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF1A1B20) // ثابت
                            : Theme.of(context).colorScheme.surfaceContainer,
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
                          focusColor: Colors.transparent,
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
