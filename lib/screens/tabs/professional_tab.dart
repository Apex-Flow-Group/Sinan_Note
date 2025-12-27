// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/note.dart';
import '../../models/note_mode.dart';
import '../../services/notes_provider.dart';
import '../../services/settings_provider.dart';

import '../../l10n/l10n_migration_helper.dart';
import '../../widgets/home/note_card_widget.dart';
import '../../widgets/home/add_menu_widget.dart';
import '../../screens/home_screen.dart' show ViewType;
import '../note_editor.dart';

class ProfessionalTab extends StatefulWidget {
  const ProfessionalTab({super.key});

  @override
  State<ProfessionalTab> createState() => _ProfessionalTabState();
}

class _ProfessionalTabState extends State<ProfessionalTab> {
  bool _showAddMenu = false;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  String _searchQuery = '';
  ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date'; // date, title

  @override
  void initState() {
    super.initState();
    _loadViewType();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // ❌ REMOVED: loadNotes() - data is already loaded by MainLayoutScreen
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

  @override
  void dispose() {
    _searchController.dispose();
    _closeAllSlidables.dispose();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
            note.content.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    // Sort
    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nHelper.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final professionalNotes = _filterNotes(notesProvider.notes
            .where((note) =>
                (note.noteType == 'pro' ||
                    note.noteType == 'code' ||
                    note.noteType == 'professional') &&
                !note.isArchived &&
                !note.isTrashed)
            .toList());

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
          body: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _closeAllSlidables.value++,
                child: SlidableAutoCloseBehavior(
                  child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: _searchController.text.isEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.code_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(strings.professional),
                            ],
                          )
                        : TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: strings.searchNotes,
                              border: InputBorder.none,
                            ),
                          ),
                    actions: [
                      IconButton(
                        icon: Icon(_searchController.text.isEmpty
                            ? Icons.search
                            : Icons.close),
                        onPressed: () {
                          setState(() {
                            if (_searchController.text.isEmpty) {
                              _searchController.text = ' ';
                            } else {
                              _searchController.clear();
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
                          final settings = Provider.of<SettingsProvider>(context, listen: false);
                          await settings.setViewType('professional', _viewType.name);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'date', child: Text(strings.sortByDate)),
                          PopupMenuItem(
                              value: 'title', child: Text(strings.sortByTitle)),
                        ],
                      ),
                    ],
                    floating: true,
                    snap: true,
                    pinned: false,
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
                  ),
                  professionalNotes.isEmpty
                      ? SliverFillRemaining(
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
                        )
                      : _viewType == ViewType.grid
                          ? SliverPadding(
                              padding: const EdgeInsets.all(8),
                              sliver: SliverMasonryGrid.count(
                                crossAxisCount: MediaQuery.of(context)
                                            .size
                                            .width >=
                                        1200
                                    ? 4
                                    : MediaQuery.of(context).size.width >= 600
                                        ? 3
                                        : 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childCount: professionalNotes.length,
                                itemBuilder: (context, index) {
                                  final note = professionalNotes[index];
                                  return NoteCardWidget(
                                    note: note,
                                    viewType: _viewType,
                                    closeAllSlidables: _closeAllSlidables,
                                    onNoteChanged: () => setState(() {}),
                                    onLongPress: () {},
                                    source: 'professional',
                                  );
                                },
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.all(8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final note = professionalNotes[index];
                                    return NoteCardWidget(
                                      note: note,
                                      viewType: _viewType,
                                      closeAllSlidables: _closeAllSlidables,
                                      onNoteChanged: () => setState(() {}),
                                      onLongPress: () {},
                                      source: 'professional',
                                    );
                                  },
                                  childCount: professionalNotes.length,
                                ),
                              ),
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
        );
      },
    );
  }
}
