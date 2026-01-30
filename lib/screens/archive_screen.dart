// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/home/home_drawer_widget.dart';
import '../widgets/home/note_card_widget.dart';
import '../screens/home_screen.dart' show ViewType;
import '../services/toast_service.dart';

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
    ToastService().cancelAll();
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
    
    for (final id in ids) {
      await notesProvider.unarchiveNote(id);
    }
    
    setState(() {
      _selectedNoteIds.clear();
      _selectionMode = false;
    });
    
    if (!mounted) return;
    
    ToastService().showToast(
      context: context,
      message: '${ids.length} notes restored',
      type: ToastType.success,
    );
  }

  void _deleteSelected() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    
    for (final id in ids) {
      await notesProvider.trashNote(id);
    }
    
    setState(() {
      _selectedNoteIds.clear();
      _selectionMode = false;
    });
    
    if (!mounted) return;
    
    ToastService().showToast(
      context: context,
      message: '${ids.length} notes moved to trash',
      type: ToastType.info,
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
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'date', child: Text(l10n.sortByDate)),
                    PopupMenuItem(value: 'title', child: Text(l10n.sortByTitle)),
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
                          : null,
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
