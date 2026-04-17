// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/mobile/home_screen_widgets.dart';
import 'package:apex_note/screens/mobile/home_scrollbar.dart';
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart'
    show isMenuOpenNotifier;
import 'package:apex_note/widgets/home/dialogs/backup_options_dialog.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_locator_button.dart';
import 'package:apex_note/widgets/home/notes_grid_view.dart';
import 'package:apex_note/widgets/home/smart_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

export 'package:apex_note/screens/mobile/home_screen_widgets.dart';

enum ViewType { grid, listExpanded, listCompact }

class HomeScreen extends StatefulWidget {
  final String? sharedText;
  final Function(bool)? onDrawerChanged;
  final bool showAddMenu;
  final VoidCallback onToggleMenu;
  final void Function(void Function(NoteMode))? onRegisterModeHandler;

  const HomeScreen({
    super.key,
    this.sharedText,
    this.onDrawerChanged,
    this.showAddMenu = false,
    required this.onToggleMenu,
    this.onRegisterModeHandler,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<Note>> _filteredNotesNotifier = ValueNotifier([]);
  final ValueNotifier<int> _totalCountNotifier = ValueNotifier(0);
  final ValueNotifier<int> _visibleCountNotifier = ValueNotifier(0);
  late final ValueNotifier<String> _viewTypeNotifier;
  late final ValueNotifier<Set<int>> _selectedNoteIdsNotifier;
  bool _isSearchActive = false;
  ViewType _viewType = ViewType.listCompact;
  Timer? _debounce;
  final ValueNotifier<String?> _activeFilterNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _viewType = _parseViewType(settings.viewType);
    _viewTypeNotifier = ValueNotifier(_viewType.name);
    _selectedNoteIdsNotifier = ValueNotifier({});
    _loadViewType();
    widget.onRegisterModeHandler?.call(_navigateToEditor);

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) {
        final newState =
            _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
        if (_isSearchActive != newState) {
          setState(() => _isSearchActive = newState);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sharedText != null) {
        final l10n = AppLocalizations.of(context)!;
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteEditorImmersive(
              mode: NoteMode.code,
              note: Note(
                title: l10n.importedFile,
                content: widget.sharedText!,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                colorIndex: settings.getDefaultColorIndex('professional'),
                noteType: NoteMode.code.name,
              ),
            ),
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
    if (!mounted) return;
    final loaded = _parseViewType(savedType);
    if (_viewType != loaded) {
      _viewType = loaded;
      _viewTypeNotifier.value = loaded.name;
      setState(() {});
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {});
  }

  void _exitSearchMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _isSearchActive = false);
  }

