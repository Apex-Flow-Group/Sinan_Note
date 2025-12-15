// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/notes_provider.dart';
import '../utils/adaptive_color.dart';

import '../l10n/l10n_migration_helper.dart';

import '../services/toast_service.dart';
import '../widgets/home/home_drawer_widget.dart';
import 'note_view_screen.dart';
import '../utils/checklist_formatter.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<int> _selectedNotes = {};
  String _sortBy = 'date';

  Color _getTextColor(int colorIndex) {
    final brightness = Theme.of(context).brightness;
    final color = AppColorPalette.palette[colorIndex].getColor(brightness);
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchTrashNotes();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final trashedNotes = _filterNotes(notesProvider.trashedNotes);

        return Scaffold(
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
                        _selectedNotes.clear();
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
                ? Text('${_selectedNotes.length} ${l10n.selected}')
                : _searchController.text.isEmpty
                    ? Text(l10n.trash)
                    : TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.searchNotes,
                          border: InputBorder.none,
                        ),
                      ),
            actions: [
              if (_selectionMode && _selectedNotes.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () async {
                    final ids = List<int>.from(_selectedNotes);
                    final notes = trashedNotes.where((n) => ids.contains(n.id)).toList();
                    final hasArchived = notes.any((n) => n.isArchived);
                    final hasActive = notes.any((n) => !n.isArchived);
                    
                    for (var id in ids) {
                      await notesProvider.restoreNote(id);
                    }
                    
                    setState(() {
                      _selectionMode = false;
                      _selectedNotes.clear();
                    });
                    
                    if (!mounted) return;
                    
                    String message;
                    if (hasArchived && hasActive) {
                      message = l10n.notesRestoredMixed;
                    } else if (hasArchived) {
                      message = l10n.restoredToArchive;
                    } else {
                      message = l10n.restoredToHome;
                    }
                    
                    ToastService().showToast(
                      context: context,
                      message: message,
                      type: ToastType.success,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.permanentDelete),
                        content: Text(
                            '${l10n.confirmPermanentDeleteMultiple} ${_selectedNotes.length} ${l10n.notesQuestion}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.delete,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final ids = List<int>.from(_selectedNotes);
                      setState(() {
                        _selectionMode = false;
                        _selectedNotes.clear();
                      });
                      for (var id in ids) {
                        await notesProvider.deleteNote(id);
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    _selectedNotes.length == trashedNotes.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_selectedNotes.length == trashedNotes.length) {
                        _selectedNotes.clear();
                      } else {
                        _selectedNotes.clear();
                        _selectedNotes.addAll(
                            trashedNotes.map((n) => n.id!).toSet());
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
                    PopupMenuItem(
                        value: 'title', child: Text(l10n.sortByTitle)),
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
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ),
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
            ],
          ),
          body: trashedNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? (l10n.emptyTrash)
                            : (l10n.noResults),
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: trashedNotes.length,
                  itemBuilder: (context, index) {
                    final note = trashedNotes[index];
                    final isSelected = _selectedNotes.contains(note.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      color: AppColorPalette.palette[note.colorIndex].getColor(Theme.of(context).brightness),
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoteViewScreen(note: note),
                              ),
                            );
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
                                        _selectedNotes.add(note.id!);
                                      } else {
                                        _selectedNotes.remove(note.id);
                                      }
                                    });
                                  },
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _getTextColor(note.colorIndex),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    ChecklistFormatter.isValidChecklist(note.content)
                                        ? _buildChecklistPreview(note.content, _getTextColor(note.colorIndex))
                                        : Text(
                                            note.content,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _getTextColor(note.colorIndex)
                                                  .withValues(alpha: 0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
