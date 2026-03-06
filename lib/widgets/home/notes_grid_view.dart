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
  final ScrollController? scrollController;

  const NotesGridView({
    super.key,
    required this.viewType,
    required this.selectedNoteIdsNotifier,
    required this.searchController,
    this.scrollController,
  });

  @override
  State<NotesGridView> createState() => _NotesGridViewState();
}

class _NotesGridViewState extends State<NotesGridView> {
  late final ScrollController _scrollController;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scrollController.dispose();
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

      final normalized = Note.normalize(searchQuery);
      if (note.normalizedTitle.contains(normalized) ||
          note.normalizedContent.contains(normalized)) {
        return true;
      }

      // Fuzzy: allow 1 typo for queries >= 4 chars
      if (normalized.length >= 4) {
        for (final word in [
          ...note.normalizedTitle.split(' '),
          ...note.normalizedContent.split(' ').take(50)
        ]) {
          if (word.length >= 3 && _levenshtein(normalized, word) <= 1) {
            return true;
          }
        }
      }

      return false;
    }).toList();

    return filtered;
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    final m = s1.length, n = s2.length;
    final dp = List.generate(
        m + 1,
        (i) => List.generate(
            n + 1,
            (j) => i == 0
                ? j
                : j == 0
                    ? i
                    : 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s1[i - 1] == s2[j - 1]
            ? dp[i - 1][j - 1]
            : 1 +
                [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                    .reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[m][n];
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
                              Icon(Icons.note_add_outlined,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No notes',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    }

                    if (widget.viewType == ViewType.grid) {
                      final fabBottom = MediaQuery.of(context).padding.bottom +
                          kBottomNavigationBarHeight +
                          16;
                      final bottomPadding = fabBottom + 56 + 8;
                      return SliverPadding(
                        padding: EdgeInsets.only(
                            left: 8, right: 8, top: 8, bottom: bottomPadding),
                        sliver: SliverMasonryGrid.count(
                          key: const PageStorageKey('notes_masonry_grid'),
                          crossAxisCount:
                              MediaQuery.of(context).size.width >= 1200
                                  ? 4
                                  : MediaQuery.of(context).size.width >= 600
                                      ? 3
                                      : 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childCount: filteredNotes.length,
                          itemBuilder: (context, index) => _buildNoteCard(
                              filteredNotes[index],
                              selectedIds,
                              selectedNoteProvider,
                              'home_grid'),
                        ),
                      );
                    }

                    final fabBottom = MediaQuery.of(context).padding.bottom +
                        kBottomNavigationBarHeight +
                        16;
                    final bottomPadding = fabBottom + 56 + 8;
                    return SliverPadding(
                      padding: EdgeInsets.only(
                          left: 8, right: 8, top: 8, bottom: bottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildNoteCard(
                              filteredNotes[index],
                              selectedIds,
                              selectedNoteProvider,
                              'home_list'),
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

  Widget _buildNoteCard(Note note, Set<int> selectedIds,
      SelectedNoteProvider selectedNoteProvider, String source) {
    // 🔥 الحصول على الملاحظة المفتوحة حالياً
    final isCurrentlyOpen = selectedNoteProvider.selectedNote?.id == note.id;

    return RepaintBoundary(
      child: Padding(
        padding: isCurrentlyOpen
            ? const EdgeInsets.only(left: 4, right: 0)
            : EdgeInsets.zero,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCurrentlyOpen ? 3 : 0,
              height: 48,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
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
                  if (currentSelection.isNotEmpty) {
                    return; // Already selecting - ignore
                  }
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
          ],
        ),
      ),
    );
  }
}
