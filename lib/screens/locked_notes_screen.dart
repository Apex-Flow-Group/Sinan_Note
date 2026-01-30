// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/logger.dart';
import '../controllers/notes/notes_provider.dart';
import '../models/note.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/home/home_drawer_widget.dart';
import '../widgets/home/note_card_widget.dart';
import '../screens/home_screen.dart' show ViewType;
import 'note_editor.dart';
import 'main_layout_screen.dart';
import '../models/note_mode.dart';
import '../widgets/home/add_menu_widget.dart';

class LockedNotesScreen extends StatefulWidget {
  const LockedNotesScreen({super.key});

  @override
  State<LockedNotesScreen> createState() => _LockedNotesScreenState();
}

class _LockedNotesScreenState extends State<LockedNotesScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  final ViewType _viewType = ViewType.listExpanded;
  bool _isLoading = true;
  List<Note> _decryptedNotes = [];
  NotesProvider? _providerRef;
  bool _showAddMenu = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _providerRef = Provider.of<NotesProvider>(context, listen: false);
      _loadLockedNotes();
      _providerRef!.loadNotes();
    });
  }

  @override
  void dispose() {
    _providerRef?.clearLockedSession(notify: false);
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _closeAllSlidables.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_showAddMenu) {
        setState(() => _showAddMenu = false);
      }
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadLockedNotes() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<NotesProvider>(context, listen: false);
    _decryptedNotes = await provider.fetchAndDecryptLockedNotes();
    AppLogger.info('Loaded ${_decryptedNotes.length} locked notes', 'LockedNotes');
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createLockedNote(NoteMode mode) async {
    AppLogger.info('Creating new locked ${mode.name} note', 'LockedNotes');
    
    String noteType;
    bool isChecklist = false;
    bool isProfessional = false;
    String initialContent = '';
    
    switch (mode) {
      case NoteMode.checklist:
        noteType = 'checklist';
        isChecklist = true;
        initialContent = '{"title":"","items":[]}';
        break;
      case NoteMode.code:
        noteType = 'code';
        isProfessional = true;
        initialContent = '';
        break;
      default:
        noteType = 'simple';
        initialContent = '';
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorImmersive(
          mode: mode,
          skipAuthentication: true,
          note: Note(
            title: '',
            content: initialContent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            colorIndex: 0,
            noteType: noteType,
            isLocked: true,
            isChecklist: isChecklist,
            isProfessional: isProfessional,
          ),
        ),
      ),
    );
    
    AppLogger.info('Editor closed, reloading', 'LockedNotes');
    if (mounted) {
      await _loadLockedNotes();
      AppLogger.info('Locked notes: ${_decryptedNotes.length}', 'LockedNotes');
    }
  }

  Future<void> _showImportSheet() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final allNotes = await provider.getNotes();
    final unlocked = allNotes
        .where((n) => !n.isLocked && !n.isArchived && !n.isTrashed)
        .toList();

    if (unlocked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noUnlockedNotes)),
      );
      return;
    }

    final selected = <int>{};
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.importNotes,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: unlocked.length,
                      itemBuilder: (context, i) {
                        final note = unlocked[i];
                        final isSelected = selected.contains(note.id);
                        
                        String displayTitle = note.title.isEmpty ? l10n.untitled : note.title;
                        String displayContent = note.content;
                        
                        if (note.isChecklist) {
                          try {
                            final decoded = jsonDecode(note.content);
                            if (decoded is Map) {
                              displayTitle = (decoded['title'] ?? '').toString().trim();
                              if (displayTitle.isEmpty) displayTitle = 'Checklist';
                              final items = decoded['items'] as List? ?? [];
                              displayContent = '${items.length} ${items.length == 1 ? 'item' : 'items'}';
                            }
                          } catch (e) {
                            displayContent = 'Checklist';
                          }
                        }
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) => setModalState(() {
                            if (val == true) {
                              selected.add(note.id!);
                            } else {
                              selected.remove(note.id);
                            }
                          }),
                          title: Text(displayTitle, maxLines: 1),
                          subtitle: Text(displayContent,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              for (final id in selected) {
                                await provider.toggleLockStatus(id, true);
                              }
                              Navigator.pop(context);
                              await _loadLockedNotes();
                            },
                      icon: const Icon(Icons.lock),
                      label: Text(l10n.lockNotesCount(selected.length)),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _selectedNoteIds.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _providerRef?.clearLockedSession(notify: false);
          return;
        }
        if (_selectedNoteIds.isNotEmpty) {
          setState(() => _selectedNoteIds.clear());
        }
      },
      child: Scaffold(
      drawer: HomeDrawerWidget(
        onBackupTap: () {},
        onNotesChanged: _loadLockedNotes,
      ),
      appBar: AppBar(
        leading: _selectedNoteIds.isEmpty
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedNoteIds.clear()),
              ),
        title: _selectedNoteIds.isNotEmpty
            ? Row(
                children: [
                  Text('${_selectedNoteIds.length} ${l10n.selected}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.select_all, size: 20),
                    onPressed: () {
                      setState(() {
                        for (final note in _decryptedNotes) {
                          if (!note.isArchived && !note.isTrashed) {
                            _selectedNoteIds.add(note.id!);
                          }
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_open, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.unlockNote),
                          content: Text(l10n.unlockNoteConfirmation),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                for (final id in _selectedNoteIds) {
                                  await _providerRef?.toggleLockStatus(id, false);
                                }
                                setState(() => _selectedNoteIds.clear());
                                await _loadLockedNotes();
                              },
                              child: Text(l10n.unlock),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.permanentDelete),
                          content: Text(l10n.confirmPermanentDelete),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                for (final id in _selectedNoteIds) {
                                  await _providerRef?.trashNote(id);
                                }
                                setState(() => _selectedNoteIds.clear());
                                await _loadLockedNotes();
                              },
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            : _searchController.text.isEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 22),
                      const SizedBox(width: 8),
                      Text(l10n.locked),
                    ],
                  )
                : TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.searchNotes,
                      border: InputBorder.none,
                    ),
                  ),
        actions: _selectedNoteIds.isEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: l10n.import,
                  onPressed: _showImportSheet,
                ),
                IconButton(
                  icon: Icon(
                      _searchController.text.isEmpty ? Icons.search : Icons.close),
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
              ]
            : [],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.decryptingVault,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final query = _searchController.text.toLowerCase();
                    final filteredNotes = _decryptedNotes
                        .where((note) => !note.isArchived && !note.isTrashed)
                        .where((note) {
                      if (query.isEmpty) return true;
                      return note.title.toLowerCase().contains(query) ||
                          note.content.toLowerCase().contains(query);
                    }).toList();

                    if (filteredNotes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open,
                                size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noLockedNotes,
                              style:
                                  const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 8, right: 8, top: 8, bottom: 100),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return NoteCardWidget(
                          note: note,
                          viewType: _viewType,
                          closeAllSlidables: _closeAllSlidables,
                          onNoteChanged: _loadLockedNotes,
                          onLongPress: () => setState(() => _selectedNoteIds.add(note.id!)),
                          source: 'locked',
                          selectionMode: _selectedNoteIds.isNotEmpty,
                          isSelected: _selectedNoteIds.contains(note.id),
                          onTap: () {
                            if (_selectedNoteIds.isNotEmpty) {
                              setState(() {
                                if (_selectedNoteIds.contains(note.id)) {
                                  _selectedNoteIds.remove(note.id);
                                } else {
                                  _selectedNoteIds.add(note.id!);
                                }
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),
          AddMenuWidget(
            showMenu: _showAddMenu,
            onToggle: () => setState(() => _showAddMenu = !_showAddMenu),
            onModeSelected: _createLockedNote,
          ),
        ],
      ),
      ),
    );
  }
}
