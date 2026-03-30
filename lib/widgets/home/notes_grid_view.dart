// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:apex_note/widgets/home/note_locator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart' show ReadContext;

class NotesGridView extends StatefulWidget {
  final ValueNotifier<String> viewTypeNotifier;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final TextEditingController searchController;
  final ScrollController? scrollController;
  final ValueNotifier<List<Note>>? filteredNotesNotifier;

  const NotesGridView({
    super.key,
    required this.viewTypeNotifier,
    required this.selectedNoteIdsNotifier,
    required this.searchController,
    this.scrollController,
    this.filteredNotesNotifier,
  });

  @override
  State<NotesGridView> createState() => _NotesGridViewState();
}

class _NotesGridViewState extends State<NotesGridView> {
  late final ScrollController _scrollController;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier(0);
  late final ValueNotifier<List<Note>> _filteredNotesNotifier;
  bool _ownsFilteredNotifier = false;
  NotesProvider? _notesProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    if (widget.filteredNotesNotifier != null) {
      _filteredNotesNotifier = widget.filteredNotesNotifier!;
      _ownsFilteredNotifier = false;
    } else {
      _filteredNotesNotifier = ValueNotifier([]);
      _ownsFilteredNotifier = true;
    }
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotesProvider>();
    if (_notesProvider != provider) {
      _notesProvider?.removeListener(_onProviderChanged);
      _notesProvider = provider;
      _notesProvider!.addListener(_onProviderChanged);
      // Initial sync
      _syncFilteredNotes(provider.notes);
    }
  }

  @override
  void dispose() {
    _notesProvider?.removeListener(_onProviderChanged);
    widget.searchController.removeListener(_onSearchChanged);
    if (widget.scrollController == null) _scrollController.dispose();
    _closeAllSlidables.dispose();
    if (_ownsFilteredNotifier) _filteredNotesNotifier.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) _syncFilteredNotes(_notesProvider!.notes);
  }

  String _lastSearchQuery = '';

  void _onSearchChanged() {
    final query = widget.searchController.text;
    if (query == _lastSearchQuery) return; // تجاهل إذا لم يتغير النص
    _lastSearchQuery = query;
    _syncFilteredNotes(_notesProvider?.notes ?? []);
  }

  void _syncFilteredNotes(List<Note> notes) {
    final newFiltered = _filterNotes(notes);
    final current = _filteredNotesNotifier.value;
    // مقارنة عميقة بالـ IDs — لا تُحدّث إذا كانت القائمة نفسها
    if (newFiltered.length == current.length &&
        newFiltered.every((n) {
          final i = newFiltered.indexOf(n);
          return i < current.length && current[i].id == n.id && current[i].updatedAt == n.updatedAt;
        })) {
      return;
    }
    _filteredNotesNotifier.value = newFiltered;
  }

  List<Note> _filterNotes(List<Note> notes) {
    final searchQuery = widget.searchController.text.toLowerCase();
    return notes.where((note) {
      if (note.isLocked || note.isArchived || note.isTrashed) return false;
      if (searchQuery.isEmpty) return true;

      if (searchQuery.startsWith('type:')) {
        return _matchNoteType(note, searchQuery.substring(5));
      }
      if (searchQuery.startsWith('pinned:')) return note.isPinned;

      final normalized = Note.normalize(searchQuery);
      if (note.normalizedTitle.contains(normalized) ||
          note.normalizedContent.contains(normalized)) {
        return true;
      }

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
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    final m = s1.length, n = s2.length;
    final dp = List.generate(
        m + 1, (i) => List.generate(n + 1, (j) => i == 0 ? j : j == 0 ? i : 0));
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
    return _NotesSliversView(
      viewTypeNotifier: widget.viewTypeNotifier,
      filteredNotesNotifier: _filteredNotesNotifier,
      selectedNoteIdsNotifier: widget.selectedNoteIdsNotifier,
      closeAllSlidables: _closeAllSlidables,
    );
  }
}

class _NotesSliversView extends StatefulWidget {
  final ValueNotifier<String> viewTypeNotifier;
  final ValueNotifier<List<Note>> filteredNotesNotifier;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final ValueNotifier<int> closeAllSlidables;

  const _NotesSliversView({
    required this.viewTypeNotifier,
    required this.filteredNotesNotifier,
    required this.selectedNoteIdsNotifier,
    required this.closeAllSlidables,
  });

  @override
  State<_NotesSliversView> createState() => _NotesSliversViewState();
}

class _NotesSliversViewState extends State<_NotesSliversView> {
  List<Note> _filteredNotes = [];
  String _viewTypeName = 'listCompact';

  @override
  void initState() {
    super.initState();
    _filteredNotes = widget.filteredNotesNotifier.value;
    _viewTypeName = widget.viewTypeNotifier.value;
    widget.filteredNotesNotifier.addListener(_onNotesChanged);
    widget.viewTypeNotifier.addListener(_onViewTypeChanged);
    // selectedNoteIdsNotifier لا يُشغّل setState هنا — كل بطاقة تقرأه مباشرة
  }

  @override
  void dispose() {
    widget.filteredNotesNotifier.removeListener(_onNotesChanged);
    widget.viewTypeNotifier.removeListener(_onViewTypeChanged);
    super.dispose();
  }

  void _onNotesChanged() =>
      setState(() => _filteredNotes = widget.filteredNotesNotifier.value);

  void _onViewTypeChanged() =>
      setState(() => _viewTypeName = widget.viewTypeNotifier.value);

  ViewType get _viewType {
    switch (_viewTypeName) {
      case 'grid':
        return ViewType.grid;
      case 'listExpanded':
        return ViewType.listExpanded;
      default:
        return ViewType.listCompact;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredNotes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No notes',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final fabBottom = MediaQuery.of(context).padding.bottom +
        kBottomNavigationBarHeight +
        16;
    final bottomPadding = fabBottom + 56 + 8;

    if (_viewType == ViewType.grid) {
      return SliverPadding(
        padding:
            EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200
              ? 4
              : MediaQuery.of(context).size.width >= 600
                  ? 3
                  : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: _filteredNotes.length,
          itemBuilder: (context, index) =>
              _buildNoteCard(_filteredNotes[index], 'home_grid'),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildNoteCard(_filteredNotes[index], 'home_list'),
          childCount: _filteredNotes.length,
          findChildIndexCallback: (key) {
            final id = (key as ValueKey<int>).value;
            final index = _filteredNotes.indexWhere((n) => n.id == id);
            return index == -1 ? null : index;
          },
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, String source) {
    if (source == 'home_grid') {
      return _NoteCardWrapper(
        note: note,
        viewType: _viewType,
        closeAllSlidables: widget.closeAllSlidables,
        selectedNoteIdsNotifier: widget.selectedNoteIdsNotifier,
        source: source,
      );
    }
    return RepaintBoundary(
      key: ValueKey<int>(note.id!),
      child: _HeightRecorder(
        noteId: note.id!,
        child: _NoteCardWrapper(
          note: note,
          viewType: _viewType,
          closeAllSlidables: widget.closeAllSlidables,
          selectedNoteIdsNotifier: widget.selectedNoteIdsNotifier,
          source: source,
        ),
      ),
    );
  }
}

/// كل بطاقة تستمع لـ selectedNoteIdsNotifier بنفسها
/// بدل أن يُعيد _NotesSliversView بناء الكل عند تغيير الـ selection
class _NoteCardWrapper extends StatefulWidget {
  final Note note;
  final ViewType viewType;
  final ValueNotifier<int> closeAllSlidables;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final String source;

  const _NoteCardWrapper({
    required this.note,
    required this.viewType,
    required this.closeAllSlidables,
    required this.selectedNoteIdsNotifier,
    required this.source,
  });

  @override
  State<_NoteCardWrapper> createState() => _NoteCardWrapperState();
}

class _NoteCardWrapperState extends State<_NoteCardWrapper> {
  bool _isSelected = false;
  bool _selectionMode = false;
  bool _isCurrentlyOpen = false;
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void initState() {
    super.initState();
    _updateSelection(widget.selectedNoteIdsNotifier.value);
    widget.selectedNoteIdsNotifier.addListener(_onSelectionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SelectedNoteProvider>();
    if (_selectedNoteProvider != provider) {
      _selectedNoteProvider?.removeListener(_onOpenChanged);
      _selectedNoteProvider = provider;
      _selectedNoteProvider!.addListener(_onOpenChanged);
      _isCurrentlyOpen = provider.selectedNote?.id == widget.note.id;
    }
  }

  @override
  void dispose() {
    widget.selectedNoteIdsNotifier.removeListener(_onSelectionChanged);
    _selectedNoteProvider?.removeListener(_onOpenChanged);
    super.dispose();
  }

  void _onOpenChanged() {
    final newOpen = _selectedNoteProvider?.selectedNote?.id == widget.note.id;
    if (newOpen != _isCurrentlyOpen) {
      setState(() => _isCurrentlyOpen = newOpen);
    }
  }

  void _onSelectionChanged() {
    final ids = widget.selectedNoteIdsNotifier.value;
    final newSelected = ids.contains(widget.note.id);
    final newMode = ids.isNotEmpty;
    if (newSelected != _isSelected || newMode != _selectionMode) {
      setState(() {
        _isSelected = newSelected;
        _selectionMode = newMode;
      });
    }
  }

  void _updateSelection(Set<int> ids) {
    _isSelected = ids.contains(widget.note.id);
    _selectionMode = ids.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _isCurrentlyOpen
          ? const EdgeInsets.only(left: 4)
          : EdgeInsets.zero,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isCurrentlyOpen ? 3 : 0,
            height: 48,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: NoteCardWidget(
              key: ValueKey(widget.note.id),
              note: widget.note,
              viewType: widget.viewType,
              closeAllSlidables: widget.closeAllSlidables,
              isCurrentlyOpen: _isCurrentlyOpen,
              onNoteChanged: () {},
              isSelected: _isSelected,
              selectionMode: _selectionMode,
              source: widget.source,
              onLongPress: () {
                if (widget.selectedNoteIdsNotifier.value.isNotEmpty) return;
                widget.selectedNoteIdsNotifier.value = {widget.note.id!};
              },
              onTap: () {
                final current = widget.selectedNoteIdsNotifier.value;
                if (current.isNotEmpty) {
                  final newSet = Set<int>.from(current);
                  if (newSet.contains(widget.note.id)) {
                    newSet.remove(widget.note.id);
                  } else {
                    newSet.add(widget.note.id!);
                  }
                  widget.selectedNoteIdsNotifier.value = Set<int>.of(newSet);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeightRecorder extends StatefulWidget {
  final int noteId;
  final Widget child;

  const _HeightRecorder({required this.noteId, required this.child});

  @override
  State<_HeightRecorder> createState() => _HeightRecorderState();
}

class _HeightRecorderState extends State<_HeightRecorder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ro = context.findRenderObject() as RenderBox?;
      if (ro != null && ro.hasSize) {
        NoteCardKeyRegistry.instance.recordHeight(widget.noteId, ro.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
