// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/note.dart';
import '../../services/notes_provider.dart';
import '../../screens/home_screen.dart';
import '../home/note_card_widget.dart';

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
    return ValueListenableBuilder<Set<int>>(
      valueListenable: widget.selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        return ListenableBuilder(
          listenable: widget.searchController,
          builder: (context, _) {
            return Selector<NotesProvider, List<Note>>(
              selector: (_, provider) => _filterNotes(provider.notes),
              shouldRebuild: (previous, next) => true,
              builder: (context, filteredNotes, _) {
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
                      itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index], selectedIds, 'home_grid'),
                    ),
                  );
                }

                final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
                final bottomPadding = fabBottom + 56 + 8;
                return SliverPadding(
                  padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildNoteCard(filteredNotes[index], selectedIds, 'home_list'),
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
  }

  Widget _buildNoteCard(Note note, Set<int> selectedIds, String source) {
    return RepaintBoundary(
      child: NoteCardWidget(
        key: ValueKey(note.id),
        note: note,
        viewType: widget.viewType,
        closeAllSlidables: _closeAllSlidables,
        onNoteChanged: () => setState(() {}),
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
          debugPrint('📱 onTap: note.id=${note.id}, selectionMode=${currentSelection.isNotEmpty}, currentSelection=$currentSelection');
          if (currentSelection.isNotEmpty) {
            final newSet = Set<int>.from(currentSelection);
            if (newSet.contains(note.id)) {
              newSet.remove(note.id);
              debugPrint('➖ Removed ${note.id}, newSet=$newSet');
            } else {
              newSet.add(note.id!);
              debugPrint('➕ Added ${note.id}, newSet=$newSet');
            }
            // 💉 FORCE NOTIFICATION: Create completely new Set instance
            widget.selectedNoteIdsNotifier.value = Set<int>.of(newSet);
          }
        },
      ),
    );
  }
}
