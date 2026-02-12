// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../controllers/settings/settings_provider.dart';
import '../../providers/selected_note_provider.dart';
import '../../models/note.dart';
import '../../models/note_mode.dart';
import '../../services/unified_notification_service.dart';
import '../../widgets/responsive_layout_wrapper.dart';
import '../../widgets/master_details_layout.dart';
import '../../widgets/details_panel.dart';
import '../../widgets/home/home_drawer_widget.dart';
import '../../widgets/home/dialogs/backup_options_dialog.dart';
import '../../widgets/home/notes_grid_view.dart';
import '../../widgets/home/add_menu_widget.dart';
import '../mobile/home_screen.dart';

/// نسخة Responsive من HomeScreen تدعم نمط Master-Details
/// 
/// على الشاشات الكبيرة (>= 600px):
/// - يعرض Master-Details Layout (قائمة + محتوى)
/// 
/// على الشاشات الصغيرة (< 600px):
/// - يعرض HomeScreen التقليدي
class HomeScreenResponsive extends StatefulWidget {
  final String? sharedText;
  final Function(bool)? onDrawerChanged;

  const HomeScreenResponsive({
    super.key,
    this.sharedText,
    this.onDrawerChanged,
  });

  @override
  State<HomeScreenResponsive> createState() => _HomeScreenResponsiveState();
}

