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
import 'package:sinan_note/screens/shared/tabs/reminder_dashboard.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/searchable_header.dart';
import 'package:sinan_note/widgets/common/selected_note_indicator.dart';
import 'package:sinan_note/widgets/details_panel.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';
import 'package:sinan_note/widgets/home/note_card_widget.dart';
import 'package:sinan_note/widgets/master_details_layout.dart';

/// شاشة التذكيرات — Responsive
///
/// - Mobile: تعرض [ReminderDashboard] كما هي
/// - Desktop/Tablet/Foldable: شاشة موحدة —
///   SearchableHeader + TabBar في الأعلى + MasterDetailsLayout أسفلهم
class ReminderDashboardResponsive extends StatefulWidget {
  const ReminderDashboardResponsive({super.key});

  @override
  State<ReminderDashboardResponsive> createState() =>
      _ReminderDashboardResponsiveState();
}

class _ReminderDashboardResponsiveState
    extends State<ReminderDashboardResponsive>
    with SingleTickerProviderStateMixin, SearchMixin {
  late TabController _tabController;
  final ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date';
  bool _selectionMode = false;
  final Set<int> _selectedNoteIds = {};
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    _closeAllSlidables.dispose();
    UnifiedNotificationService().commitAll();
    super.dispose();
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
      actionKey: 'reminder_archive',
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
      actionKey: 'reminder_delete',
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
      return const ReminderDashboard();
    }

    // Desktop/Tablet/Foldable — نمط موحد
    return _buildDesktop(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final now = DateTime.now();
        final all = notesProvider.notes
            .where((n) => n.reminderDateTime != null && !n.isTrashed)
            .toList();

        final upcoming = _filterNotes(all
            .where((n) =>
                n.reminderDateTime!.isAfter(now) &&
                n.reminderDateTime!.difference(now).inHours <= 24)
            .toList());
        final scheduled = _filterNotes(all
            .where((n) =>
                n.reminderDateTime!.isAfter(now) &&
                n.reminderDateTime!.difference(now).inHours > 24)
            .toList());
        final expired = _filterNotes(
            all.where((n) => n.reminderDateTime!.isBefore(now)).toList());

        // العدد الإجمالي لكل التذكيرات
        final totalCount = upcoming.length + scheduled.length + expired.length;

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
                              _selectedNoteIds.length == totalCount
                                  ? Icons.deselect
                                  : Icons.select_all,
                            ),
                            onPressed: () => setState(() {
                              if (_selectedNoteIds.length == totalCount) {
                                _selectedNoteIds.clear();
                              } else {
                                _selectedNoteIds.clear();
                                _selectedNoteIds.addAll([
                                  ...upcoming,
                                  ...scheduled,
                                  ...expired
                                ].map((n) => n.id!));
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
                    title: l10n.reminders,
                    icon: Icons.alarm_rounded,
                    isSearching: isSearchActive,
                    noteCount: totalCount,
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

                // ── TabBar ──
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: isDark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      unselectedLabelColor:
                          isDark ? Colors.grey[400] : Colors.grey[600],
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 14),
                      tabs: [
                        Tab(text: l10n.upcoming),
                        Tab(text: l10n.scheduled),
                        Tab(text: l10n.expired),
                      ],
                    ),
                  ),
                ),

                // ── المحتوى: MasterDetails مع TabBarView ──
                Expanded(
                  child: MasterDetailsLayout(
                    includeSafeArea: false,
                    masterPanel: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNotesList(upcoming, l10n, 'upcoming'),
                        _buildNotesList(scheduled, l10n, 'scheduled'),
                        _buildNotesList(expired, l10n, 'expired'),
                      ],
                    ),
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

  Widget _buildNotesList(List<Note> notes, AppLocalizations l10n, String type) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.alarm_add
                  : type == 'scheduled'
                      ? Icons.event_repeat
                      : Icons.alarm_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? l10n.noUpcomingReminders
                  : type == 'scheduled'
                      ? l10n.noScheduledReminders
                      : l10n.noExpiredReminders,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
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
            source: 'reminder_$type',
            isFiltering: false,
            selectionMode: _selectionMode,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}
