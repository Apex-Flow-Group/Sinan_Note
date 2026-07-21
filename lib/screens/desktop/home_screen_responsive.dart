// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/master_width_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/shortcuts/app_shortcuts.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart';
import 'package:sinan_note/widgets/desktop/desktop_menu_bar.dart';
import 'package:sinan_note/widgets/desktop/desktop_selection_actions.dart';
import 'package:sinan_note/widgets/home/add_menu_widget.dart';
import 'package:sinan_note/widgets/home/dialogs/backup_options_dialog.dart';
import 'package:sinan_note/widgets/home/dialogs/filter_sheet.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';
import 'package:sinan_note/widgets/home/note_locator_button.dart';
import 'package:sinan_note/widgets/home/notes_grid_view.dart';
import 'package:sinan_note/widgets/layout/details_panel.dart';
import 'package:sinan_note/widgets/layout/master_details_layout.dart';
import 'package:sinan_note/widgets/layout/responsive_layout_wrapper.dart';

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
  final Widget? sharedDetailsPanel;

  const HomeScreenResponsive({
    super.key,
    this.sharedText,
    this.onDrawerChanged,
    this.showAddMenu = false,
    required this.onToggleMenu,
    this.onRegisterModeHandler,
    this.sharedDetailsPanel,
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
    _searchController.addListener(_onSearchStateChanged);
    _searchFocusNode.addListener(_onSearchStateChanged);
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
    _cachedDetailsPanel = widget.sharedDetailsPanel ??
        ValueListenableBuilder<Set<int>>(
          valueListenable: _selectedNoteIdsNotifier,
          builder: (context, selectedIds, _) => DetailsPanel(
            selectedIds: selectedIds,
            onClearSelection: () => _selectedNoteIdsNotifier.value = {},
          ),
        );
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
    final savedType = await settings.getViewType('home_desktop');
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
    _searchController.removeListener(_onSearchStateChanged);
    _searchFocusNode.removeListener(_onSearchStateChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _selectedNoteIdsNotifier.dispose();
    _viewTypeNotifier.dispose();
    _notesScrollController.dispose();
    _activeFilterNotifier.dispose();
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) setState(() {});
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

    return ShortcutScope(
      bindings: {
        AppShortcuts.newNote: () => _navigateToNewNote(NoteMode.simple),
        AppShortcuts.richNote: () => _navigateToNewNote(NoteMode.rich),
        AppShortcuts.codeNote: () => _navigateToNewNote(NoteMode.code),
        AppShortcuts.checklist: () => _navigateToNewNote(NoteMode.checklist),
        AppShortcuts.reminder: () => _navigateToNewNote(NoteMode.reminder),
        AppShortcuts.search: () =>
            FocusScope.of(context).requestFocus(_searchFocusNode),
        AppShortcuts.refresh: () =>
            Provider.of<NotesProvider>(context, listen: false)
                .loadNotes(force: true),
        AppShortcuts.settings: () => AppNavigator.toSettings(context),
        AppShortcuts.toggleView: () {
          setState(() {
            int currentIndex = _desktopViewTypes.indexOf(_viewType);
            int nextIndex = (currentIndex + 1) % _desktopViewTypes.length;
            _viewType = _desktopViewTypes[nextIndex];
            _viewTypeNotifier.value = _viewType.name;
          });
          Provider.of<SettingsProvider>(context, listen: false)
              .setViewType('home_desktop', _viewType.name);
        },
      },
      child: _buildMasterDetailsScaffold(context, l10n),
    );
  }

  Widget _buildMasterDetailsScaffold(
      BuildContext context, AppLocalizations l10n) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedNoteIdsNotifier,
      builder: (context, selectedIds, _) {
        return Stack(
          children: [
            Scaffold(
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
                onTabSelected: (index) {
                  currentTabIndexNotifier.value = index;
                },
              ),
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  titleSpacing: NavigationToolbar.kMiddleSpacing,
                  leading: ClipRect(
                    child: AnimatedSlide(
                      offset: selectedIds.isNotEmpty
                          ? const Offset(0, -1)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                  ),
                  title: ClipRect(
                    child: AnimatedSlide(
                      offset: selectedIds.isNotEmpty
                          ? const Offset(0, -1)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Consumer<CategoriesProvider>(
                        builder: (context, cats, _) {
                          final selectedId = cats.selectedCategoryId;
                          return _UnifiedToolbar(
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            searchHint: l10n.searchNotes,
                            selectedCategoryId: selectedId,
                            categoryName: selectedId == null
                                ? null
                                : selectedId == kProCategoryId
                                    ? l10n.professional
                                    : (cats.categories
                                            .where((c) => c.id == selectedId)
                                            .firstOrNull
                                            ?.name ??
                                        ''),
                            onCategoryDismiss: () => cats.selectCategory(null),
                            menuBar: DesktopMenuBar(
                              onNewNote: _navigateToNewNote,
                              onSearch: () => FocusScope.of(context)
                                  .requestFocus(_searchFocusNode),
                              onRefresh: () async {
                                final notesProvider =
                                    Provider.of<NotesProvider>(context,
                                        listen: false);
                                await notesProvider.loadNotes(force: true);
                              },
                              onSettings: () =>
                                  AppNavigator.toSettings(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  actions: [
                    ClipRect(
                      child: AnimatedSlide(
                        offset: selectedIds.isNotEmpty
                            ? const Offset(0, -1)
                            : Offset.zero,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildSearchActions(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
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
                                selectedNoteIdsNotifier:
                                    _selectedNoteIdsNotifier,
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
            ), // Scaffold
            Positioned(
              top: 0,
              left: 0,
              child: Consumer<MasterWidthProvider>(
                builder: (context, masterWidth, _) => AnimatedSlide(
                  offset: selectedIds.isNotEmpty
                      ? Offset.zero
                      : const Offset(0, -1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _SelectionBar(
                    width: masterWidth.width,
                    selectedIds: selectedIds,
                    onClearSelection: () => _selectedNoteIdsNotifier.value = {},
                  ),
                ),
              ),
            ),
          ],
        ); // Stack
      },
    );
  }

  List<Widget> _buildSearchActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSearching =
        _searchController.text.isNotEmpty || _searchFocusNode.hasFocus;

    return [
      // زر بحث / خروج — يتحول حسب الحالة
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSearching
            ? IconButton(
                key: const ValueKey('exit_search'),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.close,
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {});
                },
              )
            : IconButton(
                key: const ValueKey('search'),
                icon: const Icon(Icons.search_rounded),
                tooltip: l10n.searchNotes,
                onPressed: () {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                },
              ),
      ),
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
              await settings.setViewType('home_desktop', _viewType.name);
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

  /// إنشاء ملاحظة جديدة واختيارها تلقائياً
  Future<void> _navigateToNewNote(NoteMode mode) async {
    setState(() => _showAddMenu = false);

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    final categories = Provider.of<CategoriesProvider>(context, listen: false);

    final colorMode = switch (mode) {
      NoteMode.reminder => 'reminder',
      NoteMode.code => 'professional',
      NoteMode.checklist => 'checklist',
      NoteMode.rich => 'rich',
      _ => 'simple',
    };

    final newNote = notesProvider.createDefaultNote(
      mode: mode,
      colorIndex: settings.getDefaultColorIndex(colorMode),
      categoryIds: categories.selectedCategoryId != null
          ? [categories.selectedCategoryId!]
          : [],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final showClear =
        widget.controller.text.isNotEmpty || widget.focusNode.hasFocus;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.onSurface.withValues(alpha: 0.06)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: Opacity(
                opacity: showClear ? 1.0 : 0.0,
                child: IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: showClear
                      ? () {
                          widget.controller.clear();
                          widget.focusNode.unfocus();
                        }
                      : null,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط موحّد يجمع القوائم (File|Edit|View|Help) مع حقل البحث في حاوية واحدة
class _UnifiedToolbar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchHint;
  final int? selectedCategoryId;
  final String? categoryName;
  final VoidCallback? onCategoryDismiss;
  final Widget menuBar;

  const _UnifiedToolbar({
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHint,
    required this.menuBar,
    this.selectedCategoryId,
    this.categoryName,
    this.onCategoryDismiss,
  });

  @override
  State<_UnifiedToolbar> createState() => _UnifiedToolbarState();
}

class _UnifiedToolbarState extends State<_UnifiedToolbar>
    with SingleTickerProviderStateMixin {
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
    widget.searchFocusNode.addListener(_onFocusChanged);
    _isSearchActive = widget.searchFocusNode.hasFocus ||
        widget.searchController.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    widget.searchFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final active = widget.searchFocusNode.hasFocus ||
        widget.searchController.text.isNotEmpty;
    if (_isSearchActive != active) setState(() => _isSearchActive = active);
  }

  void _onFocusChanged() {
    final active = widget.searchFocusNode.hasFocus ||
        widget.searchController.text.isNotEmpty;
    if (_isSearchActive != active) setState(() => _isSearchActive = active);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.onSurface.withValues(alpha: 0.06)
            : colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // >= 320: قوائم كاملة + حقل بحث
          // 200-320: قائمة منسدلة + حقل بحث
          // < 200: قائمة منسدلة + أيقونة بحث فقط (آخر ما يُطوى)
          final showInlineMenu = !_isSearchActive && width >= 320;
          final showSearchField = _isSearchActive || width >= 200;

          return Row(
            children: [
              if (!_isSearchActive) ...[
                if (showInlineMenu)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        menuBarTheme: MenuBarThemeData(
                          style: MenuStyle(
                            backgroundColor: const WidgetStatePropertyAll(
                                Colors.transparent),
                            elevation: const WidgetStatePropertyAll(0),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 4)),
                          ),
                        ),
                      ),
                      child: widget.menuBar,
                    ),
                  )
                else
                  _OverflowMenuAnchor(menuBar: widget.menuBar),
                Container(
                  width: 1,
                  height: 20,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ],
              if (showSearchField)
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    focusNode: widget.searchFocusNode,
                    style:
                        TextStyle(fontSize: 13, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.search_rounded,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: () => widget.searchFocusNode.requestFocus(),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (widget.selectedCategoryId != null &&
                  widget.categoryName != null &&
                  showSearchField &&
                  !_isSearchActive) ...[
                const SizedBox(width: 4),
                Chip(
                  avatar: const Icon(Icons.label_rounded, size: 14),
                  label: Text(widget.categoryName!,
                      style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: widget.onCategoryDismiss,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// زر ⋯ منسدل — يعرض قوائم File/Edit/View/Help عند ضيق المساحة
class _OverflowMenuAnchor extends StatefulWidget {
  final Widget menuBar;
  const _OverflowMenuAnchor({required this.menuBar});

  @override
  State<_OverflowMenuAnchor> createState() => _OverflowMenuAnchorState();
}

class _OverflowMenuAnchorState extends State<_OverflowMenuAnchor> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      controller: _controller,
      menuChildren: [
        // نعرض الـ menuBar نفسه داخل القائمة المنسدلة
        Theme(
          data: Theme.of(context).copyWith(
            menuBarTheme: const MenuBarThemeData(
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                elevation: WidgetStatePropertyAll(0),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
            ),
          ),
          child: widget.menuBar,
        ),
      ],
      child: IconButton(
        icon: Icon(Icons.more_horiz_rounded,
            size: 20, color: colorScheme.onSurface.withValues(alpha: 0.7)),
        onPressed: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        tooltip: '',
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final Set<int> selectedIds;
  final VoidCallback onClearSelection;
  final double width;

  const _SelectionBar({
    required this.selectedIds,
    required this.onClearSelection,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        height: kToolbarHeight,
        child: ClipRect(
          child: AnimatedSlide(
            offset: selectedIds.isNotEmpty ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClearSelection,
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${selectedIds.length} ${l10n.selected}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DesktopSelectionActions(
                    selectedIds: selectedIds,
                    onClearSelection: onClearSelection,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
