// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/note.dart';
import '../../models/note_mode.dart';
import '../../services/notes_provider.dart';
import '../../services/settings_provider.dart';

import '../../l10n/l10n_migration_helper.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../widgets/home/note_card_widget.dart';
import '../../widgets/home/add_menu_widget.dart';
import '../../screens/home_screen.dart' show ViewType;
import '../note_editor.dart';

class ReminderDashboard extends StatefulWidget {
  const ReminderDashboard({super.key});

  @override
  State<ReminderDashboard> createState() => _ReminderDashboardState();
}

class _ReminderDashboardState extends State<ReminderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAddMenu = false;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  String _searchQuery = '';
  ViewType _viewType = ViewType.listExpanded;
  String _sortBy = 'date'; // date, title

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadViewType();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadNotes();
    });
  }

  void _loadViewType() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedType = await settings.getViewType('reminder');
    if (mounted) {
      setState(() {
        if (savedType == 'grid') {
          _viewType = ViewType.grid;
        } else if (savedType == 'listCompact') {
          _viewType = ViewType.listCompact;
        } else {
          _viewType = ViewType.listExpanded;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _closeAllSlidables.dispose();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    var filtered = notes;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
            note.content.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    // Sort
    if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nHelper.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final now = DateTime.now();
        final allReminders = notesProvider.notes
            .where((n) => n.reminderDateTime != null && !n.isTrashed)
            .toList();

        final upcomingReminders = _filterNotes(allReminders
            .where((n) =>
                n.reminderDateTime!.isAfter(now) &&
                n.reminderDateTime!.difference(now).inHours <= 24)
            .toList());

        final scheduledReminders = _filterNotes(allReminders
            .where((n) =>
                n.reminderDateTime!.isAfter(now) &&
                n.reminderDateTime!.difference(now).inHours > 24)
            .toList());

        final expiredReminders = _filterNotes(allReminders
            .where((n) => n.reminderDateTime!.isBefore(now))
            .toList());

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _closeAllSlidables.value++,
              child: SlidableAutoCloseBehavior(
                child: DefaultTabController(
              length: 3,
              child: NestedScrollView(
                physics: const NeverScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    title: _searchController.text.isEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm_rounded, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  strings.reminders,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: strings.searchNotes,
                              border: InputBorder.none,
                            ),
                          ),
                    actions: [
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
                      IconButton(
                        icon: Icon(_viewType == ViewType.grid
                            ? Icons.view_list
                            : Icons.grid_view),
                        onPressed: () async {
                          setState(() {
                            _viewType = _viewType == ViewType.grid
                                ? ViewType.listExpanded
                                : ViewType.grid;
                          });
                          final settings = Provider.of<SettingsProvider>(context, listen: false);
                          await settings.setViewType('reminder', _viewType.name);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'date', child: Text(strings.sortByDate)),
                          PopupMenuItem(
                              value: 'title', child: Text(strings.sortByTitle)),
                        ],
                      ),
                    ],
                    floating: true,
                    snap: true,
                    pinned: false,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: isDark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      unselectedLabelColor:
                          isDark ? Colors.grey[400] : Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      tabs: [
                        Tab(text: strings.upcoming),
                        Tab(text: strings.scheduled),
                        Tab(text: strings.expired),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildReminderList(
                        _filterNotes(upcomingReminders), 'upcoming', strings),
                    _buildReminderList(
                        _filterNotes(scheduledReminders), 'scheduled', strings),
                    _buildReminderList(
                        _filterNotes(expiredReminders), 'expired', strings),
                  ],
                ),
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
                    builder: (context) => NoteEditorImmersive(
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
        );
      },
    );
  }

  Widget _buildReminderList(
      List<Note> reminders, String type, AppLocalizations strings) {
    if (reminders.isEmpty) {
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

    if (_viewType == ViewType.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200
              ? 4
              : MediaQuery.of(context).size.width >= 600
                  ? 3
                  : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final note = reminders[index];
          return Opacity(
            opacity: type == 'expired' ? 0.6 : 1.0,
            child: NoteCardWidget(
              note: note,
              viewType: _viewType,
              closeAllSlidables: _closeAllSlidables,
              onNoteChanged: () => setState(() {}),
              onLongPress: () {},
              source: 'reminder_$type',
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final note = reminders[index];
        return Opacity(
          opacity: type == 'expired' ? 0.6 : 1.0,
          child: NoteCardWidget(
            note: note,
            viewType: _viewType,
            closeAllSlidables: _closeAllSlidables,
            onNoteChanged: () => setState(() {}),
            onLongPress: () {},
            source: 'reminder_$type',
          ),
        );
      },
    );
  }
}
