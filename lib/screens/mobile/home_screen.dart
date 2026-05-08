// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
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
import 'package:apex_note/widgets/home/dialogs/filter_sheet.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_locator_button.dart';
import 'package:apex_note/widgets/home/notes_grid_view.dart';
import 'package:apex_note/widgets/home/smart_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _scrollController.addListener(_onScrollChanged);

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
    FilterSheet.show(context, activeFilterNotifier: _activeFilterNotifier);
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
    if (mounted) {
      await Provider.of<NotesProvider>(context, listen: false)
          .refreshAllNotes();
    }
  }

  final ValueNotifier<bool> _isPullingNotifier = ValueNotifier(false);
  final ValueNotifier<double> _pullDistanceNotifier = ValueNotifier(0.0);
  static const double _pullThreshold = 80.0;
  bool _pullTriggered =
      false; // Flag: pull reached threshold, waiting for release
  final ValueNotifier<bool> _isRefreshingNotifier = ValueNotifier(false);

  Future<void> _onRefresh() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final mode = settings.pullToRefreshMode;

    // Disabled → do nothing
    if (mode == 'disabled') return;

    _isRefreshingNotifier.value = true;
    final minDuration = Future.delayed(const Duration(milliseconds: 1500));

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final categoriesProvider =
        Provider.of<CategoriesProvider>(context, listen: false);

    try {
      if (mode == 'full') {
        final pullToSyncEnabled = (await SharedPreferences.getInstance())
                .getBool('google_drive_pull_to_refresh') ??
            true;
        if (GoogleDriveService.isSignedIn &&
            GoogleDriveService.autoSyncEnabled.value &&
            pullToSyncEnabled) {
          await GoogleDriveService.smartSyncOnStartup();
          while (GoogleDriveService.isSyncing.value) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }

        await notesProvider.refreshAllNotes(force: true);
        await categoriesProvider.refreshCategories();

        _searchController.clear();
        _activeFilterNotifier.value = null;
        if (mounted) setState(() => _isSearchActive = false);
      } else {
        await notesProvider.refreshAllNotes(force: true);
      }
    } finally {
      // Wait minimum 1.5s so the user sees the refreshing indicator
      await minDuration;
      // ✅ Clean reset — ensure all pull state is zeroed for next pull
      _isRefreshingNotifier.value = false;
      _pullTriggered = false;
      _pullDistanceNotifier.value = 0;
      _isPullingNotifier.value = false;
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    // Don't show pull indicator when pull-to-refresh is disabled
    final mode =
        Provider.of<SettingsProvider>(context, listen: false).pullToRefreshMode;
    if (mode == 'disabled') return;

    final offset = _scrollController.offset;
    if (offset < 0) {
      // If pull already triggered, stop updating distance (refreshing bar takes over)
      if (_pullTriggered) return;

      final distance = offset.abs();
      _pullDistanceNotifier.value = distance;
      if (distance >= _pullThreshold) {
        if (!_isPullingNotifier.value) {
          _isPullingNotifier.value = true;
          _pullTriggered = true;
          // Switch immediately to refreshing bar (no bounce-back visible)
          _pullDistanceNotifier.value = 0;
          _isRefreshingNotifier.value = true;
        }
      } else {
        if (_isPullingNotifier.value) _isPullingNotifier.value = false;
      }
    } else {
      if (!_pullTriggered) {
        if (_pullDistanceNotifier.value != 0) _pullDistanceNotifier.value = 0;
      }
      if (_isPullingNotifier.value) _isPullingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _filteredNotesNotifier.dispose();
    _totalCountNotifier.dispose();
    _visibleCountNotifier.dispose();
    _viewTypeNotifier.dispose();
    _selectedNoteIdsNotifier.dispose();
    _activeFilterNotifier.dispose();
    _isPullingNotifier.dispose();
    _pullDistanceNotifier.dispose();
    _isRefreshingNotifier.dispose();
    UnifiedNotificationService().commitAll();
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
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor:
                    AppTheme.secondaryBackground(Theme.of(context).colorScheme),
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.dark
                        ? Brightness.light
                        : Brightness.dark,
              ),
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is UserScrollNotification &&
                            notification.direction == ScrollDirection.idle) {
                          _handleScrollEnd();
                        }
                        if (notification is ScrollEndNotification &&
                            _pullTriggered) {
                          _pullTriggered = false;
                          _isPullingNotifier.value = false;
                          _pullDistanceNotifier.value = 0;
                          _onRefresh();
                        }
                        return false;
                      },
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
                            scrollController: _scrollController,
                          ),
                          DateBarHeader(
                            scrollController: _scrollController,
                            filteredNotesNotifier: _filteredNotesNotifier,
                            activeFilterNotifier: _activeFilterNotifier,
                            isPullingNotifier: _isPullingNotifier,
                            pullDistanceNotifier: _pullDistanceNotifier,
                            isRefreshingNotifier: _isRefreshingNotifier,
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
          ),
        );
      },
    );
  }

  static const _headerHeight = 68.0;
  bool _isScrollSnapping = false;

  void _handleScrollEnd() {
    if (_isSearchActive) return;
    if (_isScrollSnapping) return;
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if (offset > 0 && offset < _headerHeight) {
      _isScrollSnapping = true;
      final snapTo = offset < _headerHeight / 2 ? 0.0 : _headerHeight;
      _scrollController
          .animateTo(
            snapTo,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          )
          .then((_) => _isScrollSnapping = false);
    }
  }
}
