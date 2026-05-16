// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/search_mixin.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/main.dart' show tabToHomeNotifier;
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/common/selected_note_indicator.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:apex_note/widgets/home/selection_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderDashboard extends StatefulWidget {
  const ReminderDashboard({super.key});

  @override
  State<ReminderDashboard> createState() => _ReminderDashboardState();
}

class _ReminderDashboardState extends State<ReminderDashboard>
    with SingleTickerProviderStateMixin, SearchMixin {
  late TabController _tabController;
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  bool _showAddMenu = false;
  bool _showPermissionBanner = false;
  bool _isCheckingPermissions = true;
  String _sortBy = 'date';
  ViewType _viewType = ViewType.listExpanded;
  final ValueNotifier<Set<int>> _selectedNoteIdsNotifier = ValueNotifier({});
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initSearch();
    _loadViewType();
    _checkPermissions();
    _selectedNoteIdsNotifier.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _closeAllSlidables.dispose();
    _selectedNoteIdsNotifier.removeListener(_onSelectionChanged);
    _selectedNoteIdsNotifier.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('reminder_permission_dismissed') ?? false;
    if (!dismissed) {
      await NotificationService().checkAllPermissions();
    }
    if (mounted) {
      setState(() {
        _showPermissionBanner = !dismissed;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _loadViewType() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedType = await settings.getViewType('reminder');
    if (!mounted) return;
    setState(() {
      _viewType = savedType == 'listCompact'
          ? ViewType.listCompact
          : ViewType.listExpanded;
    });
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = searchQuery.isEmpty
        ? notes
        : notes
            .where((n) =>
                n.normalizedTitle.contains(Note.normalize(searchQuery)) ||
                n.normalizedContent.contains(Note.normalize(searchQuery)))
            .toList();
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
                    child: DefaultTabController(
                      length: 3,
                      child: CustomScrollView(
                        slivers: [
                          ValueListenableBuilder<Set<int>>(
                            valueListenable: _selectedNoteIdsNotifier,
                            builder: (context, selectedIds, _) {
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              final inSelection = selectedIds.isNotEmpty;
                              if (inSelection) {
                                return SliverAppBar(
                                  pinned: true,
                                  automaticallyImplyLeading: false,
                                  titleSpacing: 0,
                                  title: SelectionActionBar(
                                    key: const ValueKey('selection'),
                                    selectedIdsNotifier:
                                        _selectedNoteIdsNotifier,
                                    isDark: isDark,
                                    allPinned: false,
                                    onClear: () =>
                                        _selectedNoteIdsNotifier.value = {},
                                    onPin: () async {
                                      final provider =
                                          Provider.of<NotesProvider>(context,
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
                                      final provider =
                                          Provider.of<NotesProvider>(context,
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
                                      final provider =
                                          Provider.of<NotesProvider>(context,
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
                                                Provider.of<NotesProvider>(
                                                    context,
                                                    listen: false);
                                            final note = provider.notes
                                                .firstWhere((n) =>
                                                    n.id == selectedIds.first);
                                            _selectedNoteIdsNotifier.value = {};
                                            final content =
                                                NoteCardUtils.fixNoteContent(
                                                    note.content,
                                                    maxChars:
                                                        note.content.length);
                                            CustomShareSheet.show(context,
                                                '${note.title}\n\n$content',
                                                subject: note.title,
                                                note: note);
                                          }
                                        : null,
                                  ),
                                );
                              }
                              return SliverAppBar(
                                pinned: true,
                                automaticallyImplyLeading: false,
                                toolbarHeight: 0,
                                bottom: PreferredSize(
                                  preferredSize: const Size.fromHeight(108),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SearchableHeader(
                                        title: strings.reminders,
                                        icon: Icons.alarm_rounded,
                                        isSearching: _isSearchMode,
                                        searchController: searchController,
                                        includeSafeArea: false,
                                        onSearchChange: (q) => setState(() {}),
                                        onToggleSearch: () {
                                          if (_isSearchMode) {
                                            setState(() {
                                              _isSearchMode = false;
                                              exitSearch();
                                            });
                                          } else {
                                            setState(
                                                () => _isSearchMode = true);
                                          }
                                        },
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _viewType ==
                                                        ViewType.listExpanded
                                                    ? Icons.view_headline
                                                    : Icons.view_day,
                                              ),
                                              onPressed: () async {
                                                setState(() {
                                                  _viewType = _viewType ==
                                                          ViewType.listExpanded
                                                      ? ViewType.listCompact
                                                      : ViewType.listExpanded;
                                                });
                                                await Provider.of<
                                                            SettingsProvider>(
                                                        context,
                                                        listen: false)
                                                    .setViewType('reminder',
                                                        _viewType.name);
                                              },
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.sort),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              onSelected: (v) =>
                                                  setState(() => _sortBy = v),
                                              itemBuilder: (_) => [
                                                _sortItem(
                                                    context,
                                                    'date',
                                                    Icons.access_time,
                                                    strings.sortByDate),
                                                _sortItem(
                                                    context,
                                                    'title',
                                                    Icons.sort_by_alpha,
                                                    strings.sortByTitle),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      TabBar(
                                        controller: _tabController,
                                        indicatorColor:
                                            Theme.of(context).primaryColor,
                                        labelColor: isDark
                                            ? Colors.white
                                            : Theme.of(context).primaryColor,
                                        unselectedLabelColor: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                        unselectedLabelStyle: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 14),
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        tabs: [
                                          Tab(text: strings.upcoming),
                                          Tab(text: strings.scheduled),
                                          Tab(text: strings.expired),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SliverFillRemaining(
                            child: Column(
                              children: [
                                if (_showPermissionBanner &&
                                    !_isCheckingPermissions)
                                  _BatteryBanner(
                                    onDismiss: () => setState(
                                        () => _showPermissionBanner = false),
                                  ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      _ReminderTabView(
                                        notes: upcoming,
                                        type: 'upcoming',
                                        viewType: _viewType,
                                        closeAllSlidables: _closeAllSlidables,
                                        selectedNoteIdsNotifier:
                                            _selectedNoteIdsNotifier,
                                        onChanged: () => setState(() {}),
                                        strings: strings,
                                      ),
                                      _ReminderTabView(
                                        notes: scheduled,
                                        type: 'scheduled',
                                        viewType: _viewType,
                                        closeAllSlidables: _closeAllSlidables,
                                        selectedNoteIdsNotifier:
                                            _selectedNoteIdsNotifier,
                                        onChanged: () => setState(() {}),
                                        strings: strings,
                                      ),
                                      _ReminderTabView(
                                        notes: expired,
                                        type: 'expired',
                                        viewType: _viewType,
                                        closeAllSlidables: _closeAllSlidables,
                                        selectedNoteIdsNotifier:
                                            _selectedNoteIdsNotifier,
                                        onChanged: () => setState(() {}),
                                        strings: strings,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AddMenuWidget(
                  showMenu: _showAddMenu,
                  onToggle: () => setState(() => _showAddMenu = !_showAddMenu),
                  onModeSelected: (mode) async {
                    setState(() => _showAddMenu = false);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteEditorImmersive(
                          mode: mode,
                          note: Note(
                            title: '',
                            content: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            colorIndex: 0,
                            noteType: mode.name,
                            isChecklist: mode == NoteMode.checklist,
                            isProfessional: mode == NoteMode.code,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _sortItem(
      BuildContext context, String value, IconData icon, String label) {
    final isSelected = _sortBy == value;
    final color = Theme.of(context).colorScheme.primary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? color : null),
          const SizedBox(width: 12),
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 20, color: color)
          ],
        ],
      ),
    );
  }
}

// ── Battery Banner ────────────────────────────────────────────────────────────

class _BatteryBanner extends StatefulWidget {
  final VoidCallback onDismiss;
  const _BatteryBanner({required this.onDismiss});

  @override
  State<_BatteryBanner> createState() => _BatteryBannerState();
}

class _BatteryBannerState extends State<_BatteryBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: _expanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() => const Row(
        children: [
          Icon(Icons.battery_alert, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
              child: Text('Battery Optimization',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Icon(Icons.expand_more, size: 20),
        ],
      );

  Widget _buildExpanded() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.battery_alert, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Battery Optimization',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('reminder_permission_dismissed', true);
                  widget.onDismiss();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
              'Disable battery optimization to ensure reminders work reliably in the background',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
      );
}

// ── Reminder Tab View ─────────────────────────────────────────────────────────

class _ReminderTabView extends StatelessWidget {
  final List<Note> notes;
  final String type;
  final ViewType viewType;
  final ValueNotifier<int> closeAllSlidables;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final VoidCallback onChanged;
  final AppLocalizations strings;

  const _ReminderTabView({
    required this.notes,
    required this.type,
    required this.viewType,
    required this.closeAllSlidables,
    required this.selectedNoteIdsNotifier,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
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
                  ? strings.noUpcomingReminders
                  : type == 'scheduled'
                      ? strings.noScheduledReminders
                      : strings.noExpiredReminders,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 100),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildCard(context, notes[index]),
    );
  }

  Widget _buildCard(BuildContext context, Note note) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        final isSelected = selectedIds.contains(note.id);
        final selectionMode = selectedIds.isNotEmpty;
        return Consumer<SelectedNoteProvider>(
          builder: (context, sel, _) => SelectedNoteIndicator(
            note: note,
            child: NoteCardWidget(
              note: note,
              viewType: viewType,
              closeAllSlidables: closeAllSlidables,
              onNoteChanged: () {
                onChanged();
              },
              isSelected: isSelected,
              selectionMode: selectionMode,
              source: 'reminder_$type',
              isFiltering: false,
              isCurrentlyOpen: sel.selectedNote?.id == note.id,
              onLongPress: () {
                if (selectedNoteIdsNotifier.value.isNotEmpty) return;
                selectedNoteIdsNotifier.value = {note.id!};
              },
              onTap: () {
                final current = selectedNoteIdsNotifier.value;
                if (current.isNotEmpty) {
                  final newSet = Set<int>.from(current);
                  if (newSet.contains(note.id)) {
                    newSet.remove(note.id);
                  } else {
                    newSet.add(note.id!);
                  }
                  selectedNoteIdsNotifier.value = Set<int>.of(newSet);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
