// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../controllers/notes/notes_provider.dart';
import '../../../controllers/settings/settings_provider.dart';
import '../../../services/notification_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../widgets/home/note_card_widget.dart';
import '../../../widgets/home/add_menu_widget.dart';
import '../../mobile/home_screen.dart' show ViewType;
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
  bool _showPermissionBanner = false;
  bool _isCheckingPermissions = true;
  bool _bannerExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadViewType();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('reminder_permission_dismissed') ?? false;
    
    if (!dismissed) {
      await NotificationService().checkAllPermissions();
      // Always show banner to remind about battery optimization
      if (mounted) {
        setState(() {
          _showPermissionBanner = true; // Always show for battery tip
          _isCheckingPermissions = false;
        });
      }
    } else {
      setState(() => _isCheckingPermissions = false);
    }
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
    final strings = AppLocalizations.of(context)!;
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'date',
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: _sortBy == 'date' ? Theme.of(context).colorScheme.primary : null),
                                const SizedBox(width: 12),
                                Text(strings.sortByDate),
                                if (_sortBy == 'date') ...[
                                  const Spacer(),
                                  Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'title',
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 20, color: _sortBy == 'title' ? Theme.of(context).colorScheme.primary : null),
                                const SizedBox(width: 12),
                                Text(strings.sortByTitle),
                                if (_sortBy == 'title') ...[
                                  const Spacer(),
                                  Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary),
                                ],
                              ],
                            ),
                          ),
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
                body: Column(
                  children: [
                    if (_showPermissionBanner && !_isCheckingPermissions)
                      _buildPermissionBanner(strings),
                    Expanded(
                      child: TabBarView(
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

  Widget _buildPermissionBanner(AppLocalizations strings) {
    return GestureDetector(
      onTap: () => setState(() => _bannerExpanded = !_bannerExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: _bannerExpanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_alert, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Battery Optimization',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('reminder_permission_dismissed', true);
                          setState(() => _showPermissionBanner = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Disable battery optimization to ensure reminders work reliably in the background',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                children: [
                  Icon(Icons.battery_alert, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Battery Optimization',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 20),
                ],
              ),
      ),
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
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
