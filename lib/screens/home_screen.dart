// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/home/add_menu_widget.dart' show AddMenuWidget, isMenuOpenNotifier;
import '../widgets/home/home_drawer_widget.dart';
import '../widgets/home/smart_header.dart';
import '../widgets/home/notes_grid_view.dart';

import '../widgets/home/dialogs/backup_options_dialog.dart';
import '../services/toast_service.dart';
import 'note_editor.dart';

enum ViewType { grid, listExpanded, listCompact }

class HomeScreen extends StatefulWidget {
  final String? sharedText;
  final Function(bool)? onDrawerChanged;

  const HomeScreen({super.key, this.sharedText, this.onDrawerChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  ViewType _viewType = ViewType.listCompact; // قيمة افتراضية سريعة
  late final ValueNotifier<String> _viewTypeNotifier;
  late final ValueNotifier<Set<int>> _selectedNoteIdsNotifier;
  bool _showAddMenu = false;
  Timer? _debounce;
  final bool _isReady = true;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _viewType = _parseViewType(settings.viewType);
    _viewTypeNotifier = ValueNotifier(_viewType.name);
    _selectedNoteIdsNotifier = ValueNotifier({});
    _loadViewType();
    
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) {
        final newState = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
        if (_isSearchActive != newState) {
          setState(() => _isSearchActive = newState);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sharedText != null) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              return NoteEditorImmersive(
                mode: NoteMode.code,
                note: Note(
                  title: l10n.importedFile,
                  content: widget.sharedText!,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  colorIndex: settings.getDefaultColorIndex('professional'),
                  noteType: NoteMode.code.name,
                ),
              );
            },
          ),
        );
      }
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
      if (savedType == 'grid') {
        loadedType = ViewType.grid;
      } else if (savedType == 'listExpanded') {
        loadedType = ViewType.listExpanded;
      } else {
        loadedType = ViewType.listCompact;
      }
      if (_viewType != loadedType) {
        _viewType = loadedType;
        _viewTypeNotifier.value = loadedType.name;
        if (mounted) setState(() {});
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  void _exitSearchMode() async {

    _isSearchActive = false;

    _searchController.clear();
    _searchFocusNode.unfocus();

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
    }
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



  void _navigateToEditor(NoteMode mode) async {
    setState(() => _showAddMenu = false);
    isMenuOpenNotifier.value = false;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    String colorMode = 'simple';
    if (mode == NoteMode.reminder) {
      colorMode = 'reminder';
    } else if (mode == NoteMode.code) {
      colorMode = 'professional';
    }
    
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
            colorIndex: settings.getDefaultColorIndex(colorMode),
            noteType: mode.name,
            isChecklist: mode == NoteMode.checklist,
            isProfessional: mode == NoteMode.code,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewTypeNotifier.dispose();
    _selectedNoteIdsNotifier.dispose();
    ToastService().cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        final canPopNow = !_showAddMenu && !_isSearchActive && selectedIds.isEmpty;

        return _HomeScreenPopScope(
          canPop: canPopNow,
          onClearSelection: () {
            _selectedNoteIdsNotifier.value = {};
          },
          onCloseMenu: () {
            setState(() => _showAddMenu = false);
            isMenuOpenNotifier.value = false;
          },
          onExitSearch: _exitSearchMode,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ),
            child: Scaffold(
              key: _scaffoldKey,
              onDrawerChanged: widget.onDrawerChanged,
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
              body: Stack(
                children: [
                  SafeArea(
                    child: CustomScrollView(
                      slivers: [
                        SmartHeader(
                          selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          viewTypeNotifier: _viewTypeNotifier,
                          onViewToggle: () async {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              int nextIndex = (_viewType.index + 1) % ViewType.values.length;
                              _viewType = ViewType.values[nextIndex];
                              _viewTypeNotifier.value = _viewType.name;
                            });
                            final settings = Provider.of<SettingsProvider>(context, listen: false);
                            await settings.setViewType('home', _viewType.name);
                          },
                          onMenuTap: () {
                            if (_isSearchActive) {
                              _exitSearchMode();
                              return;
                            }
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          onFilterTap: () {
                            FocusScope.of(context).unfocus();
                            _showFilterDialog(context);
                          },
                          isSearchActive: _isSearchActive,
                        ),
                        // Deferred rendering: Show Grid only after 300ms delay
                        if (_isReady)
                          NotesGridView(
                            viewType: _viewType,
                            selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                            searchController: _searchController,
                          )
                        else
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                  AddMenuWidget(
                    showMenu: _showAddMenu,
                    onToggle: () {
                      setState(() => _showAddMenu = !_showAddMenu);
                      isMenuOpenNotifier.value = _showAddMenu;
                    },
                    onModeSelected: _navigateToEditor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// OPTIMIZATION: Separate widget to prevent PopScope from rebuilding on every setState
class _HomeScreenPopScope extends StatefulWidget {
  final bool canPop;
  final VoidCallback onClearSelection;
  final VoidCallback onCloseMenu;
  final VoidCallback onExitSearch;
  final Widget child;

  const _HomeScreenPopScope({
    required this.canPop,
    required this.onClearSelection,
    required this.onCloseMenu,
    required this.onExitSearch,
    required this.child,
  });

  @override
  State<_HomeScreenPopScope> createState() => _HomeScreenPopScopeState();
}

class _HomeScreenPopScopeState extends State<_HomeScreenPopScope> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Execute callbacks in order of priority
        if (!widget.canPop) {
          widget.onClearSelection();
          widget.onCloseMenu();
          widget.onExitSearch();
        }
      },
      child: widget.child,
    );
  }
  
  @override
  void didUpdateWidget(_HomeScreenPopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if canPop actually changed
    if (oldWidget.canPop != widget.canPop) {
      // PopScope will automatically update
    }
  }
}
