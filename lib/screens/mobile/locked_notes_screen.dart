// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/core/utils/search_mixin.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/screens/mobile/vault_import_sheet.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';
import 'package:sinan_note/services/security/vault_reset_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/searchable_header.dart';
import 'package:sinan_note/widgets/home/add_menu_widget.dart';
import 'package:sinan_note/widgets/home/dialogs/vault_dialogs.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart'
    show HomeDrawerWidget, setDrawerVaultActive;
import 'package:sinan_note/widgets/home/note_card_widget.dart';

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
      // setDrawerVaultActive هنا وليس في initState مباشرة —
      // لأنها تُعدّل ValueNotifier وتُطلق notifyListeners أثناء الـ build
      setDrawerVaultActive(true);
      _providerRef = Provider.of<NotesProvider>(context, listen: false);
      _providerRef!.addListener(_onProviderChanged);
      _loadLockedNotes();
      _providerRef!.loadNotes();
    });
  }

  void _onProviderChanged() {
    // إعادة تحميل الملاحظات المقفلة عند أي تغيير في الـ provider
    // (مثل إضافة ملاحظة جديدة من المحرر)
    if (mounted && !_isLoading) {
      _loadLockedNotes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _providerRef?.removeListener(_onProviderChanged);
    WidgetsBinding.instance.removeObserver(this);
    _closeAllSlidables.dispose();
    super.dispose();
  }

  // يُضبط على true أثناء أي عملية مصادقة (dialog بيومتري/PIN)
  // يمنع didChangeAppLifecycleState من إغلاق الشاشة أثناء المصادقة
  bool _isAuthenticating = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticating ||
        VaultResetGuard.isActive ||
        UnifiedLockService().isVaultOperation) {
      return;
    }

    // على Desktop: نُغلق الخزنة عند تصغير النافذة أو إخفائها
    // hidden = تصغير على Windows/macOS
    // paused = خلفية على Mobile
    // inactive = فقدان التركيز (نتجاهله على Desktop)
    final bool shouldLock;
    if (PlatformHelper.isDesktopPlatform) {
      shouldLock = state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    } else {
      shouldLock = state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive;
    }

    if (shouldLock) {
      if (_showAddMenu) {
        setState(() => _showAddMenu = false);
      }
      _providerRef?.clearLockedSession(notify: false);
      setDrawerVaultActive(false);
      if (mounted) {
        VaultNavigator.exitVault(context);
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
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = provider.createDefaultLockedNote(mode: mode);

    await AppNavigator.toEditor(
      context,
      note: note,
      mode: mode,
      skipAuthentication: true,
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

    _isAuthenticating = true;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => VaultImportSheet(
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
    if (mounted) _isAuthenticating = false;
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
          setDrawerVaultActive(false);
          WidgetsBinding.instance.removeObserver(this);
          // رجوع لأول شاشة في الـ stack (MainLayout) بدلاً من VaultEntryScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              VaultNavigator.exitVault(context);
            }
          });
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
                    isSearching: isSearchActive,
                    searchController: searchController,
                    onSearchChange: (q) => setState(() {}),
                    onToggleSearch: () => toggleSearch(),
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
    final query = Note.normalize(searchController.text.trim());
    final filtered = _decryptedNotes
        .where((n) => !n.isArchived && !n.isTrashed)
        .where((n) =>
            query.isEmpty ||
            n.normalizedTitle.contains(query) ||
            n.normalizedContent.contains(query))
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
    // نضبط _isAuthenticating لمنع lifecycle من إغلاق الشاشة أثناء الـ dialog
    _isAuthenticating = true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).whenComplete(() {
      if (mounted) _isAuthenticating = false;
    });
  }
}

// ─── Import Sheet ─────────────────────────────────────────────────────────────
// نُقل إلى vault_import_sheet.dart (UI1)
