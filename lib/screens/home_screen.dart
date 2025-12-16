// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../services/notes_provider.dart';
import '../services/settings_provider.dart';
import '../l10n/l10n_migration_helper.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/breathing_search_field.dart';
import '../widgets/home/note_card_widget.dart';
import '../widgets/home/add_menu_widget.dart' show AddMenuWidget, isMenuOpenNotifier;
import '../widgets/home/home_drawer_widget.dart';
import '../widgets/home/smooth_search_header_delegate.dart';
import '../widgets/home/selection_action_bar.dart';
import '../utils/checklist_formatter.dart';

import '../widgets/home/dialogs/backup_options_dialog.dart';
import '../widgets/custom_share_sheet.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isSearchActive = false;
  bool _isTransitioning = false; // Temporal Lock
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier(0);
  ViewType _viewType = ViewType.listExpanded;
  late final ValueNotifier<String> _viewTypeNotifier;
  final ValueNotifier<int> _selectionCountNotifier = ValueNotifier(0);
  bool _showAddMenu = false;
  Timer? _debounce;
  final Set<int> _selectedNoteIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadViewType();
    _viewTypeNotifier = ValueNotifier(_viewType.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadNotes();
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchActive =
              _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sharedText != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              return NoteEditorImmersive(
                mode: NoteMode.code,
                note: Note(
                  title: context.l10n.importedFile,
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

  void _loadViewType() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedType = settings.viewType;
    if (savedType == 'grid') {
      _viewType = ViewType.grid;
    } else if (savedType == 'listExpanded') {
      _viewType = ViewType.listExpanded;
    } else {
      _viewType = ViewType.listCompact;
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    if (mounted) {
      setState(() {
        _isSearchActive =
            _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    }
  }

  void _exitSearchMode() async {
    // 1. Set Transition Lock IMMEDIATELY
    setState(() => _isTransitioning = true);

    // 2. Reset Search State
    _isSearchActive = false;
    _searchQuery = '';

    // 3. Clear UI elements
    _searchController.clear();
    _searchFocusNode.unfocus();

    // 4. CRITICAL FIX: Wait longer for render engine to stabilize
    await Future.delayed(
        const Duration(milliseconds: 100)); // INCREASED TO 100ms

    // 5. Release Lock
    if (mounted) {
      setState(() => _isTransitioning = false);
    }
  }



  List<Note> _filterNotes(List<Note> notes) {
    final filtered = notes.where((note) {
      // SECURITY: Block locked notes from appearing in home screen
      if (note.isLocked) return false;
      if (note.isArchived || note.isTrashed) return false;
      if (_searchQuery.isEmpty) return true;
      
      // Parse filter queries
      if (_searchQuery.startsWith('type:')) {
        final type = _searchQuery.substring(5);
        return _matchNoteType(note, type);
      }
      
      if (_searchQuery.startsWith('pinned:')) {
        return note.isPinned;
      }
      
      // Regular search
      return note.title.toLowerCase().contains(_searchQuery) ||
          note.content.toLowerCase().contains(_searchQuery);
    }).toList();
    
    // Ensure pinned notes always appear first
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    return filtered;
  }

  bool _matchNoteType(Note note, String type) {
    switch (type) {
      case 'simple':
        return note.noteType == 'simple' || note.noteType.isEmpty;
      case 'pro':
      case 'code':
        return note.noteType == 'pro' || 
               note.noteType == 'code' || 
               note.isProfessional;
      case 'reminder':
        return note.reminderDateTime != null;
      case 'checklist':
        return note.noteType == 'checklist' || note.isChecklist;
      default:
        return false;
    }
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

  void _onScroll() {
    // Pagination removed - all data loaded at once
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _closeAllSlidables.dispose();
    _viewTypeNotifier.dispose();
    _selectionCountNotifier.dispose();
    ToastService().cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final allNotes = notesProvider.notes;
        final filteredNotes = _filterNotes(allNotes);

        return PopScope(
          canPop: !_showAddMenu && !_isSearchActive && _selectedNoteIds.isEmpty,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectedNoteIds.isNotEmpty) {
              setState(() => _selectedNoteIds.clear());
              return;
            }
            if (_showAddMenu) {
              setState(() => _showAddMenu = false);
              isMenuOpenNotifier.value = false;
              return;
            }
            if (_isSearchActive) {
              _exitSearchMode();
              return;
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor:
                  Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
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
                    child: MediaQuery.removeViewInsets(
                      context: context,
                      removeBottom: true,
                      child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _closeAllSlidables.value++;
                        // Critical: Only unfocus if NOT actively interacting with search
                        // This prevents race condition with AppBar icon
                        if (!_isSearchActive || _searchController.text.isEmpty) {
                          FocusScope.of(context).unfocus();
                        }
                      },
                      child: SlidableAutoCloseBehavior(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              _closeAllSlidables.value++;
                            }
                            return false;
                          },
                          child: CustomScrollView(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              _buildHeader(context, l10n, isDark, allNotes),
                              _buildContent(filteredNotes, l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark,
      List<Note> allNotes) {
    return SliverPersistentHeader(
      pinned: _selectedNoteIds.isNotEmpty,
      floating: _selectedNoteIds.isEmpty,
      delegate: SmoothSearchHeaderDelegate(
        expandedHeight: 80.0,
        isDark: isDark,
        selectionMode: _selectedNoteIds.isNotEmpty,
        isSearchActive: _isSearchActive,
        selectionBar: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: ValueListenableBuilder<int>(
                valueListenable: _selectionCountNotifier,
                builder: (context, count, _) => SelectionActionBar(
                  selectedCount: count,
                  isDark: isDark,
                  allPinned: _selectedNoteIds.isNotEmpty &&
                      _selectedNoteIds.every((id) => allNotes
                          .firstWhere((n) => n.id == id,
                              orElse: () => Note(
                                  id: -1,
                                  title: '',
                                  content: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  colorIndex: 0,
                                  isLocked: false,
                                  noteType: '',
                                  isPinned: false))
                          .isPinned),
                  onClear: () => setState(() {
                    _selectedNoteIds.clear();
                    _selectionCountNotifier.value = 0;
                  }),
                  onPin: () => _togglePinSelected(l10n, allNotes),
                  onArchive: () => _archiveSelected(l10n),
                  onDelete: () => _deleteSelected(l10n),
                  onShare: count == 1 ? () => _shareSelected(allNotes) : null,
                ),
              ),
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Builder(
                builder: (context) => Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Theme.of(context).colorScheme.surfaceBright : Theme.of(context).colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isSearchActive ? Icons.arrow_back : Icons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () {
                          // 1. CRITICAL CHECK: Block if mid-transition from a previous tap
                          if (_isTransitioning) return;

                          // 2. The Search Exit Path (Takes priority and exits immediately)
                          if (_isSearchActive) {
                            // _exitSearchMode handles the lock and state reset internally.
                            _exitSearchMode();
                            return; // Hard stop - prevents any possibility of falling through.
                          }

                          // 3. The Default Path (Only executes if search is NOT active)
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        splashRadius: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BreathingSearchField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: l10n.searchNotes,
                        viewTypeNotifier: _viewTypeNotifier,
                        onViewToggle: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            int nextIndex =
                                (_viewType.index + 1) % ViewType.values.length;
                            _viewType = ViewType.values[nextIndex];
                            _viewTypeNotifier.value = _viewType.name;
                          });
                          final settings = Provider.of<SettingsProvider>(
                              context,
                              listen: false);
                          settings.setViewType('home', _viewType.name);
                        },
                        onFilterTap: () {
                          FocusScope.of(context).unfocus();
                          _showFilterDialog(context, l10n);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Note> filteredNotes, AppLocalizations l10n) {
    if (filteredNotes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noNotes,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewType == ViewType.grid) {
      final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
      final bottomPadding = fabBottom + 56 + 8;
      return SliverPadding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200
              ? 4
              : MediaQuery.of(context).size.width >= 600
                  ? 3
                  : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: filteredNotes.length,
          itemBuilder: (context, index) =>
              _buildNoteCard(filteredNotes[index], 'home_grid'),
        ),
      );
    }

    final fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
    final bottomPadding = fabBottom + 56 + 8;
    return SliverPadding(
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildNoteCard(filteredNotes[index], 'home_list'),
          childCount: filteredNotes.length,
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, String source) {
    return NoteCardWidget(
      note: note,
      viewType: _viewType,
      closeAllSlidables: _closeAllSlidables,
      onNoteChanged: () => setState(() {}),
      isSelected: _selectedNoteIds.contains(note.id),
      selectionMode: _selectedNoteIds.isNotEmpty,
      source: source,
      onLongPress: () => setState(() {
        _selectedNoteIds.add(note.id!);
        _selectionCountNotifier.value = _selectedNoteIds.length;
      }),
      onTap: () {
        if (_selectedNoteIds.isNotEmpty) {
          setState(() {
            if (_selectedNoteIds.contains(note.id)) {
              _selectedNoteIds.remove(note.id);
            } else {
              _selectedNoteIds.add(note.id!);
            }
            _selectionCountNotifier.value = _selectedNoteIds.length;
          });
        }
      },
    );
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.noteType,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.note, color: Colors.blue),
                title: Text(l10n.simpleNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'type:simple');
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.purple),
                title: Text(l10n.professionalNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'type:pro');
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.orange),
                title: Text(l10n.reminderNotes),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'type:reminder');
                },
              ),
              ListTile(
                leading: const Icon(Icons.checklist, color: Colors.green),
                title: Text(l10n.checklists),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'type:checklist');
                },
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.noteStatus,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.red),
                title: Text(l10n.pinnedOnly),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'pinned:true');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.red),
                title: Text(l10n.clearFilter),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePinSelected(
      AppLocalizations l10n, List<Note> allNotes) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    final isPinning = !allNotes.firstWhere((n) => n.id == ids.first).isPinned;
    
    for (final id in ids) {
      final note = allNotes.firstWhere((n) => n.id == id);
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
    if (mounted) {
      setState(() => _selectedNoteIds.clear());
      ToastService().showToast(
        context: context,
        message: isPinning ? '${ids.length} notes pinned' : '${ids.length} notes unpinned',
        type: ToastType.success,
      );
    }
  }

  Future<void> _archiveSelected(AppLocalizations l10n) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);
    
    setState(() => _selectedNoteIds.clear());
    
    // Execute immediately
    for (final id in ids) {
      await notesProvider.archiveNote(id);
    }
    
    if (!mounted) return;
    
    // Show toast with undo
    ToastService().showUndoToast(
      context: context,
      message: '${ids.length} notes archived',
      actionKey: 'archive_home',
      type: ToastType.success,
      onExecute: () {},
      onUndo: () async {
        for (final id in ids) {
          await notesProvider.unarchiveNote(id);
        }
      },
      undoLabel: l10n.undo,
    );
  }

  Future<void> _deleteSelected(AppLocalizations l10n) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final ids = List<int>.from(_selectedNoteIds);

    setState(() => _selectedNoteIds.clear());
    
    // Execute immediately
    for (final id in ids) {
      await notesProvider.trashNote(id);
    }
    
    if (!mounted) return;
    
    // Show toast with undo
    ToastService().showUndoToast(
      context: context,
      message: '${ids.length} notes deleted',
      actionKey: 'delete_home',
      type: ToastType.info,
      onExecute: () {},
      onUndo: () async {
        for (final id in ids) {
          await notesProvider.restoreNote(id);
        }
      },
      undoLabel: l10n.undo,
    );
  }

  void _shareSelected(List<Note> allNotes) {
    final selectedNotes =
        allNotes.where((n) => _selectedNoteIds.contains(n.id)).toList();
    final text = selectedNotes.map((n) {
      if (n.isChecklist) {
        return ChecklistFormatter.formatForSharing(n.title, n.content);
      }
      return '${n.title}\n\n${n.content}';
    }).join('\n\n---\n\n');
    CustomShareSheet.show(context, text);
    setState(() => _selectedNoteIds.clear());
  }
}
