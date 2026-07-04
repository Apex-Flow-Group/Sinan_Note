// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/core/utils/search_mixin.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/screens/shared/tabs/code_tab.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/searchable_header.dart';
import 'package:sinan_note/widgets/common/selected_note_indicator.dart';
import 'package:sinan_note/widgets/details_panel.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';
import 'package:sinan_note/widgets/home/note_card_widget.dart';
import 'package:sinan_note/widgets/master_details_layout.dart';

/// شاشة المحترف — Responsive
///
/// - Mobile: تعرض [CodeTab] كما هي
/// - Desktop/Tablet/Foldable: شاشة موحدة بنمط version_history —
///   SearchableHeader في الأعلى + MasterDetailsLayout أسفله
class CodeTabResponsive extends StatefulWidget {
  const CodeTabResponsive({super.key});

  @override
  State<CodeTabResponsive> createState() => _CodeTabResponsiveState();
}

class _CodeTabResponsiveState extends State<CodeTabResponsive>
    with SearchMixin {
  final ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date';
  bool _selectionMode = false;
  final Set<int> _selectedNoteIds = {};
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    initSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes
        .where((n) => n.isProfessional && !n.isArchived && !n.isTrashed)
        .toList();

    if (searchQuery.isNotEmpty) {
      final q = Note.normalize(searchQuery);
      filtered = filtered
          .where((n) =>
              n.normalizedTitle.contains(q) || n.normalizedContent.contains(q))
          .toList();
    }

    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  void _archiveSelected() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    await notesProvider.archiveNotes(ids);
    setState(() {
      _selectedNoteIds.clear();
      _selectionMode = false;
    });
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: '${ids.length} ${l10n.notesArchived}',
      actionKey: 'code_archive',
      type: NotificationType.success,
      onExecute: () {},
      onUndo: () async => await notesProvider.unarchiveNotes(ids),
      undoLabel: l10n.undo,
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
    final l10n = AppLocalizations.of(context)!;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: '${ids.length} ${l10n.notesDeleted}',
      actionKey: 'code_delete',
      type: NotificationType.info,
      onExecute: () {},
      onUndo: () async => await notesProvider.restoreNotes(ids),
      undoLabel: l10n.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mobile — الشاشة القديمة كما هي
    if (!PlatformHelper.shouldUseDesktopLayout(context)) {
      return const CodeTab();
    }

    // Desktop/Tablet/Foldable — نمط موحد
    return _buildDesktop(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final codeNotes = _filterNotes(notesProvider.notes);

        return PopScope(
          canPop: !_selectionMode && !isSearchActive,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedNoteIds.clear();
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
                // ── SearchableHeader ──
                Builder(builder: (ctx) {
                  if (_selectionMode) {
                    return SearchableHeader(
                      title: '${_selectedNoteIds.length} ${l10n.selected}',
                      isSearching: false,
                      hideSearchFrame: true,
                      maxWidth: 720,
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
                              _selectedNoteIds.length == codeNotes.length
                                  ? Icons.deselect
                                  : Icons.select_all,
                            ),
                            onPressed: () => setState(() {
                              if (_selectedNoteIds.length == codeNotes.length) {
                                _selectedNoteIds.clear();
                              } else {
                                _selectedNoteIds.clear();
                                _selectedNoteIds
                                    .addAll(codeNotes.map((n) => n.id!));
                              }
                            }),
                          ),
                          IconButton(
                            icon: Icon(Icons.archive,
                                color: _selectedNoteIds.isNotEmpty
                                    ? Colors.orange
                                    : Colors.grey),
                            onPressed: _selectedNoteIds.isNotEmpty
                                ? _archiveSelected
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: _selectedNoteIds.isNotEmpty
                                    ? Colors.red
                                    : Colors.grey),
                            onPressed: _selectedNoteIds.isNotEmpty
                                ? _deleteSelected
                                : null,
                          ),
                        ],
                      ),
                    );
                  }
                  return SearchableHeader(
                    title: l10n.professional,
                    icon: Icons.code_rounded,
                    isSearching: isSearchActive,
                    noteCount: codeNotes.length,
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
                      ],
                    ),
                  );
                }),

                // ── المحتوى: MasterDetails ──
                Expanded(
                  child: MasterDetailsLayout(
                    includeSafeArea: false,
                    masterPanel: _buildNotesList(codeNotes, l10n),
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

  Widget _buildNotesList(List<Note> codeNotes, AppLocalizations l10n) {
    if (codeNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noProfessionalNotes,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: codeNotes.length,
      itemBuilder: (context, index) {
        final note = codeNotes[index];
        final isSelected = _selectedNoteIds.contains(note.id);
        return SelectedNoteIndicator(
          note: note,
          child: NoteCardWidget(
            note: note,
            viewType: _viewType,
            closeAllSlidables: _closeAllSlidables,
            onNoteChanged: () => setState(() {}),
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
                    Provider.of<SelectedNoteProvider>(context, listen: false)
                        .selectNote(note);
                  },
            source: 'professional',
            isFiltering: false,
            selectionMode: _selectionMode,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}
