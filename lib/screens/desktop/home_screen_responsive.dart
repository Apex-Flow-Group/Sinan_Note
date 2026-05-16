// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/shortcuts/app_shortcuts.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart';
import 'package:apex_note/widgets/desktop/desktop_menu_bar.dart';
import 'package:apex_note/widgets/desktop/desktop_selection_actions.dart';
import 'package:apex_note/widgets/details_panel.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/home/dialogs/backup_options_dialog.dart';
import 'package:apex_note/widgets/home/dialogs/filter_sheet.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_locator_button.dart';
import 'package:apex_note/widgets/home/notes_grid_view.dart';
import 'package:apex_note/widgets/master_details_layout.dart';
import 'package:apex_note/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final bool showAddMenu;
  final VoidCallback onToggleMenu;
  final void Function(void Function(NoteMode))? onRegisterModeHandler;

  const HomeScreenResponsive({
    super.key,
    this.sharedText,
    this.onDrawerChanged,
    this.showAddMenu = false,
    required this.onToggleMenu,
    this.onRegisterModeHandler,
  });

  @override
  State<HomeScreenResponsive> createState() => _HomeScreenResponsiveState();
}

class _HomeScreenResponsiveState extends State<HomeScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<Set<int>> _selectedNoteIdsNotifier = ValueNotifier({});
  ViewType _viewType = ViewType.listCompact;
  late final ValueNotifier<String> _viewTypeNotifier;
  bool _showAddMenu = false;
  final ScrollController _notesScrollController = ScrollController();
  final ValueNotifier<String?> _activeFilterNotifier = ValueNotifier(null);

  // Desktop view types (no grid)
  static const List<ViewType> _desktopViewTypes = [
    ViewType.listCompact,
    ViewType.listExpanded,
  ];

  // ✅ Cache master panel to prevent rebuilds
  Widget? _cachedDetailsPanel;

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

    // ✅ Build cached panels once
    _buildCachedPanels();
  }

  void _buildCachedPanels() {
    _cachedDetailsPanel = const DetailsPanel();
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
    _searchFocusNode.dispose();
    _selectedNoteIdsNotifier.dispose();
    _viewTypeNotifier.dispose();
    _notesScrollController.dispose();
    _activeFilterNotifier.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    FilterSheet.show(context, activeFilterNotifier: _activeFilterNotifier);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      // Mobile Layout - الشاشة التقليدية
      mobileLayout: HomeScreen(
        sharedText: widget.sharedText,
        onDrawerChanged: widget.onDrawerChanged,
        showAddMenu: widget.showAddMenu,
        onToggleMenu: widget.onToggleMenu,
        onRegisterModeHandler: widget.onRegisterModeHandler,
      ),

      // Master-Details Layout - للشاشات الكبيرة
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        AppShortcuts.newNote: NewNoteIntent(),
        AppShortcuts.search: SearchIntent(),
        AppShortcuts.codeNote: CodeNoteIntent(),
        AppShortcuts.checklist: ChecklistIntent(),
        AppShortcuts.reminder: ReminderIntent(),
        AppShortcuts.refresh: RefreshIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewNoteIntent: CallbackAction<NewNoteIntent>(
            onInvoke: (_) => _navigateToNewNote(NoteMode.simple),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              FocusScope.of(context).requestFocus(FocusNode());
              return null;
            },
          ),
          CodeNoteIntent: CallbackAction<CodeNoteIntent>(
            onInvoke: (_) => _navigateToNewNote(NoteMode.code),
          ),
          ChecklistIntent: CallbackAction<ChecklistIntent>(
            onInvoke: (_) => _navigateToNewNote(NoteMode.checklist),
          ),
          ReminderIntent: CallbackAction<ReminderIntent>(
            onInvoke: (_) => _navigateToNewNote(NoteMode.reminder),
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) {
              Provider.of<NotesProvider>(context, listen: false)
                  .loadNotes(force: true);
              return null;
            },
          ),
        },
        child: _buildMasterDetailsScaffold(context, l10n),
      ),
    );
  }

  Widget _buildMasterDetailsScaffold(
      BuildContext context, AppLocalizations l10n) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        final bool hasSelection = selectedIds.isNotEmpty;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: HomeDrawerWidget(
            onBackupTap: () {
              final tempStrings = {
                'exportBackup': l10n.exportBackup,
                'importBackup': l10n.importBackup,
                'googleDrive': l10n.googleDrive,
                'share': l10n.share,
                'soon': l10n.soon,
              };
              BackupOptionsDialog.show(context, tempStrings);
            },
            onNotesChanged: () {},
          ),
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                : Consumer<CategoriesProvider>(
                    builder: (context, cats, _) {
                      final selectedId = cats.selectedCategoryId;
                      if (selectedId == null) {
                        return _SearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hint: l10n.searchNotes,
                        );
                      }
                      final catName = selectedId == kProCategoryId
                          ? l10n.professional
                          : (cats.categories
                                  .where((c) => c.id == selectedId)
                                  .firstOrNull
                                  ?.name ??
                              '');
                      return Row(
                        children: [
                          Expanded(
                            child: _SearchField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              hint: l10n.searchNotes,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.label_rounded, size: 16),
                            label: Text(catName,
                                style: const TextStyle(fontSize: 13)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => cats.selectCategory(null),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      );
                    },
                  ),
            actions: hasSelection
                ? _buildSelectionActions(context, selectedIds)
                : _buildSearchActions(context),
          ),
          body: Column(
            children: [
              DesktopMenuBar(
                onNewNote: _navigateToNewNote,
                onSearch: () =>
                    FocusScope.of(context).requestFocus(_searchFocusNode),
                onRefresh: () async {
                  final notesProvider =
                      Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.loadNotes(force: true);
                },
                onSettings: () => Navigator.pushNamed(context, '/settings'),
              ),
              Consumer<NotesProvider>(
                builder: (_, notes, __) => notes.isLoading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: MasterDetailsLayout(
                  masterPanel: Stack(
                    children: [
                      CustomScrollView(
                        controller: _notesScrollController,
                        slivers: [
                          NotesGridView(
                            viewTypeNotifier: _viewTypeNotifier,
                            selectedNoteIdsNotifier: _selectedNoteIdsNotifier,
                            searchController: _searchController,
                            scrollController: _notesScrollController,
                            activeFilterNotifier: _activeFilterNotifier,
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
                      NoteLocatorButton(
                        scrollController: _notesScrollController,
                      ),
                    ],
                  ),
                  detailsPanel: _cachedDetailsPanel ?? const DetailsPanel(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSearchActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ValueListenableBuilder<String>(
        valueListenable: _viewTypeNotifier,
        builder: (context, viewType, child) {
          return IconButton(
            icon: Icon(
              viewType == 'listExpanded' ? Icons.view_headline : Icons.view_day,
            ),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              setState(() {
                int currentIndex = _desktopViewTypes.indexOf(_viewType);
                int nextIndex = (currentIndex + 1) % _desktopViewTypes.length;
                _viewType = _desktopViewTypes[nextIndex];
                _viewTypeNotifier.value = _viewType.name;
              });
              final settings =
                  Provider.of<SettingsProvider>(context, listen: false);
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

  List<Widget> _buildSelectionActions(
      BuildContext context, Set<int> selectedIds) {
    return [
      DesktopSelectionActions(
        selectedIds: selectedIds,
        onClearSelection: () => _selectedNoteIdsNotifier.value = {},
      ),
    ];
  }

  /// إنشاء ملاحظة جديدة واختيارها تلقائياً
  Future<void> _navigateToNewNote(NoteMode mode) async {
    setState(() => _showAddMenu = false);

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    final categories = Provider.of<CategoriesProvider>(context, listen: false);
    final selectedCatId = categories.selectedCategoryId;

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
      categoryIds: selectedCatId != null ? [selectedCatId] : [],
    );

    final noteId = await notesProvider.addOrUpdateNote(newNote, silent: true);

    final savedNote = notesProvider.notes.firstWhere(
      (note) => note.id == noteId,
      orElse: () => newNote,
    );

    selectedNoteProvider.selectNote(savedNote);
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showClear =
        widget.controller.text.isNotEmpty || widget.focusNode.hasFocus;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Opacity(
          opacity: showClear ? 1.0 : 0.0,
          child: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: showClear
                ? () {
                    widget.controller.clear();
                    widget.focusNode.unfocus();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
