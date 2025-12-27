// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/note.dart';
import '../../services/notes_provider.dart';
import '../../screens/home_screen.dart';
import '../home/note_card_widget.dart';

class NotesGridWidget extends StatelessWidget {
  final ViewType viewType;
  final String searchQuery;
  final ValueNotifier<int> closeAllSlidables;
  final Set<int> selectedNoteIds;
  final ValueNotifier<int> selectionCountNotifier;
  final VoidCallback onStateChanged;

  const NotesGridWidget({
    super.key,
    required this.viewType,
    required this.searchQuery,
    required this.closeAllSlidables,
    required this.selectedNoteIds,
    required this.selectionCountNotifier,
    required this.onStateChanged,
  });

  List<Note> _filterNotes(List<Note> notes) {
    final filtered = notes.where((note) {
      if (note.isLocked) return false;
      if (note.isArchived || note.isTrashed) return false;
      if (searchQuery.isEmpty) return true;
      
      if (searchQuery.startsWith('type:')) {
        final type = searchQuery.substring(5);
        return _matchNoteType(note, type);
      }
      
      if (searchQuery.startsWith('pinned:')) {
        return note.isPinned;
      }
      
      return note.title.toLowerCase().contains(searchQuery) ||
          note.content.toLowerCase().contains(searchQuery);
    }).toList();
    
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    return filtered;
  }

  bool _matchNoteType(Note note, String type) {
    switch (type) {
      case 'simple':
        return note.noteType == 'simple' || note.noteType.isEmpty;
      case 'pro':
      case 'code':
        return note.noteType == 'pro' || 
               note.noteType == 'code' || 
               note.isProfessional;
      case 'reminder':
        return note.reminderDateTime != null;
      case 'checklist':
        return note.noteType == 'checklist' || note.isChecklist;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<NotesProvider, List<Note>>(
      selector: (_, provider) => _filterNotes(provider.notes),
      shouldRebuild: (previous, next) => previous != next,
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
                  Text(
                    'No notes',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (viewType == ViewType.grid) {
          final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
          final bottomPadding = fabBottom + 56 + 8;
          return SliverPadding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 1200
                  ? 4
                  : MediaQuery.of(context).size.width >= 600
                      ? 3
                      : 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childCount: filteredNotes.length,
              itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index], 'home_grid'),
            ),
          );
        }

        final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
        final bottomPadding = fabBottom + 56 + 8;
        return SliverPadding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNoteCard(filteredNotes[index], 'home_list'),
              childCount: filteredNotes.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note, String source) {
    return RepaintBoundary(
      child: NoteCardWidget(
        key: ValueKey(note.id),
        note: note,
        viewType: viewType,
        closeAllSlidables: closeAllSlidables,
        onNoteChanged: onStateChanged,
        isSelected: selectedNoteIds.contains(note.id),
        selectionMode: selectedNoteIds.isNotEmpty,
        source: source,
        onLongPress: () {
          selectedNoteIds.add(note.id!);
          selectionCountNotifier.value = selectedNoteIds.length;
          onStateChanged();
        },
        onTap: () {
          if (selectedNoteIds.isNotEmpty) {
            if (selectedNoteIds.contains(note.id)) {
              selectedNoteIds.remove(note.id);
            } else {
              selectedNoteIds.add(note.id!);
            }
            selectionCountNotifier.value = selectedNoteIds.length;
            onStateChanged();
          }
        },
      ),
    );
  }
}