class _HomeScreenResponsiveState extends State<HomeScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<Set<int>> _selectedNoteIdsNotifier = ValueNotifier({});
  final ValueNotifier<bool> _isEditModeNotifier = ValueNotifier(false); // 🔥 وضع التعديل
  ViewType _viewType = ViewType.listCompact;
  late final ValueNotifier<String> _viewTypeNotifier;
  bool _showAddMenu = false;

  // Desktop view types (no grid)
  static const List<ViewType> _desktopViewTypes = [
    ViewType.listCompact,
    ViewType.listExpanded,
  ];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _viewType = _parseViewType(settings.viewType);
    _viewTypeNotifier = ValueNotifier(_viewType.name);
    _loadViewType();
    // مسح الاختيار عند فتح الشاشة (الانتقال من تبويب آخر)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
        context,
        listen: false,
      );
      selectedNoteProvider.clearSelection();
    });
  }

  ViewType _parseViewType(String type) {
    switch (type) {
      case 'grid':
        return ViewType.grid;
      case 'listExpanded':
        return ViewType.listExpanded;
      default:
        return ViewType.listCompact;
    }
  }

  Future<void> _loadViewType() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedType = await settings.getViewType('home');
    if (mounted) {
      ViewType loadedType;
      if (savedType == 'listExpanded') {
        loadedType = ViewType.listExpanded;
      } else {
        loadedType = ViewType.listCompact; // Default for desktop
      }
      if (_viewType != loadedType) {
        _viewType = loadedType;
        _viewTypeNotifier.value = loadedType.name;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedNoteIdsNotifier.dispose();
    _isEditModeNotifier.dispose();
    _viewTypeNotifier.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.filter_list_rounded, size: 22),
            const SizedBox(width: 8),
            Text(l10n.filter),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.noteType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.note, color: Colors.blue),
                title: Text(l10n.simpleNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.text = 'type:simple';
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.purple),
                title: Text(l10n.professionalNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.text = 'type:pro';
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.orange),
                title: Text(l10n.reminderNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.text = 'type:reminder';
                },
              ),
              ListTile(
                leading: const Icon(Icons.checklist, color: Colors.green),
                title: Text(l10n.checklists),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.text = 'type:checklist';
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.noteStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.red),
                title: Text(l10n.pinnedOnly),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.text = 'pinned:true';
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.red),
                title: Text(l10n.clearFilter),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchController.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      // Mobile Layout - الشاشة التقليدية
      mobileLayout: HomeScreen(
        sharedText: widget.sharedText,
        onDrawerChanged: widget.onDrawerChanged,
      ),
      
      // Master-Details Layout - للشاشات الكبيرة
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        final bool hasSelection = selectedIds.isNotEmpty;
        
        return Scaffold(
          drawer: HomeDrawerWidget(
            onBackupTap: () {
              final tempStrings = {
                'exportBackup': l10n.exportBackup,
                'importBackup': l10n.importBackup,
                'googleDrive': l10n.googleDrive,
                'share': l10n.share,
                'soon': 'قريباً',
              };
              BackupOptionsDialog.show(context, tempStrings);
            },
            onNotesChanged: () {},
          ),
          
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            leading: hasSelection
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _selectedNoteIdsNotifier.value = {};
                    },
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
            title: hasSelection
                ? Text('${selectedIds.length} ${l10n.selected}')
                : TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchNotes,
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
            actions: hasSelection
                ? _buildSelectionActions(context, selectedIds)
                : _buildSearchActions(context),
          ),
          
          body: MasterDetailsLayout(
            masterPanel: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    NotesGridView(
                      viewType: _viewType,
                      selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                      searchController: _searchController,
                    ),
                  ],
                ),
                AddMenuWidget(
                  showMenu: _showAddMenu,
                  onToggle: () {
                    setState(() => _showAddMenu = !_showAddMenu);
                  },
                  onModeSelected: _navigateToNewNote,
                ),
              ],
            ),
            detailsPanel: const DetailsPanel(),
          ),
        );
      },
    );
  }

  List<Widget> _buildSearchActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (_searchController.text.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _searchController.clear();
            });
          },
        ),
      ValueListenableBuilder<String>(
        valueListenable: _viewTypeNotifier,
        builder: (context, viewType, child) {
          return IconButton(
            icon: Icon(
              viewType == 'listExpanded'
                  ? Icons.view_headline
                  : Icons.view_day,
            ),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              setState(() {
                int currentIndex = _desktopViewTypes.indexOf(_viewType);
                int nextIndex = (currentIndex + 1) % _desktopViewTypes.length;
                _viewType = _desktopViewTypes[nextIndex];
                _viewTypeNotifier.value = _viewType.name;
              });
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              await settings.setViewType('home', _viewType.name);
            },
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.filter_list_rounded),
        onPressed: () {
          FocusScope.of(context).unfocus();
          _showFilterDialog(context);
        },
        tooltip: l10n.filter,
      ),
    ];
  }

  List<Widget> _buildSelectionActions(BuildContext context, Set<int> selectedIds) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    
    return [
      IconButton(
        icon: const Icon(Icons.push_pin),
        onPressed: () async {
          final ids = List<int>.from(selectedIds);
          final count = ids.length;
          final notesToRestore = <Note>[];
          
          for (final id in ids) {
            final note = notesProvider.notes.firstWhere((n) => n.id == id);
            notesToRestore.add(note);
            final updatedNote = Note(
              id: note.id,
              title: note.title,
              content: note.content,
              createdAt: note.createdAt,
              updatedAt: DateTime.now(),
              colorIndex: note.colorIndex,
              isArchived: note.isArchived,
              isTrashed: note.isTrashed,
              reminderDateTime: note.reminderDateTime,
              isLocked: note.isLocked,
              noteType: note.noteType,
              recurrenceRule: note.recurrenceRule,
              isCompleted: note.isCompleted,
              isProfessional: note.isProfessional,
              isPinned: !note.isPinned,
              isChecklist: note.isChecklist,
            );
            await notesProvider.updateNote(updatedNote);
          }
          
          _selectedNoteIdsNotifier.value = {};
          
          if (context.mounted) {
            UnifiedNotificationService().showWithUndo(
              context: context,
              message: '$count ${l10n.notesPinned}',
              actionKey: 'bulk_pin',
              type: NotificationType.success,
              onExecute: () {},
              onUndo: () async {
                for (final note in notesToRestore) {
                  await notesProvider.updateNote(note);
                }
              },
              undoLabel: l10n.undo,
            );
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.archive),
        onPressed: () async {
          final ids = List<int>.from(selectedIds);
          final count = ids.length;
          
          await notesProvider.archiveNotes(ids);
          _selectedNoteIdsNotifier.value = {};
          
          if (context.mounted) {
            UnifiedNotificationService().showWithUndo(
              context: context,
              message: '$count ${l10n.notesArchived}',
              actionKey: 'bulk_archive',
              type: NotificationType.success,
              onExecute: () {},
              onUndo: () async {
                await notesProvider.unarchiveNotes(ids);
              },
              undoLabel: l10n.undo,
            );
          }
        },
        tooltip: l10n.archive,
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final ids = List<int>.from(selectedIds);
          final count = ids.length;
          
          await notesProvider.trashNotes(ids);
          _selectedNoteIdsNotifier.value = {};
          
          if (context.mounted) {
            UnifiedNotificationService().showWithUndo(
              context: context,
              message: '$count ${l10n.notesDeleted}',
              actionKey: 'bulk_delete',
              type: NotificationType.info,
              onExecute: () {},
              onUndo: () async {
                await notesProvider.restoreNotes(ids);
              },
              undoLabel: l10n.undo,
            );
          }
        },
        tooltip: l10n.delete,
      ),
    ];
  }

  /// إنشاء ملاحظة جديدة واختيارها تلقائياً
  Future<void> _navigateToNewNote(NoteMode mode) async {
    setState(() => _showAddMenu = false);
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);

    String colorMode = 'simple';
    if (mode == NoteMode.reminder) {
      colorMode = 'reminder';
    } else if (mode == NoteMode.code) {
      colorMode = 'professional';
    } else if (mode == NoteMode.checklist) {
      colorMode = 'checklist';
    } else if (mode == NoteMode.rich) {
      colorMode = 'rich';
    }

    final newNote = Note(
      title: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: settings.getDefaultColorIndex(colorMode),
      noteType: mode.name,
      isChecklist: mode == NoteMode.checklist,
      isProfessional: mode == NoteMode.code,
    );

    final noteId = await notesProvider.addOrUpdateNote(newNote, silent: true);
    
    final savedNote = notesProvider.notes.firstWhere(
      (note) => note.id == noteId,
      orElse: () => newNote,
    );

    selectedNoteProvider.selectNote(savedNote);
  }

  
}
