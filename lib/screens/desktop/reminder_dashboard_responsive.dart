// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/responsive_layout_wrapper.dart';
import '../../widgets/master_details_layout.dart';
import '../../widgets/details_panel.dart';
import '../shared/tabs/reminder_dashboard.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../providers/selected_note_provider.dart';
import '../../widgets/note_list_tile.dart';
import '../../widgets/home/add_menu_widget.dart';
import '../../models/note_mode.dart';
import '../../models/note.dart';
import '../shared/note_editor.dart';
import '../../services/notification_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

class ReminderDashboardResponsive extends StatelessWidget {
  const ReminderDashboardResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayoutWrapper(
      mobileLayout: ReminderDashboard(),
      masterDetailsLayout: _MasterDetailsReminders(),
    );
  }
}

class _MasterDetailsReminders extends StatefulWidget {
  const _MasterDetailsReminders();

  @override
  State<_MasterDetailsReminders> createState() => _MasterDetailsRemindersState();
}

class _MasterDetailsRemindersState extends State<_MasterDetailsReminders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPermissionBanner = false;
  bool _isCheckingPermissions = true;
  bool _bannerExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('reminder_permission_dismissed') ?? false;
    
    if (!dismissed) {
      await NotificationService().checkAllPermissions();
      if (mounted) {
        setState(() {
          _showPermissionBanner = true;
          _isCheckingPermissions = false;
        });
      }
    } else {
      setState(() => _isCheckingPermissions = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterDetailsLayout(
      masterPanel: _buildMasterPanel(context),
      detailsPanel: const DetailsPanel(),
    );
  }

  Widget _buildMasterPanel(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_rounded, size: 22),
            const SizedBox(width: 8),
            Text(strings.reminders),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: isDark ? Colors.white : Theme.of(context).primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            Tab(text: strings.upcoming),
            Tab(text: strings.scheduled),
            Tab(text: strings.expired),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showPermissionBanner && !_isCheckingPermissions)
            _buildPermissionBanner(strings),
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, _) {
                final now = DateTime.now();
                final allReminders = notesProvider.notes
                    .where((n) => n.reminderDateTime != null && !n.isTrashed)
                    .toList();

                final upcomingReminders = allReminders
                    .where((n) =>
                        n.reminderDateTime!.isAfter(now) &&
                        n.reminderDateTime!.difference(now).inHours <= 24)
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                final scheduledReminders = allReminders
                    .where((n) =>
                        n.reminderDateTime!.isAfter(now) &&
                        n.reminderDateTime!.difference(now).inHours > 24)
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                final expiredReminders = allReminders
                    .where((n) => n.reminderDateTime!.isBefore(now))
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                return Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReminderList(upcomingReminders, 'upcoming', strings),
                        _buildReminderList(scheduledReminders, 'scheduled', strings),
                        _buildReminderList(expiredReminders, 'expired', strings),
                      ],
                    ),
                    _buildAddMenu(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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

  Widget _buildReminderList(List<Note> reminders, String type, AppLocalizations strings) {
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final note = reminders[index];
        return Consumer<SelectedNoteProvider>(
          builder: (context, selectedNoteProvider, _) {
            final isSelected = selectedNoteProvider.isNoteSelected(note.id);
            return Opacity(
              opacity: type == 'expired' ? 0.6 : 1.0,
              child: NoteListTile(
                note: note,
                isSelected: isSelected,
                onTap: () => selectedNoteProvider.selectNote(note),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool showMenu = false;
        
        return AddMenuWidget(
          showMenu: showMenu,
          onToggle: () => setState(() => showMenu = !showMenu),
          onModeSelected: (mode) async {
            setState(() => showMenu = false);
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
        );
      },
    );
  }
}
