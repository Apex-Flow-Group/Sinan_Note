// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/search_mixin.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class CodeTab extends StatefulWidget {
  const CodeTab({super.key});

  @override
  State<CodeTab> createState() => _CodeTabState();
}

class _CodeTabState extends State<CodeTab> with SearchMixin {
  bool _showAddMenu = false;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  String _sortBy = 'date';
  ViewType _viewType = ViewType.listExpanded;
  NotesProvider? _notesProvider;
  final ValueNotifier<List<Note>> _filteredNotesNotifier = ValueNotifier([]);
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadViewType();
    initSearch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotesProvider>();
    if (_notesProvider != provider) {
      _notesProvider?.removeListener(_onProviderChanged);
      _notesProvider = provider;
      _notesProvider!.addListener(_onProviderChanged);
      _syncNotes();
    }
  }

  @override
  void dispose() {
    _notesProvider?.removeListener(_onProviderChanged);
    _closeAllSlidables.dispose();
    _filteredNotesNotifier.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) _syncNotes();
  }

  void _syncNotes() {
    final query = searchController.text;
    if (query == _lastSearchQuery &&
        _filteredNotesNotifier.value.isNotEmpty) {
      // أعد الحساب فقط إذا تغيرت البيانات
    }
    _lastSearchQuery = query;
    _filteredNotesNotifier.value = _filterNotes(_notesProvider?.notes ?? []);
  }

  void _loadViewType() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedType = await settings.getViewType('professional');
    if (mounted) {
      setState(() {
        if (savedType == 'grid') {
          _viewType = ViewType.grid;
        } else if (savedType == 'listCompact') {
          _viewType = ViewType.listCompact;
        } else {
          _viewType = ViewType.listExpanded;
        }
      });
    }
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes
        .where((n) => n.isProfessional && !n.isArchived && !n.isTrashed)
        .toList();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(searchQuery) ||
            note.content.toLowerCase().contains(searchQuery);
      }).toList();
    }
    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      body: PopScope(
        canPop: searchController.text.isEmpty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (searchController.text.isNotEmpty) {
            setState(() => searchController.clear());
          }
        },
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _closeAllSlidables.value++,
              child: SlidableAutoCloseBehavior(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: searchController.text.isEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.code_rounded, size: 22),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.professional,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: strings.searchNotes,
                                border: InputBorder.none,
                              ),
                            ),
                      actions: [
                        IconButton(
                          icon: Icon(searchController.text.isEmpty
                              ? Icons.search
                              : Icons.close),
                          onPressed: () {
                            setState(() {
                              if (searchController.text.isEmpty) {
                                searchController.text = ' ';
                              } else {
                                searchController.clear();
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(_viewType == ViewType.grid
                              ? Icons.view_list
                              : Icons.grid_view),
                          onPressed: () async {
                            setState(() {
                              _viewType = _viewType == ViewType.grid
                                  ? ViewType.listExpanded
                                  : ViewType.grid;
                            });
                            final settings = Provider.of<SettingsProvider>(
                                context, listen: false);
                            await settings.setViewType(
                                'professional', _viewType.name);
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                            _syncNotes();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'date',
                              child: Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 20,
                                      color: _sortBy == 'date'
                                          ? Theme.of(context).colorScheme.primary
                                          : null),
                                  const SizedBox(width: 12),
                                  Text(strings.sortByDate),
                                  if (_sortBy == 'date') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'title',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha,
                                      size: 20,
                                      color: _sortBy == 'title'
                                          ? Theme.of(context).colorScheme.primary
                                          : null),
                                  const SizedBox(width: 12),
                                  Text(strings.sortByTitle),
                                  if (_sortBy == 'title') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      floating: true,
                      snap: true,
                      pinned: false,
                    ),
                    ValueListenableBuilder<List<Note>>(
                      valueListenable: _filteredNotesNotifier,
                      builder: (context, notes, _) {
                        if (notes.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.code_off,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    strings.noProfessionalNotes,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (_viewType == ViewType.grid) {
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width >= 1200
                                      ? 4
                                      : MediaQuery.of(context).size.width >= 600
                                          ? 3
                                          : 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childCount: notes.length,
                              itemBuilder: (context, index) =>
                                  _buildCard(notes[index]),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildCard(notes[index]),
                              childCount: notes.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            AddMenuWidget(
              showMenu: _showAddMenu,
              onToggle: () => setState(() => _showAddMenu = !_showAddMenu),
              onModeSelected: (mode) async {
                setState(() => _showAddMenu = false);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorImmersive(
                      mode: mode,
                      note: Note(
                        title: '',
                        content: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        colorIndex: 0,
                        noteType: mode.name,
                        isChecklist: mode == NoteMode.checklist,
                        isProfessional: mode == NoteMode.code,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Note note) {
    return RepaintBoundary(
      key: ValueKey(note.id),
      child: Selector<SelectedNoteProvider, bool>(
        selector: (_, p) => p.selectedNote?.id == note.id,
        builder: (context, isCurrentlyOpen, _) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: isCurrentlyOpen
                ? const EdgeInsets.only(left: 12)
                : EdgeInsets.zero,
            child: NoteCardWidget(
              note: note,
              viewType: _viewType,
              closeAllSlidables: _closeAllSlidables,
              onNoteChanged: () {},
              onLongPress: () {},
              source: 'professional',
              isCurrentlyOpen: isCurrentlyOpen,
            ),
          );
        },
      ),
    );
  }
}
