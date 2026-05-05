// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/search_mixin.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/common/selected_note_indicator.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SearchMixin {
  bool _selectionMode = false;
  final Set<int> _selectedNotes = {};
  String _sortBy = 'date';

  bool get _isSearchActive => isSearchActive;
  void _exitSearch() => exitSearch();

  Color _getTextColor(int colorIndex) {
    final brightness = Theme.of(context).brightness;
    final color = AppColorPalette.palette[colorIndex].getColor(brightness);
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    initSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchTrashedNotes();
    });
  }

  @override
  void dispose() {
    UnifiedNotificationService().commitAll();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes.where((note) {
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

  Widget _buildChecklistPreview(String content, Color textColor) {
    final items = ChecklistFormatter.parseJson(content).take(3).toList();
    if (items.isEmpty) {
      return Text(
        content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(
                item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: item.isDone
                    ? Colors.green.withValues(alpha: 0.7)
                    : textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.text.isEmpty ? 'Mission...' : item.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isDone
                        ? textColor.withValues(alpha: 0.5)
                        : textColor.withValues(alpha: 0.7),
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
      onUndo: () async {
        await notesProvider.trashNotes(ids);
      },
      undoLabel: l10n.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final trashedNotes = _filterNotes(notesProvider.trashedNotes);

        return PopScope(
          canPop: !_selectionMode && !_isSearchActive,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedNotes.clear();
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
            body: SafeArea(
              child: Column(
                children: [
                  Builder(builder: (ctx) {
                    if (_selectionMode) {
                      return SearchableHeader(
                        title: '${_selectedNotes.length} ${l10n.selected}',
                        isSearching: false,
                        hideSearchFrame: true,
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
                      isSearching: _isSearchActive,
                      noteCount: trashedNotes.length,
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
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
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.permanentDelete),
                                    content: Text(l10n.confirmDeleteAll),
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
                                  for (var note in trashedNotes) {
                                    await notesProvider.deleteNote(note.id!);
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  Expanded(
                    child: trashedNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? (l10n.emptyTrash)
                                      : (l10n.noResults),
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: trashedNotes.length,
                            itemBuilder: (context, index) {
                              final note = trashedNotes[index];
                              final isSelected =
                                  _selectedNotes.contains(note.id);
                              return SelectedNoteIndicator(
                                note: note,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 8),
                                  color: AppColorPalette
                                      .palette[note.colorIndex]
                                      .getColor(Theme.of(context).brightness),
                                  child: InkWell(
                                    onTap: () async {
                                      if (_selectionMode) {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedNotes.remove(note.id);
                                          } else {
                                            _selectedNotes.add(note.id!);
                                          }
                                        });
                                      } else {
                                        final isDesktop =
                                            MediaQuery.of(context).size.width >=
                                                600;
                                        if (isDesktop) {
                                          Provider.of<SelectedNoteProvider>(
                                                  context,
                                                  listen: false)
                                              .selectNote(note);
                                        } else {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  NoteEditorImmersive(
                                                note: note,
                                                mode: NoteCardUtils.getNoteMode(
                                                    note),
                                                readOnly: true,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_selectionMode) {
                                        setState(() {
                                          _selectionMode = true;
                                          _selectedNotes.add(note.id!);
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          if (_selectionMode)
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedNotes
                                                        .add(note.id!);
                                                  } else {
                                                    _selectedNotes
                                                        .remove(note.id);
                                                  }
                                                });
                                              },
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  note.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getTextColor(
                                                        note.colorIndex),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                ChecklistFormatter
                                                        .isValidChecklist(
                                                            note.content)
                                                    ? _buildChecklistPreview(
                                                        note.content,
                                                        _getTextColor(
                                                            note.colorIndex))
                                                    : Text(
                                                        NoteCardUtils
                                                            .fixNoteContent(
                                                                note.content),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: _getTextColor(
                                                                  note
                                                                      .colorIndex)
                                                              .withValues(
                                                                  alpha: 0.7),
                                                        ),
                                                        maxLines: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ), // Expanded
                ],
              ), // Column
            ), // SafeArea
          ),
        );
      },
    );
  }
}