  void _showFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(l10n.filter,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(l10n.noteType,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                    ListTile(
                        leading: const Icon(Icons.note, color: Colors.blue),
                        title: Text(l10n.simpleNotes),
                        onTap: () {
                          Navigator.pop(ctx);
                          _activeFilterNotifier.value = 'type:simple';
                        }),
                    ListTile(
                        leading:
                            const Icon(Icons.checklist, color: Colors.green),
                        title: Text(l10n.checklists),
                        onTap: () {
                          Navigator.pop(ctx);
                          _activeFilterNotifier.value = 'type:checklist';
                        }),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(l10n.noteStatus,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                    ListTile(
                        leading: const Icon(Icons.push_pin, color: Colors.red),
                        title: Text(l10n.pinnedOnly),
                        onTap: () {
                          Navigator.pop(ctx);
                          _activeFilterNotifier.value = 'pinned:true';
                        }),
                    const Divider(),
                    ListTile(
                        leading: const Icon(Icons.clear_all, color: Colors.red),
                        title: Text(l10n.clearFilter),
                        onTap: () {
                          Navigator.pop(ctx);
                          _activeFilterNotifier.value = null;
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditor(NoteMode mode) async {
    if (widget.showAddMenu) widget.onToggleMenu();
    isMenuOpenNotifier.value = false;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final categories = Provider.of<CategoriesProvider>(context, listen: false);
    final selectedCatId = categories.selectedCategoryId;
    final colorMode = switch (mode) {
      NoteMode.reminder => 'reminder',
      NoteMode.code => 'professional',
      NoteMode.checklist => 'checklist',
      NoteMode.rich => 'rich',
      _ => 'simple',
    };
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
            colorIndex: settings.getDefaultColorIndex(colorMode),
            noteType: mode.name,
            isChecklist: mode == NoteMode.checklist,
            isProfessional: mode == NoteMode.code,
            categoryIds: selectedCatId != null ? [selectedCatId] : [],
          ),
        ),
      ),
    );
  }

  DateTime? _lastSyncTime;
  static const _syncCooldown = Duration(seconds: 45);

  Future<void> _onRefresh() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final now = DateTime.now();

    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!) < _syncCooldown) {
      await notesProvider.refreshAllNotes();
      return;
    }

    _lastSyncTime = now;
    if (GoogleDriveService.isSignedIn) {
      await GoogleDriveService.smartSyncOnStartup();
      // انتظر حتى تنتهي المزامنة كاملاً قبل تحديث الواجهة
      while (GoogleDriveService.isSyncing.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    await notesProvider.refreshAllNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _filteredNotesNotifier.dispose();
    _totalCountNotifier.dispose();
    _visibleCountNotifier.dispose();
    _viewTypeNotifier.dispose();
    _selectedNoteIdsNotifier.dispose();
    _activeFilterNotifier.dispose();
    UnifiedNotificationService().cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        final canPop =
            !widget.showAddMenu && !_isSearchActive && selectedIds.isEmpty;

        return HomeScreenPopScope(
          canPop: canPop,
          showAddMenu: widget.showAddMenu,
          isSearchActive: _isSearchActive,
          onClearSelection: () => _selectedNoteIdsNotifier.value = {},
          onCloseMenu: () {
            if (widget.showAddMenu) widget.onToggleMenu();
          },
          onExitSearch: _exitSearchMode,
          child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            onDrawerChanged: widget.onDrawerChanged,
            drawer: HomeDrawerWidget(
              onBackupTap: () => BackupOptionsDialog.show(context, {
                'exportBackup': l10n.exportBackup,
                'importBackup': l10n.importBackup,
                'googleDrive': l10n.googleDrive,
                'share': l10n.share,
                'soon': 'قريباً',
              }),
              onNotesChanged: () {},
            ),
            body: Stack(
              children: [
                SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    displacement: 60,
                    edgeOffset: 68,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    strokeWidth: 2.5,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: CustomScrollView(
                        controller: _scrollController,
                        cacheExtent: 1500,
                        physics: const BouncingScrollPhysics(
                          decelerationRate: ScrollDecelerationRate.fast,
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SmartHeader(
                            selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            viewTypeNotifier: _viewTypeNotifier,
                            onViewToggle: () async {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _viewType = ViewType.values[
                                    (_viewType.index + 1) %
                                        ViewType.values.length];
                                _viewTypeNotifier.value = _viewType.name;
                              });
                              await Provider.of<SettingsProvider>(context,
                                      listen: false)
                                  .setViewType('home', _viewType.name);
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
                          DateBarHeader(
                            scrollController: _scrollController,
                            filteredNotesNotifier: _filteredNotesNotifier,
                            activeFilterNotifier: _activeFilterNotifier,
                          ),
                          NotesGridView(
                            viewTypeNotifier: _viewTypeNotifier,
                            selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                            searchController: _searchController,
                            scrollController: _scrollController,
                            filteredNotesNotifier: _filteredNotesNotifier,
                            totalCountNotifier: _totalCountNotifier,
                            visibleCountNotifier: _visibleCountNotifier,
                            activeFilterNotifier: _activeFilterNotifier,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: _viewTypeNotifier,
                  builder: (context, _) => HomeScrollbar(
                    scrollController: _scrollController,
                    notesNotifier: _filteredNotesNotifier,
                    interactive: _viewTypeNotifier.value == 'listCompact',
                    totalCountNotifier: _totalCountNotifier,
                    viewTypeNotifier: _viewTypeNotifier,
                  ),
                ),
                NoteLocatorButton(scrollController: _scrollController),
              ],
            ),
          ),
        );
      },
    );
  }
}
