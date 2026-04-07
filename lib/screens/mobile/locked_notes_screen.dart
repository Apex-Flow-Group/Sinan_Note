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
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/home/dialogs/vault_dialogs.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeAllSlidables.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 16, bottom: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.importNotes,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: unlocked.length,
                        itemBuilder: (context, i) {
                          final note = unlocked[i];
                          final isSelected = selected.contains(note.id);
                          String displayTitle =
                              note.title.isEmpty ? l10n.untitled : note.title;
                          String displayContent;

                          if (note.isChecklist) {
                            try {
                              final decoded = jsonDecode(note.content);
                              if (decoded is Map) {
                                final t =
                                    (decoded['title'] ?? '').toString().trim();
                                displayTitle = t.isEmpty ? 'Checklist' : t;
                                final items = decoded['items'] as List? ?? [];
                                displayContent = items
                                    .map((i) =>
                                        '${i['isDone'] == true ? '☑' : '☐'} ${i['text'] ?? ''}')
                                    .join('\n');
                                if (displayContent.isEmpty) {
                                  displayContent = '${items.length} items';
                                }
                              } else {
                                displayContent = 'Checklist';
                              }
                            } catch (_) {
                              displayContent = 'Checklist';
                            }
                          } else {
                            // استخراج النص الحقيقي من Delta JSON أو نص عادي
                            final raw = note.content.trim();
                            if (raw.startsWith('[') || raw.startsWith('{')) {
                              try {
                                final decoded = jsonDecode(raw);
                                if (decoded is List) {
                                  // Delta format من Quill
                                  displayContent = decoded
                                      .map((op) => op['insert'] ?? '')
                                      .join()
                                      .trim();
                                } else {
                                  displayContent = raw;
                                }
                              } catch (_) {
                                displayContent = raw;
                              }
                            } else {
                              displayContent = raw;
                            }
                          }

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) => setModalState(() {
                              if (val == true) {
                                selected.add(note.id!);
                              } else {
                                selected.remove(note.id);
                              }
                            }),
                            title: Text(displayTitle, maxLines: 1),
                            subtitle: Text(displayContent,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SafeArea(
                      child: ElevatedButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                for (final id in selected) {
                                  await provider.toggleLockStatus(id, true);
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                await _loadLockedNotes();
                              },
                        icon: const Icon(Icons.lock),
                        label: Text(l10n.lockNotesCount(selected.length)),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
        drawer: HomeDrawerWidget(
            onBackupTap: () {}, onNotesChanged: _loadLockedNotes),
        body: Stack(
          children: [
            // المحتوى مع padding للـ AppBar
            Column(
              children: [
                AppBar(
                  leading: _selectedNoteIds.isEmpty
                      ? Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedNoteIds.clear()),
                        ),
                  title: _buildAppBarTitle(l10n),
                  actions: _selectedNoteIds.isEmpty ? _buildActions(l10n) : [],
                ),
                Expanded(
                  child: _isLoading ? _buildLoading(l10n) : _buildNotesList(l10n),
                ),
              ],
            ),
            // القائمة تغطي كامل الشاشة بما فيها الشريط العلوي
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

  Widget _buildAppBarTitle(AppLocalizations l10n) {
    if (_selectedNoteIds.isNotEmpty) {
      return Row(
        children: [
          Text('${_selectedNoteIds.length} ${l10n.selected}'),
          const Spacer(),
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
                  await _providerRef?.toggleLockStatus(id, false);
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
      );
    }
    if (searchController.text.isNotEmpty) {
      return TextField(
        controller: searchController,
        autofocus: true,
        decoration: InputDecoration(
            hintText: l10n.searchNotes, border: InputBorder.none),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock, size: 22),
        const SizedBox(width: 8),
        Text(l10n.locked),
      ],
    );
  }

  List<Widget> _buildActions(AppLocalizations l10n) => [
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
        IconButton(
          icon:
              Icon(searchController.text.isEmpty ? Icons.search : Icons.close),
          onPressed: () => setState(() {
            if (searchController.text.isEmpty) {
              searchController.text = ' ';
            } else {
              searchController.clear();
            }
          }),
        ),
      ];

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
