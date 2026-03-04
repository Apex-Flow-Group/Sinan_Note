// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class NotesGridView extends StatefulWidget {
  final ViewType viewType;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final TextEditingController searchController;
  
  const NotesGridView({
    super.key,
    required this.viewType,
    required this.selectedNoteIdsNotifier,
    required this.searchController,
  });

  @override
  State<NotesGridView> createState() => _NotesGridViewState();
}

class _NotesGridViewState extends State<NotesGridView> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier(0);

  @override
  void dispose() {
    _scrollController.dispose();
    _closeAllSlidables.dispose();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    final searchQuery = widget.searchController.text.toLowerCase();
    final filtered = notes.where((note) {
      if (note.isLocked || note.isArchived || note.isTrashed) return false;
      if (searchQuery.isEmpty) return true;
      
      if (searchQuery.startsWith('type:')) {
        final type = searchQuery.substring(5);
        return _matchNoteType(note, type);
      }
      
      if (searchQuery.startsWith('pinned:')) return note.isPinned;
      
      return note.title.toLowerCase().contains(searchQuery) ||
          note.content.toLowerCase().contains(searchQuery);
    }).toList();
    
    // OPTIMIZATION: No sorting here - NotesProvider already sorts by (pinned, updatedAt)
    return filtered;
  }

  bool _matchNoteType(Note note, String type) {
    switch (type) {
      case 'simple': return note.noteType == 'simple' || note.noteType.isEmpty;
      case 'pro':
      case 'code': return note.noteType == 'pro' || note.noteType == 'code' || note.isProfessional;
      case 'reminder': return note.reminderDateTime != null;
      case 'checklist': return note.noteType == 'checklist' || note.isChecklist;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedNoteProvider>(
      builder: (context, selectedNoteProvider, _) {
        return ValueListenableBuilder<Set<int>>(
          valueListenable: widget.selectedNoteIdsNotifier,
          builder: (context, selectedIds, _) {
            return ListenableBuilder(
              listenable: widget.searchController,
              builder: (context, _) {
                return Consumer<NotesProvider>(
                  builder: (context, provider, _) {
                    final filteredNotes = _filterNotes(provider.notes);
                    if (filteredNotes.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No notes', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    }

                    if (widget.viewType == ViewType.grid) {
                      final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
                      final bottomPadding = fabBottom + 56 + 8;
                      return SliverPadding(
                        padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
                        sliver: SliverMasonryGrid.count(
                          key: const PageStorageKey('notes_masonry_grid'),
                          crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : MediaQuery.of(context).size.width >= 600 ? 3 : 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childCount: filteredNotes.length,
                          itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index], selectedIds, selectedNoteProvider, 'home_grid'),
                        ),
                      );
                    }

                    final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
                    final bottomPadding = fabBottom + 56 + 8;
                    return SliverPadding(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildNoteCard(filteredNotes[index], selectedIds, selectedNoteProvider, 'home_list'),
                          childCount: filteredNotes.length,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNoteCard(Note note, Set<int> selectedIds, SelectedNoteProvider selectedNoteProvider, String source) {
    // 🔥 الحصول على الملاحظة المفتوحة حالياً
    final isCurrentlyOpen = selectedNoteProvider.selectedNote?.id == note.id;
    
    return RepaintBoundary(
      child: Padding(
        padding: isCurrentlyOpen 
            ? const EdgeInsets.only(left: 12, right: 0)
            : EdgeInsets.zero,
        child: NoteCardWidget(
          key: ValueKey(note.id),
          note: note,
          viewType: widget.viewType,
          closeAllSlidables: _closeAllSlidables,
          isCurrentlyOpen: isCurrentlyOpen, // 🔥 NEW
          onNoteChanged: () {
            // Provider يُحدّث تلقائياً عبر notifyListeners
          },
          isSelected: selectedIds.contains(note.id),
          selectionMode: selectedIds.isNotEmpty,
          source: source,
          onLongPress: () {
            // Long Press ONLY starts selection mode
            final currentSelection = widget.selectedNoteIdsNotifier.value;
            if (currentSelection.isNotEmpty) return; // Already selecting - ignore
            widget.selectedNoteIdsNotifier.value = {note.id!};
          },
          onTap: () {
            // 🔥 FIX: Read LIVE value from notifier, not stale snapshot
            final currentSelection = widget.selectedNoteIdsNotifier.value;
            if (currentSelection.isNotEmpty) {
              final newSet = Set<int>.from(currentSelection);
              if (newSet.contains(note.id)) {
                newSet.remove(note.id);
              } else {
                newSet.add(note.id!);
              }
              // 💉 FORCE NOTIFICATION: Create completely new Set instance
              widget.selectedNoteIdsNotifier.value = Set<int>.of(newSet);
            }
          },
        ),
      ),
    );
  }
}
