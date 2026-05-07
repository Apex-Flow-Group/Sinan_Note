// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/core/utils/search_mixin.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/screens/shared/main_layout_screen.dart';
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/home/dialogs/vault_dialogs.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart'
    show HomeDrawerWidget;
import 'package:apex_note/widgets/home/note_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockedNotesScreen extends StatefulWidget {
  const LockedNotesScreen({super.key});

  @override
  State<LockedNotesScreen> createState() => _LockedNotesScreenState();
}

class _LockedNotesScreenState extends State<LockedNotesScreen>
    with WidgetsBindingObserver, SearchMixin {
  final ValueNotifier<int> _closeAllSlidables = ValueNotifier<int>(0);
  final ViewType _viewType = ViewType.listExpanded;
  bool _isLoading = true;
  List<Note> _decryptedNotes = [];
  NotesProvider? _providerRef;
  bool _showAddMenu = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initSearch();
    searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _providerRef = Provider.of<NotesProvider>(context, listen: false);
      _loadLockedNotes();
      _providerRef!.loadNotes();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeAllSlidables.dispose();
    super.dispose();
  }

  final bool _isAuthenticating = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticating) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_showAddMenu) setState(() => _showAddMenu = false);
      _providerRef?.clearLockedSession(notify: false);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadLockedNotes() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<NotesProvider>(context, listen: false);
    _decryptedNotes = await provider.fetchAndDecryptLockedNotes();
    AppLogger.info(
        'Loaded ${_decryptedNotes.length} locked notes', 'LockedNotes');
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createLockedNote(NoteMode mode) async {
    String noteType;
    bool isChecklist = false, isProfessional = false;
    String initialContent = '';

    switch (mode) {
      case NoteMode.checklist:
        noteType = 'checklist';
        isChecklist = true;
        initialContent = '{"title":"","items":[]}';
        break;
      case NoteMode.code:
        noteType = 'code';
        isProfessional = true;
        break;
      default:
        noteType = 'simple';
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorImmersive(
          mode: mode,
          skipAuthentication: true,
          note: Note(
            title: '',
            content: initialContent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            colorIndex: 0,
            noteType: noteType,
            isLocked: true,
            isChecklist: isChecklist,
            isProfessional: isProfessional,
          ),
        ),
      ),
    );

    if (mounted) await _loadLockedNotes();
  }

  Future<void> _showImportSheet() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final allNotes = await provider.getNotes();
    if (!mounted) return;

    final unlocked = allNotes
        .where((n) => !n.isLocked && !n.isArchived && !n.isTrashed)
        .toList();

    if (unlocked.isEmpty) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.noUnlockedNotes,
        type: NotificationType.info,
      );
      return;
    }

    final selected = <int>{};
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => _ImportSheet(
        unlocked: unlocked,
        selected: selected,
        onConfirm: () async {
          for (final id in selected) {
            await provider.toggleLockStatus(id, true);
          }
          if (!modalContext.mounted) return;
          Navigator.pop(modalContext);
          await _loadLockedNotes();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _selectedNoteIds.isEmpty && searchController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _providerRef?.clearLockedSession(notify: false);
          _providerRef?.lockVault();
          WidgetsBinding.instance.removeObserver(this);
          return;
        }
        if (_selectedNoteIds.isNotEmpty) {
          setState(() => _selectedNoteIds.clear());
        } else if (searchController.text.isNotEmpty) {
          setState(() => searchController.clear());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: HomeDrawerWidget(
            onBackupTap: () {}, onNotesChanged: _loadLockedNotes),
        body: Stack(
          children: [
            Column(
              children: [
                Builder(builder: (ctx) {
                  if (_selectedNoteIds.isNotEmpty) {
                    return SearchableHeader(
                      title: '${_selectedNoteIds.length} ${l10n.selected}',
                      isSearching: false,
                      searchController: searchController,
                      onToggleSearch: () {},
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _selectedNoteIds.clear()),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.select_all, size: 20),
                            onPressed: () => setState(() {
                              for (final note in _decryptedNotes) {
                                if (!note.isArchived && !note.isTrashed) {
                                  _selectedNoteIds.add(note.id!);
                                }
                              }
                            }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock_open, size: 20),
                            onPressed: () => _confirmAction(
                              l10n.unlockNote,
                              l10n.unlockNoteConfirmation,
                              l10n.unlock,
                              () async {
                                for (final id in _selectedNoteIds) {
                                  await _providerRef?.toggleLockStatus(
                                      id, false);
                                }
                                setState(() => _selectedNoteIds.clear());
                                await _loadLockedNotes();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _confirmAction(
                              l10n.permanentDelete,
                              l10n.confirmPermanentDelete,
                              l10n.delete,
                              () async {
                                for (final id in _selectedNoteIds) {
                                  await _providerRef?.trashNote(id);
                                }
                                setState(() => _selectedNoteIds.clear());
                                await _loadLockedNotes();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SearchableHeader(
                    title: l10n.locked,
                    icon: Icons.lock_outline_rounded,
                    isSearching: searchController.text.isNotEmpty,
                    searchController: searchController,
                    onSearchChange: (q) => setState(() {}),
                    onToggleSearch: () => setState(() {
                      if (searchController.text.isNotEmpty) {
                        searchController.clear();
                      } else {
                        searchController.text = ' ';
                      }
                    }),
                    leading: Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          tooltip: l10n.settings,
                          onPressed: () => VaultDialogs.showSettings(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_download),
                          tooltip: l10n.import,
                          onPressed: _showImportSheet,
                        ),
                      ],
                    ),
                  );
                }),
                Expanded(
                  child:
                      _isLoading ? _buildLoading(l10n) : _buildNotesList(l10n),
                ),
              ],
            ),
            AddMenuWidget(
              showMenu: _showAddMenu,
              onToggle: () => setState(() => _showAddMenu = !_showAddMenu),
              onModeSelected: _createLockedNote,
              showLockBadge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.decryptingVault,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildNotesList(AppLocalizations l10n) {
    final query = searchController.text.toLowerCase();
    final filtered = _decryptedNotes
        .where((n) => !n.isArchived && !n.isTrashed)
        .where((n) =>
            query.isEmpty ||
            n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noLockedNotes,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final note = filtered[index];
        return NoteCardWidget(
          note: note,
          viewType: _viewType,
          closeAllSlidables: _closeAllSlidables,
          onNoteChanged: () async {
            if (mounted) await _loadLockedNotes();
          },
          onLongPress: () => setState(() => _selectedNoteIds.add(note.id!)),
          source: 'locked',
          isFiltering: false,
          selectionMode: _selectedNoteIds.isNotEmpty,
          isSelected: _selectedNoteIds.contains(note.id),
          onTap: () {
            if (_selectedNoteIds.isNotEmpty) {
              setState(() {
                if (_selectedNoteIds.contains(note.id)) {
                  _selectedNoteIds.remove(note.id);
                } else {
                  _selectedNoteIds.add(note.id!);
                }
              });
            }
          },
        );
      },
    );
  }

  void _confirmAction(String title, String content, String confirmLabel,
      Future<void> Function() onConfirm) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Import Sheet ─────────────────────────────────────────────────────────────

class _ImportSheet extends StatefulWidget {
  final List<Note> unlocked;
  final Set<int> selected;
  final Future<void> Function() onConfirm;

  const _ImportSheet({
    required this.unlocked,
    required this.selected,
    required this.onConfirm,
  });

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _searchCtrl = TextEditingController();
  String? _filter; // null = الكل

  static const _filterTypes = [
    ('simple', Icons.notes_rounded, null),
    ('rich', Icons.format_color_text, null),
    ('checklist', Icons.checklist_rounded, null),
    ('code', Icons.code_rounded, null),
    ('reminder', Icons.alarm_rounded, null),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _typeKey(Note note) {
    if (note.isChecklist || note.noteType == 'checklist') return 'checklist';
    if (note.isProfessional || note.noteType == 'code') return 'code';
    if (note.noteType == 'reminder') return 'reminder';
    if (note.noteType == 'rich') return 'rich';
    return 'simple';
  }

  (String, String) _displayInfo(Note note, AppLocalizations l10n) {
    String title = note.title.isEmpty ? l10n.untitled : note.title;
    String content;

    if (note.isChecklist) {
      try {
        final decoded = jsonDecode(note.content);
        if (decoded is Map) {
          final t = (decoded['title'] ?? '').toString().trim();
          if (t.isNotEmpty) title = t;
          final items = decoded['items'] as List? ?? [];
          content = items
              .map((i) =>
                  '${i['isDone'] == true ? '☑' : '☐'} ${i['text'] ?? ''}')
              .join('  ');
          if (content.isEmpty) content = '${items.length} items';
        } else {
          content = 'Checklist';
        }
      } catch (_) {
        content = 'Checklist';
      }
    } else {
      final raw = note.content.trim();
      if (raw.startsWith('[') || raw.startsWith('{')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            content = decoded.map((op) => op['insert'] ?? '').join().trim();
          } else {
            content = raw;
          }
        } catch (_) {
          content = raw;
        }
      } else {
        content = raw;
      }
    }

    return (title, content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final query = _searchCtrl.text.trim().toLowerCase();

    // أنواع موجودة فعلاً
    final availableTypes = _filterTypes
        .where((f) => widget.unlocked.any((n) => _typeKey(n) == f.$1))
        .toList();

    final filterLabels = {
      'simple': l10n.simpleNote,
      'rich': l10n.richNoteMenu,
      'checklist': l10n.checklistNote,
      'code': l10n.codeNote,
      'reminder': l10n.reminder,
    };

    // تطبيق الفلتر والبحث
    final visible = widget.unlocked.where((n) {
      if (_filter != null && _typeKey(n) != _filter) return false;
      if (query.isEmpty) return true;
      final (title, content) = _displayInfo(n, l10n);
      return title.toLowerCase().contains(query) ||
          content.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            // ─── Handle ───────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Title row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.importNotes,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.selected.isNotEmpty)
                    Text(
                      '${widget.selected.length} ${l10n.selected}',
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.searchNotes,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: 0.07),
                ),
              ),
            ),

            // ─── Filter chips ─────────────────────────────────────
            if (availableTypes.length >= 2)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: FilterChip(
                        label: Text(l10n.clearFilter),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                        showCheckmark: false,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color: _filter == null
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontSize: 12,
                          fontWeight: _filter == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...availableTypes.map((f) {
                      final isActive = _filter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        child: FilterChip(
                          label: Text(filterLabels[f.$1] ?? f.$1),
                          avatar: Icon(f.$2,
                              size: 14,
                              color: isActive
                                  ? scheme.onPrimary
                                  : scheme.onSurface),
                          selected: isActive,
                          onSelected: (_) =>
                              setState(() => _filter = isActive ? null : f.$1),
                          showCheckmark: false,
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            color:
                                isActive ? scheme.onPrimary : scheme.onSurface,
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const Divider(height: 8),

            // ─── List ─────────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(l10n.noResults,
                          style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final note = visible[i];
                        final isSelected = widget.selected.contains(note.id);
                        final (title, content) = _displayInfo(note, l10n);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) => setState(() {
                            if (val == true) {
                              widget.selected.add(note.id!);
                            } else {
                              widget.selected.remove(note.id);
                            }
                          }),
                          title: Text(title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(content,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          secondary: Icon(
                            _filterTypes
                                .firstWhere((f) => f.$1 == _typeKey(note),
                                    orElse: () => _filterTypes.first)
                                .$2,
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
            ),

            // ─── Confirm button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: widget.selected.isEmpty ? null : widget.onConfirm,
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.lockNotesCount(widget.selected.length)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
