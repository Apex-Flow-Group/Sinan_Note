// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/search_mixin.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/common/selected_note_indicator.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with SearchMixin {
  final ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date';
  bool _selectionMode = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    initSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchArchivedNotes();
    });
  }

  @override
  void dispose() {
    UnifiedNotificationService().cancelAll();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes.where((note) {
      if (note.isLocked) return false;
      if (searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(searchQuery) ||
          note.content.toLowerCase().contains(searchQuery);
    }).toList();

    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  bool get _isSearchActive => isSearchActive;
  void _exitSearch() => exitSearch();

  void _restoreSelected() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    
    await notesProvider.unarchiveNotes(ids);
    
    setState(() {
      _selectedNoteIds.clear();
      _selectionMode = false;
    });
    
    if (!mounted) return;
    
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: '${ids.length} notes restored',
      actionKey: 'archive_restore',
      type: NotificationType.success,
      onExecute: () {},
      onUndo: () async {
        await notesProvider.archiveNotes(ids);
      },
      undoLabel: AppLocalizations.of(context)!.undo,
    );
  }

  void _deleteSelected() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    
    await notesProvider.trashNotes(ids);
    
    setState(() {
      _selectedNoteIds.clear();
      _selectionMode = false;
    });
    
    if (!mounted) return;
    
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: '${ids.length} notes moved to trash',
      actionKey: 'archive_delete',
      type: NotificationType.info,
      onExecute: () {},
      onUndo: () async {
        await notesProvider.unarchiveNotes(ids);
      },
      undoLabel: AppLocalizations.of(context)!.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final archivedNotes = _filterNotes(notesProvider.archivedNotes);

        return PopScope(
          canPop: !_selectionMode && !_isSearchActive,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedNoteIds.clear();
              });
            } else if (_isSearchActive) {
              _exitSearch();
            }
          },
          child: Scaffold(
          drawer: HomeDrawerWidget(
            onBackupTap: () {},
            onNotesChanged: () {},
          ),
          body: Column(
            children: [
              Builder(builder: (ctx) {
                if (_selectionMode) {
                  return SearchableHeader(
                    title: '${_selectedNoteIds.length} ${l10n.selected}',
                    isSearching: false,
                    hideSearchFrame: true,
                    searchController: searchController,
                    onToggleSearch: () {},
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectionMode = false;
                        _selectedNoteIds.clear();
                      }),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _selectedNoteIds.length == archivedNotes.length
                                ? Icons.deselect
                                : Icons.select_all,
                          ),
                          onPressed: () => setState(() {
                            if (_selectedNoteIds.length == archivedNotes.length) {
                              _selectedNoteIds.clear();
                            } else {
                              _selectedNoteIds.clear();
                              _selectedNoteIds.addAll(archivedNotes.map((n) => n.id!));
                            }
                          }),
                        ),
                        IconButton(
                          icon: Icon(Icons.unarchive,
                              color: _selectedNoteIds.isNotEmpty ? Colors.green : Colors.grey),
                          onPressed: _selectedNoteIds.isNotEmpty ? _restoreSelected : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: _selectedNoteIds.isNotEmpty ? Colors.red : Colors.grey),
                          onPressed: _selectedNoteIds.isNotEmpty ? _deleteSelected : null,
                        ),
                      ],
                    ),
                  );
                }
                return SearchableHeader(
                  title: l10n.archive,
                  icon: Icons.archive_outlined,
                  isSearching: _isSearchActive,
                  noteCount: archivedNotes.length,
                  searchController: searchController,
                  onSearchChange: (q) => setState(() {}),
                  onToggleSearch: () {
                    if (_isSearchActive) {
                      _exitSearch();
                    } else {
                      setState(() => searchController.text = '');
                      toggleSearch();
                    }
                  },
                  leading: !_isSearchActive
                      ? Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) => setState(() => _sortBy = value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'date',
                            child: Row(children: [
                              Icon(Icons.access_time, size: 20,
                                  color: _sortBy == 'date' ? Theme.of(context).colorScheme.primary : null),
                              const SizedBox(width: 12),
                              Text(l10n.sortByDate),
                              if (_sortBy == 'date') ...[
                                const Spacer(),
                                Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                              ],
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'title',
                            child: Row(children: [
                              Icon(Icons.sort_by_alpha, size: 20,
                                  color: _sortBy == 'title' ? Theme.of(context).colorScheme.primary : null),
                              const SizedBox(width: 12),
                              Text(l10n.sortByTitle),
                              if (_sortBy == 'title') ...[
                                const Spacer(),
                                Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                              ],
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              Expanded(
                child: archivedNotes.isEmpty
                    ? Center(child: Text(l10n.noArchivedNotes))
                    : ListView.builder(
                        padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 8,
                            bottom: MediaQuery.of(context).padding.bottom + 80),
                        itemCount: archivedNotes.length,
                        itemBuilder: (context, index) {
                          final note = archivedNotes[index];
                          final isSelected = _selectedNoteIds.contains(note.id);
                          return SelectedNoteIndicator(
                            note: note,
                            child: NoteCardWidget(
                              note: note,
                              viewType: _viewType,
                              closeAllSlidables: ValueNotifier<int>(0),
                              onNoteChanged: () {
                                Provider.of<NotesProvider>(context, listen: false)
                                    .fetchArchivedNotes();
                              },
                              onLongPress: () {
                                setState(() {
                                  _selectionMode = true;
                                  if (_selectedNoteIds.contains(note.id)) {
                                    _selectedNoteIds.remove(note.id);
                                  } else {
                                    _selectedNoteIds.add(note.id!);
                                  }
                                });
                              },
                              onTap: _selectionMode
                                  ? () {
                                      setState(() {
                                        if (_selectedNoteIds.contains(note.id)) {
                                          _selectedNoteIds.remove(note.id);
                                        } else {
                                          _selectedNoteIds.add(note.id!);
                                        }
                                      });
                                    }
                                  : () {
                                      final isDesktop = MediaQuery.of(context).size.width >= 600;
                                      if (isDesktop) {
                                        Provider.of<SelectedNoteProvider>(context, listen: false)
                                            .selectNote(note);
                                      }
                                    },
                              source: 'archive',
                              isFiltering: false,
                              selectionMode: _selectionMode,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
