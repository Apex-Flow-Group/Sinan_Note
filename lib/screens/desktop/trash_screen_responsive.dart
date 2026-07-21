// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/core/utils/search_mixin.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/screens/mobile/trash_empty_sheet.dart';
import 'package:sinan_note/screens/mobile/trash_screen.dart';
import 'package:sinan_note/widgets/common/searchable_header.dart';
import 'package:sinan_note/widgets/common/selected_note_indicator.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/desktop/desktop_menu_bar.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';
import 'package:sinan_note/widgets/home/note_card_widget.dart';
import 'package:sinan_note/widgets/layout/details_panel.dart';
import 'package:sinan_note/widgets/layout/master_details_layout.dart';

/// شاشة السلة — Responsive
///
/// - Mobile: تعرض [TrashScreen] كما هي
/// - Desktop/Tablet/Foldable: شاشة موحدة بنمط version_history
class TrashScreenResponsive extends StatefulWidget {
  const TrashScreenResponsive({super.key});

  @override
  State<TrashScreenResponsive> createState() => _TrashScreenResponsiveState();
}

class _TrashScreenResponsiveState extends State<TrashScreenResponsive>
    with SearchMixin {
  bool _selectionMode = false;
  final Set<int> _selectedNotes = {};
  String _sortBy = 'date';
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    initSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotesProvider>(context, listen: false).fetchTrashedNotes();
        Provider.of<SelectedNoteProvider>(context, listen: false)
            .clearSelection();
      }
    });
  }

  @override
  void dispose() {
    _closeAllSlidables.dispose();
    UnifiedNotificationService().commitAll();
    super.dispose();
  }

  Future<void> _createNewNote(BuildContext context, NoteMode mode) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    final colorMode = switch (mode) {
      NoteMode.reminder => 'reminder',
      NoteMode.code => 'professional',
      NoteMode.checklist => 'checklist',
      NoteMode.rich => 'rich',
      _ => 'simple',
    };
    final newNote = notesProvider.createDefaultNote(
      mode: mode,
      colorIndex: settings.getDefaultColorIndex(colorMode),
    );
    final noteId = await notesProvider.addOrUpdateNote(newNote, silent: true);
    final savedNote = notesProvider.notes.firstWhere(
      (note) => note.id == noteId,
      orElse: () => newNote,
    );
    selectedNoteProvider.selectNote(savedNote);
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes.where((note) {
      if (searchQuery.isEmpty) return true;
      final q = Note.normalize(searchQuery);
      return note.normalizedTitle.contains(q) ||
          note.normalizedContent.contains(q);
    }).toList();

    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  void _restoreSelectedNotes(NotesProvider notesProvider,
      List<Note> trashedNotes, AppLocalizations l10n) async {
    final ids = List<int>.from(_selectedNotes);
    final notes = trashedNotes.where((n) => ids.contains(n.id)).toList();
    final hasArchived = notes.any((n) => n.isArchived);
    final hasActive = notes.any((n) => !n.isArchived);

    String message;
    if (hasArchived && hasActive) {
      message = l10n.notesRestoredMixed;
    } else if (hasArchived) {
      message = l10n.restoredToArchive;
    } else {
      message = l10n.restoredToHome;
    }

    await notesProvider.restoreNotes(ids);
    if (!mounted) return;

    setState(() {
      _selectionMode = false;
      _selectedNotes.clear();
    });

    UnifiedNotificationService().showWithUndo(
      context: context,
      message: message,
      actionKey: 'trash_restore',
      type: NotificationType.success,
      onExecute: () {},
      onUndo: () async => await notesProvider.trashNotes(ids),
      undoLabel: l10n.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformHelper.shouldUseDesktopLayout(context)) {
      return const TrashScreen();
    }
    return _buildDesktop(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final trashedNotes = _filterNotes(notesProvider.trashedNotes);

        return PopScope(
          canPop: !_selectionMode && !isSearchActive,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedNotes.clear();
              });
            } else if (isSearchActive) {
              exitSearch();
            }
          },
          child: Scaffold(
            drawer: HomeDrawerWidget(
              onBackupTap: () {},
              onNotesChanged: () {},
              onTabSelected: (index) {
                Navigator.of(context, rootNavigator: true)
                    .popUntil((r) => r.settings.name == '/main' || r.isFirst);
                currentTabIndexNotifier.value = index;
              },
            ),
            body: Column(
              children: [
                Builder(builder: (ctx) {
                  if (_selectionMode) {
                    return SearchableHeader(
                      title: '${_selectedNotes.length} ${l10n.selected}',
                      isSearching: false,
                      hideSearchFrame: true,
                      maxWidth: 720,
                      searchController: searchController,
                      onToggleSearch: () {},
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _selectionMode = false;
                          _selectedNotes.clear();
                        }),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _selectedNotes.length == trashedNotes.length
                                  ? Icons.deselect
                                  : Icons.select_all,
                            ),
                            onPressed: () => setState(() {
                              if (_selectedNotes.length ==
                                  trashedNotes.length) {
                                _selectedNotes.clear();
                              } else {
                                _selectedNotes.clear();
                                _selectedNotes
                                    .addAll(trashedNotes.map((n) => n.id!));
                              }
                            }),
                          ),
                          IconButton(
                            icon: Icon(Icons.restore,
                                color: _selectedNotes.isNotEmpty
                                    ? Colors.green
                                    : Colors.grey),
                            onPressed: _selectedNotes.isNotEmpty
                                ? () => _restoreSelectedNotes(
                                    notesProvider, trashedNotes, l10n)
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_forever,
                                color: _selectedNotes.isNotEmpty
                                    ? Colors.red
                                    : Colors.grey),
                            onPressed: _selectedNotes.isNotEmpty
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.permanentDelete),
                                        content: Text(
                                            '${l10n.confirmPermanentDeleteMultiple} ${_selectedNotes.length} ${l10n.notesQuestion}'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text(l10n.cancel)),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: Text(l10n.delete,
                                                  style: const TextStyle(
                                                      color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final ids =
                                          List<int>.from(_selectedNotes);
                                      setState(() {
                                        _selectionMode = false;
                                        _selectedNotes.clear();
                                      });
                                      for (var id in ids) {
                                        await notesProvider.deleteNote(id);
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  }
                  return SearchableHeader(
                    title: l10n.trash,
                    icon: Icons.delete_sweep_outlined,
                    isSearching: isSearchActive,
                    noteCount: trashedNotes.length,
                    maxWidth: 720,
                    searchController: searchController,
                    onSearchChange: (q) => setState(() {}),
                    onToggleSearch: () {
                      if (isSearchActive) {
                        exitSearch();
                      } else {
                        toggleSearch();
                      }
                    },
                    leading: !isSearchActive
                        ? Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          )
                        : null,
                    menuBar: DesktopMenuBar(
                      onNewNote: (mode) => _createNewNote(context, mode),
                      onSearch: () => toggleSearch(),
                      onRefresh: () =>
                          Provider.of<NotesProvider>(context, listen: false)
                              .fetchTrashedNotes(),
                      onSettings: () => AppNavigator.toSettings(context),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) =>
                              setState(() => _sortBy = value),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'date',
                              child: Row(children: [
                                Icon(Icons.access_time,
                                    size: 20,
                                    color: _sortBy == 'date'
                                        ? Theme.of(context).colorScheme.primary
                                        : null),
                                const SizedBox(width: 12),
                                Text(l10n.sortByDate),
                                if (_sortBy == 'date') ...[
                                  const Spacer(),
                                  Icon(Icons.check,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ],
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'title',
                              child: Row(children: [
                                Icon(Icons.sort_by_alpha,
                                    size: 20,
                                    color: _sortBy == 'title'
                                        ? Theme.of(context).colorScheme.primary
                                        : null),
                                const SizedBox(width: 12),
                                Text(l10n.sortByTitle),
                                if (_sortBy == 'title') ...[
                                  const Spacer(),
                                  Icon(Icons.check,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ],
                              ]),
                            ),
                          ],
                        ),
                        if (trashedNotes.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () => TrashEmptySheet.show(context,
                                trashedNotes: trashedNotes,
                                notesProvider: notesProvider),
                          ),
                      ],
                    ),
                  );
                }),
                Expanded(
                  child: MasterDetailsLayout(
                    includeSafeArea: false,
                    masterPanel: _buildNotesList(trashedNotes, l10n),
                    detailsPanel: const DetailsPanel(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(List<Note> trashedNotes, AppLocalizations l10n) {
    if (trashedNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchController.text.isEmpty ? l10n.emptyTrash : l10n.noResults,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: trashedNotes.length,
      itemBuilder: (context, index) {
        final note = trashedNotes[index];
        final isSelected = _selectedNotes.contains(note.id);
        return SelectedNoteIndicator(
          note: note,
          child: NoteCardWidget(
            note: note,
            viewType: ViewType.listExpanded,
            closeAllSlidables: _closeAllSlidables,
            onNoteChanged: () {
              Provider.of<NotesProvider>(context, listen: false)
                  .fetchTrashedNotes();
            },
            onLongPress: () {
              if (!_selectionMode) {
                setState(() {
                  _selectionMode = true;
                  _selectedNotes.add(note.id!);
                });
              }
            },
            onTap: _selectionMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedNotes.remove(note.id);
                      } else {
                        _selectedNotes.add(note.id!);
                      }
                    });
                  }
                : () {
                    Provider.of<SelectedNoteProvider>(context, listen: false)
                        .selectNote(note);
                  },
            source: 'trash',
            isFiltering: false,
            selectionMode: _selectionMode,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}
