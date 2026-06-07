// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/widgets/home/notes_grid/notes_filter_controller.dart';
import 'package:sinan_note/widgets/home/notes_grid/notes_sliver_view.dart';

export 'notes_grid/height_recorder.dart';
export 'notes_grid/note_card_wrapper.dart';
export 'notes_grid/notes_filter_controller.dart';
export 'notes_grid/notes_sliver_view.dart';

class NotesGridView extends StatefulWidget {
  final ValueNotifier<String> viewTypeNotifier;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final TextEditingController searchController;
  final ScrollController? scrollController;
  final ValueNotifier<List<Note>>? filteredNotesNotifier;
  final ValueNotifier<int>? totalCountNotifier;
  final ValueNotifier<int>? visibleCountNotifier;
  final ValueNotifier<String?> activeFilterNotifier;

  const NotesGridView({
    super.key,
    required this.viewTypeNotifier,
    required this.selectedNoteIdsNotifier,
    required this.searchController,
    required this.activeFilterNotifier,
    this.scrollController,
    this.filteredNotesNotifier,
    this.totalCountNotifier,
    this.visibleCountNotifier,
  });

  @override
  State<NotesGridView> createState() => _NotesGridViewState();
}

class _NotesGridViewState extends State<NotesGridView> {
  late final ScrollController _scrollController;
  late final NotesFilterController _filterController;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier(0);
  NotesProvider? _notesProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _filterController = NotesFilterController(
      searchController: widget.searchController,
      activeFilterNotifier: widget.activeFilterNotifier,
      externalFilteredNotifier: widget.filteredNotesNotifier,
      externalTotalNotifier: widget.totalCountNotifier,
      externalVisibleNotifier: widget.visibleCountNotifier,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotesProvider>();
    final catProvider = context.watch<CategoriesProvider>();
    if (_notesProvider != provider) {
      _notesProvider?.removeListener(_onProviderChanged);
      _notesProvider = provider;
      _notesProvider!.addListener(_onProviderChanged);
    }
    _filterController.syncFromProvider(provider, catProvider);
  }

  void _onProviderChanged() {
    if (!mounted) return;
    _filterController.syncFromProvider(
      _notesProvider!,
      context.read<CategoriesProvider>(),
    );
  }

  void _onScroll() => _filterController.onScroll(_scrollController);

  @override
  void dispose() {
    _notesProvider?.removeListener(_onProviderChanged);
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) _scrollController.dispose();
    _closeAllSlidables.dispose();
    _filterController.dispose();
    super.dispose();
  }

  ValueNotifier<int> get totalCountNotifier =>
      _filterController.totalCountNotifier;
  ValueNotifier<int> get visibleCountNotifier =>
      _filterController.visibleCountNotifier;

  @override
  Widget build(BuildContext context) {
    return NotesSliverView(
      viewTypeNotifier: widget.viewTypeNotifier,
      filteredNotesNotifier: _filterController.filteredNotesNotifier,
      selectedNoteIdsNotifier: widget.selectedNoteIdsNotifier,
      closeAllSlidables: _closeAllSlidables,
      hasMoreNotifier: _filterController.hasMoreNotifier,
      isFilteringNotifier: _filterController.isFilteringNotifier,
    );
  }
}

