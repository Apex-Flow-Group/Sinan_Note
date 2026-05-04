// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/main.dart' show bottomNavHiddenNotifier;
import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/widgets/home/notes_grid/height_recorder.dart';
import 'package:apex_note/widgets/home/notes_grid/note_card_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NotesSliverView extends StatefulWidget {
  final ValueNotifier<String> viewTypeNotifier;
  final ValueNotifier<List<Note>> filteredNotesNotifier;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final ValueNotifier<int> closeAllSlidables;
  final ValueNotifier<bool> hasMoreNotifier;
  final ValueNotifier<bool> isFilteringNotifier;

  const NotesSliverView({
    super.key,
    required this.viewTypeNotifier,
    required this.filteredNotesNotifier,
    required this.selectedNoteIdsNotifier,
    required this.closeAllSlidables,
    required this.hasMoreNotifier,
    required this.isFilteringNotifier,
  });

  @override
  State<NotesSliverView> createState() => _NotesSliverViewState();
}

class _NotesSliverViewState extends State<NotesSliverView> {
  List<Note> _filteredNotes = [];
  String _viewTypeName = 'listCompact';
  bool _hasMore = false;
  bool _isNavHidden = false;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _filteredNotes = widget.filteredNotesNotifier.value;
    _viewTypeName = widget.viewTypeNotifier.value;
    _hasMore = widget.hasMoreNotifier.value;
    _isNavHidden = bottomNavHiddenNotifier.value;
    _isFiltering = widget.isFilteringNotifier.value;
    widget.filteredNotesNotifier.addListener(_onNotesChanged);
    widget.viewTypeNotifier.addListener(_onViewTypeChanged);
    widget.hasMoreNotifier.addListener(_onHasMoreChanged);
    widget.isFilteringNotifier.addListener(_onFilteringChanged);
    bottomNavHiddenNotifier.addListener(_onNavHiddenChanged);
  }

  @override
  void dispose() {
    widget.filteredNotesNotifier.removeListener(_onNotesChanged);
    widget.viewTypeNotifier.removeListener(_onViewTypeChanged);
    widget.hasMoreNotifier.removeListener(_onHasMoreChanged);
    widget.isFilteringNotifier.removeListener(_onFilteringChanged);
    bottomNavHiddenNotifier.removeListener(_onNavHiddenChanged);
    super.dispose();
  }

  void _onNavHiddenChanged() => setState(() => _isNavHidden = bottomNavHiddenNotifier.value);
  void _onFilteringChanged() => setState(() => _isFiltering = widget.isFilteringNotifier.value);
  void _onHasMoreChanged() => setState(() => _hasMore = widget.hasMoreNotifier.value);
  void _onNotesChanged() => setState(() => _filteredNotes = widget.filteredNotesNotifier.value);
  void _onViewTypeChanged() => setState(() => _viewTypeName = widget.viewTypeNotifier.value);

  ViewType get _viewType {
    switch (_viewTypeName) {
      case 'grid': return ViewType.grid;
      case 'listExpanded': return ViewType.listExpanded;
      default: return ViewType.listCompact;
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
              Text('No notes', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final navBarHeight = _isNavHidden ? 0.0 : kBottomNavigationBarHeight;
    final bottomPadding = MediaQuery.of(context).padding.bottom + navBarHeight + 16 + 56 + 8;

    if (_viewType == ViewType.grid) {
      return SliverPadding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : MediaQuery.of(context).size.width >= 600 ? 3 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: _filteredNotes.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredNotes.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            }
            return _buildCard(_filteredNotes[index], 'home_grid');
          },
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _filteredNotes.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            }
            return _buildCard(_filteredNotes[index], 'home_list');
          },
          childCount: _filteredNotes.length + (_hasMore ? 1 : 0),
          findChildIndexCallback: (key) {
            if (key is! ValueKey<int>) return null;
            final index = _filteredNotes.indexWhere((n) => n.id == key.value);
            return index == -1 ? null : index;
          },
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  Widget _buildCard(Note note, String source) {
    final wrapper = NoteCardWrapper(
      note: note,
      viewType: _viewType,
      closeAllSlidables: widget.closeAllSlidables,
      selectedNoteIdsNotifier: widget.selectedNoteIdsNotifier,
      source: source,
      isFiltering: _isFiltering,
    );

    if (source == 'home_grid') return wrapper;

    return RepaintBoundary(
      key: ValueKey<int>(note.id!),
      child: HeightRecorder(noteId: note.id!, child: wrapper),
    );
  }
}
