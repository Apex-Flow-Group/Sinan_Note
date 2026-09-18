// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show bottomNavHiddenNotifier;
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/widgets/home/notes_grid/height_recorder.dart';
import 'package:sinan_note/widgets/home/notes_grid/note_card_wrapper.dart';

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
  List<Note> _pinnedNotes = const [];
  List<Note> _unpinnedNotes = const [];

  /// موضع كل ملاحظة داخل قسمها — يُبنى مع القائمة لا عند كل بحث عن بطاقة
  final Map<int, int> _indexInFiltered = {};
  final Map<int, int> _indexInUnpinned = {};
  String _viewTypeName = 'listCompact';
  bool _hasMore = false;
  bool _isNavHidden = false;
  bool _isFiltering = false;

  int _getCrossAxisCount(BuildContext context) {
    final mode = PlatformHelper.getDisplayMode(context);
    final width = MediaQuery.of(context).size.width;
    switch (mode) {
      case DisplayMode.desktop:
        return width >= 1200 ? 4 : 3;
      case DisplayMode.tablet:
        return width >= 1200 ? 4 : 3;
      case DisplayMode.foldableOpen:
        return 3;
      case DisplayMode.phone:
        return 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _setNotes(widget.filteredNotesNotifier.value);
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

  void _onNavHiddenChanged() =>
      setState(() => _isNavHidden = bottomNavHiddenNotifier.value);
  void _onFilteringChanged() =>
      setState(() => _isFiltering = widget.isFilteringNotifier.value);
  void _onHasMoreChanged() =>
      setState(() => _hasMore = widget.hasMoreNotifier.value);
  void _onNotesChanged() =>
      setState(() => _setNotes(widget.filteredNotesNotifier.value));

  void _setNotes(List<Note> notes) {
    _filteredNotes = notes;
    _pinnedNotes = notes.where((note) => note.isPinned).toList(growable: false);
    _unpinnedNotes =
        notes.where((note) => !note.isPinned).toList(growable: false);
    _reindex(_indexInFiltered, _filteredNotes);
    _reindex(_indexInUnpinned, _unpinnedNotes);
  }

  static void _reindex(Map<int, int> target, List<Note> notes) {
    target.clear();
    for (var i = 0; i < notes.length; i++) {
      final id = notes[i].id;
      if (id != null) target[id] = i;
    }
  }

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
              Builder(builder: (ctx) {
                final l10n = Localizations.of(ctx, AppLocalizations);
                return Text(
                  l10n?.noNotes ?? 'No notes',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                );
              }),
            ],
          ),
        ),
      );
    }

    final navBarHeight = _isNavHidden ? 0.0 : kBottomNavigationBarHeight;
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + navBarHeight + 16 + 56 + 8;

    return SliverMainAxisGroup(slivers: _buildNoteSlivers(bottomPadding));
  }

  List<Widget> _buildNoteSlivers(double bottomPadding) {
    // عنوان واحد بلا مقابل لا يفصل شيئاً — نعرض الفواصل فقط عند وجود المجموعتين
    if (_pinnedNotes.isEmpty || _unpinnedNotes.isEmpty) {
      return [
        _buildNotesSliver(_filteredNotes, _indexInFiltered, bottomPadding),
      ];
    }

    final l10n = AppLocalizations.of(context);
    return [
      _buildSectionLabel(
        l10n?.sectionPinned ?? 'Pinned',
        Icons.push_pin_rounded,
      ),
      _buildNotesSliver(
        _pinnedNotes,
        const {},
        0,
        showLoader: false,
        lazy: false,
      ),
      _buildSectionLabel(
        l10n?.sectionOthers ?? 'Others',
        Icons.sticky_note_2_rounded,
      ),
      _buildNotesSliver(_unpinnedNotes, _indexInUnpinned, bottomPadding),
    ];
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.45,
        );
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [lazy] يجب أن يكون `false` لكل قسم ما عدا واحد:
  /// `SliverMasonryGrid` لا يحتمل وجود نسختين كسولتين في نفس ScrollView —
  /// الثانية تُجمّد التمرير قبل نهاية القائمة.
  Widget _buildNotesSliver(
    List<Note> notes,
    Map<int, int> index,
    double bottomPadding, {
    bool showLoader = true,
    bool lazy = true,
  }) {
    final padding =
        EdgeInsets.only(left: 4, right: 4, top: 4, bottom: bottomPadding);
    final loader = showLoader && _hasMore;
    final childCount = notes.length + (loader ? 1 : 0);

    Widget builder(BuildContext context, int index, String source) {
      if (index == notes.length) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _buildCard(notes[index], source);
    }

    if (_viewType == ViewType.grid && !lazy) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: MasonryGridView.count(
            crossAxisCount: _getCrossAxisCount(context),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: childCount,
            itemBuilder: (context, index) =>
                builder(context, index, 'home_grid'),
          ),
        ),
      );
    }

    if (_viewType == ViewType.grid) {
      return SliverPadding(
        padding: padding,
        sliver: SliverMasonryGrid(
          key: ValueKey<int?>(notes.isEmpty ? null : notes.first.id),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => builder(context, index, 'home_grid'),
            childCount: childCount,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => builder(context, index, 'home_list'),
          childCount: childCount,
          findChildIndexCallback: (key) => _findIndexIn(index, key),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  static int? _findIndexIn(Map<int, int> index, Key key) {
    if (key is! ValueKey<int>) return null;
    return index[key.value];
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

    return RepaintBoundary(
      key: ValueKey<int>(note.id!),
      child: source == 'home_grid'
          ? wrapper
          : HeightRecorder(noteId: note.id!, child: wrapper),
    );
  }
}
