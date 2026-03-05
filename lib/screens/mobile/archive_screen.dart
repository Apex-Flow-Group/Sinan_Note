// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date';
  bool _selectionMode = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchArchivedNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    UnifiedNotificationService().cancelAll();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes.where((note) {
      if (note.isLocked) return false;
      if (_searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(_searchQuery) ||
          note.content.toLowerCase().contains(_searchQuery);
    }).toList();

    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

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
          canPop: !_selectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedNoteIds.clear();
              });
            }
          },
          child: Scaffold(
          drawer: HomeDrawerWidget(
            onBackupTap: () {},
            onNotesChanged: () {},
          ),
          appBar: AppBar(
            leading: _selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectionMode = false;
                        _selectedNoteIds.clear();
                      });
                    },
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            title: _selectionMode
                ? Text('${_selectedNoteIds.length} ${l10n.selected}')
                : _searchController.text.isEmpty
                    ? Text(l10n.archive)
                    : TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.searchNotes,
                          border: InputBorder.none,
                        ),
                      ),
            actions: [
              if (_selectionMode && _selectedNoteIds.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.unarchive, color: Colors.green),
                  onPressed: _restoreSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelected,
                ),
                IconButton(
                  icon: Icon(
                    _selectedNoteIds.length == archivedNotes.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_selectedNoteIds.length == archivedNotes.length) {
                        _selectedNoteIds.clear();
                      } else {
                        _selectedNoteIds.clear();
                        _selectedNoteIds.addAll(
                            archivedNotes.map((n) => n.id!).toSet());
                      }
                    });
                  },
                ),
              ] else ...[
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'date',
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 20, color: _sortBy == 'date' ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 12),
                          Text(l10n.sortByDate),
                          if (_sortBy == 'date') ...[
                            const Spacer(),
                            Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'title',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 20, color: _sortBy == 'title' ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 12),
                          Text(l10n.sortByTitle),
                          if (_sortBy == 'title') ...[
                            const Spacer(),
                            Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
          body: archivedNotes.isEmpty
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
                    return NoteCardWidget(
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
                                Provider.of<SelectedNoteProvider>(context, listen: false).selectNote(note);
                              }
                            },
                      source: 'archive',
                      selectionMode: _selectionMode,
                      isSelected: isSelected,
                    );
                  },
                ),
          ),
        );
      },
    );
  }
}
