// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/search_mixin.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show tabToHomeNotifier;
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/widgets/common/custom_share_sheet.dart';
import 'package:sinan_note/widgets/common/searchable_header.dart';
import 'package:sinan_note/widgets/common/selected_note_indicator.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/editor/category_picker_sheet.dart';
import 'package:sinan_note/widgets/home/add_menu_widget.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';
import 'package:sinan_note/widgets/home/note_card_widget.dart';
import 'package:sinan_note/widgets/home/selection_action_bar.dart';

class CodeTab extends StatefulWidget {
  const CodeTab({super.key});

  @override
  State<CodeTab> createState() => _CodeTabState();
}

class _CodeTabState extends State<CodeTab> with SearchMixin {
  bool _showAddMenu = false;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  final ValueNotifier<Set<int>> _selectedNoteIdsNotifier = ValueNotifier({});
  String _sortBy = 'date';
  ViewType _viewType = ViewType.listExpanded;
  NotesProvider? _notesProvider;
  final ValueNotifier<List<Note>> _filteredNotesNotifier = ValueNotifier([]);
  String _lastSearchQuery = '';
  bool _isSearchMode = false;

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
    _selectedNoteIdsNotifier.dispose();
    _filteredNotesNotifier.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) _syncNotes();
  }

  void _syncNotes() {
    final query = searchController.text;
    if (query == _lastSearchQuery && _filteredNotesNotifier.value.isNotEmpty) {
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
        if (savedType == 'listCompact') {
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
        return note.normalizedTitle.contains(Note.normalize(searchQuery)) ||
            note.normalizedContent.contains(Note.normalize(searchQuery));
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
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_isSearchMode) {
            setState(() {
              _isSearchMode = false;
              exitSearch();
            });
          } else if (searchController.text.isNotEmpty) {
            setState(() => searchController.clear());
          } else {
            tabToHomeNotifier.value++;
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
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: _selectedNoteIdsNotifier,
                      builder: (context, selectedIds, _) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final inSelection = selectedIds.isNotEmpty;
                        if (inSelection) {
                          return SliverAppBar(
                            pinned: true,
                            automaticallyImplyLeading: false,
                            titleSpacing: 0,
                            title: SelectionActionBar(
                              key: const ValueKey('selection'),
                              selectedIdsNotifier: _selectedNoteIdsNotifier,
                              isDark: isDark,
                              allPinned: false,
                              onClear: () =>
                                  _selectedNoteIdsNotifier.value = {},
                              onPin: () async {
                                final provider = Provider.of<NotesProvider>(
                                    context,
                                    listen: false);
                                final ids = List<int>.from(selectedIds);
                                for (final id in ids) {
                                  final note = provider.notes
                                      .firstWhere((n) => n.id == id);
                                  await provider.updateNote(note.copyWith(
                                      isPinned: !note.isPinned,
                                      updatedAt: DateTime.now()));
                                }
                                _selectedNoteIdsNotifier.value = {};
                                if (context.mounted) {
                                  UnifiedNotificationService().show(
                                      context: context,
                                      message:
                                          '${ids.length} ${strings.notesPinned}',
                                      type: NotificationType.success);
                                }
                              },
                              onArchive: () async {
                                final provider = Provider.of<NotesProvider>(
                                    context,
                                    listen: false);
                                final ids = List<int>.from(selectedIds);
                                await provider.archiveNotes(ids);
                                _selectedNoteIdsNotifier.value = {};
                                if (context.mounted) {
                                  UnifiedNotificationService().show(
                                      context: context,
                                      message:
                                          '${ids.length} ${strings.notesArchived}',
                                      type: NotificationType.success);
                                }
                              },
                              onDelete: () async {
                                final provider = Provider.of<NotesProvider>(
                                    context,
                                    listen: false);
                                final ids = List<int>.from(selectedIds);
                                await provider.trashNotes(ids);
                                _selectedNoteIdsNotifier.value = {};
                                if (context.mounted) {
                                  UnifiedNotificationService().show(
                                      context: context,
                                      message:
                                          '${ids.length} ${strings.notesDeleted}',
                                      type: NotificationType.info);
                                }
                              },
                              onShare: selectedIds.length == 1
                                  ? () {
                                      final provider =
                                          Provider.of<NotesProvider>(context,
                                              listen: false);
                                      final note = provider.notes.firstWhere(
                                          (n) => n.id == selectedIds.first);
                                      _selectedNoteIdsNotifier.value = {};
                                      final content =
                                          NoteCardUtils.fixNoteContent(
                                              note.content,
                                              maxChars: null);
                                      CustomShareSheet.show(
                                          context, '${note.title}\n\n$content',
                                          subject: note.title,
                                          note: note, onNoteCopied: () async {
                                        final provider =
                                            Provider.of<NotesProvider>(context,
                                                listen: false);
                                        await provider.duplicateNote(note.id!,
                                            copyLabel:
                                                AppLocalizations.of(context)!
                                                    .noteCopy);
                                      });
                                    }
                                  : null,
                              onCategory: () async {
                                final provider = Provider.of<NotesProvider>(
                                    context,
                                    listen: false);
                                final ids = List<int>.from(selectedIds);
                                final isSingle = ids.length == 1;
                                final firstNote = provider.notes
                                    .firstWhere((n) => n.id == ids.first);
                                final result = await CategoryPickerSheet.show(
                                  context,
                                  isSingle ? firstNote.categoryIds : [],
                                  isHiddenFromHome: isSingle
                                      ? firstNote.isHiddenFromHome
                                      : false,
                                );
                                if (result == null || !context.mounted) return;
                                final newCatIds =
                                    (result['categoryIds'] as List).cast<int>();
                                final newHidden =
                                    result['isHiddenFromHome'] as bool;
                                for (final id in ids) {
                                  final note = provider.notes
                                      .firstWhere((n) => n.id == id);
                                  final merged = isSingle
                                      ? newCatIds
                                      : {...note.categoryIds, ...newCatIds}
                                          .toList();
                                  await provider.updateNote(note.copyWith(
                                    categoryIds: merged,
                                    isHiddenFromHome: isSingle
                                        ? newHidden
                                        : (note.isHiddenFromHome || newHidden),
                                  ));
                                }
                                _selectedNoteIdsNotifier.value = {};
                              },
                            ),
                          );
                        }
                        return SliverAppBar(
                          pinned: true,
                          automaticallyImplyLeading: false,
                          toolbarHeight: 0,
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(60),
                            child: SearchableHeader(
                              title: strings.professional,
                              icon: Icons.code_rounded,
                              isSearching: _isSearchMode,
                              searchController: searchController,
                              includeSafeArea: false,
                              onSearchChange: (q) {
                                _syncNotes();
                              },
                              onToggleSearch: () {
                                if (_isSearchMode) {
                                  setState(() {
                                    _isSearchMode = false;
                                    exitSearch();
                                  });
                                } else {
                                  setState(() => _isSearchMode = true);
                                }
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _viewType == ViewType.listExpanded
                                          ? Icons.view_headline
                                          : Icons.view_day,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        _viewType =
                                            _viewType == ViewType.listExpanded
                                                ? ViewType.listCompact
                                                : ViewType.listExpanded;
                                      });
                                      await Provider.of<SettingsProvider>(
                                              context,
                                              listen: false)
                                          .setViewType(
                                              'professional', _viewType.name);
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.sort),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      setState(() => _sortBy = value);
                                      _syncNotes();
                                    },
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
                                          Text(strings.sortByDate),
                                          if (_sortBy == 'date') ...[
                                            const Spacer(),
                                            Icon(Icons.check,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary)
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
                                          Text(strings.sortByTitle),
                                          if (_sortBy == 'title') ...[
                                            const Spacer(),
                                            Icon(Icons.check,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary)
                                          ],
                                        ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                            padding: EdgeInsets.fromLTRB(8, 8, 8,
                                MediaQuery.of(context).padding.bottom + 100),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childCount: notes.length,
                              itemBuilder: (context, index) =>
                                  _buildCard(notes[index]),
                            ),
                          );
                        }

                        // listCompact أو listExpanded
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(8, 8, 8,
                              MediaQuery.of(context).padding.bottom + 100),
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
                final settings =
                    Provider.of<SettingsProvider>(context, listen: false);
                final notesProvider =
                    Provider.of<NotesProvider>(context, listen: false);
                final colorMode = switch (mode) {
                  NoteMode.code => 'professional',
                  NoteMode.checklist => 'checklist',
                  NoteMode.rich => 'rich',
                  NoteMode.reminder => 'reminder',
                  _ => 'simple',
                };
                await AppNavigator.toEditor(
                  context,
                  mode: mode,
                  note: notesProvider.createDefaultNote(
                    mode: mode,
                    colorIndex: settings.getDefaultColorIndex(colorMode),
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
      child: ValueListenableBuilder<Set<int>>(
        valueListenable: _selectedNoteIdsNotifier,
        builder: (context, selectedIds, _) {
          final isSelected = selectedIds.contains(note.id);
          final selectionMode = selectedIds.isNotEmpty;
          return Selector<SelectedNoteProvider, bool>(
            selector: (_, p) => p.selectedNote?.id == note.id,
            builder: (context, isCurrentlyOpen, _) {
              return SelectedNoteIndicator(
                note: note,
                child: NoteCardWidget(
                  note: note,
                  viewType: _viewType,
                  closeAllSlidables: _closeAllSlidables,
                  onNoteChanged: () {
                    _syncNotes();
                  },
                  isSelected: isSelected,
                  selectionMode: selectionMode,
                  source: 'professional',
                  isFiltering: false,
                  isCurrentlyOpen: isCurrentlyOpen,
                  onLongPress: () {
                    if (_selectedNoteIdsNotifier.value.isNotEmpty) return;
                    _selectedNoteIdsNotifier.value = {note.id!};
                  },
                  onTap: () {
                    final current = _selectedNoteIdsNotifier.value;
                    if (current.isNotEmpty) {
                      final newSet = Set<int>.from(current);
                      if (newSet.contains(note.id)) {
                        newSet.remove(note.id);
                      } else {
                        newSet.add(note.id!);
                      }
                      _selectedNoteIdsNotifier.value = Set<int>.of(newSet);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
