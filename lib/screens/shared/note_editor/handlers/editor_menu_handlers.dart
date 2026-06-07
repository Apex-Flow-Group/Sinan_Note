// Copyright © 2025 Apex Flow Group. All rights reserved.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/editor/category_picker_sheet.dart';

/// Mixin يحتوي على عمليات قائمة المحرر: أرشفة، تثبيت، تكرار، حذف، كتالوج
mixin EditorMenuHandlersMixin<T extends StatefulWidget> on State<T> {
  EditorCoordinator get menuCoordinator;
  int? get menuNoteId;
  bool Function() get menuIsMounted;
  void Function(VoidCallback) get menuSetState;
  Future<void> Function() get menuHandleBack;

  /// أرشفة الملاحظة مع snackbar تراجع
  Future<void> handleMenuArchive() async {
    final noteId = menuNoteId;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.archiveNote(noteId);
    if (!mounted) return;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToArchive,
      type: NotificationType.success,
      actionKey: 'menu_archive_$noteId',
      onExecute: () {},
      onUndo: () async => await provider.unarchiveNote(noteId),
      undoLabel: l10n.undo,
    );
    menuHandleBack();
  }

  /// تثبيت/إلغاء تثبيت الملاحظة مع snackbar
  Future<void> handleMenuPin() async {
    final noteId = menuNoteId;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final notes = provider.notes;
    final note = notes.where((n) => n.id == noteId).firstOrNull;
    if (note == null) return;
    final wasPinned = note.isPinned;
    await provider.updateNote(note.copyWith(isPinned: !wasPinned));
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: wasPinned ? l10n.unpin : l10n.pin,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// تكرار الملاحظة مع snackbar
  Future<void> handleMenuDuplicate() async {
    final noteId = menuNoteId;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.duplicateNote(noteId, copyLabel: l10n.noteCopy);
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.noteCopied,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// حذف الملاحظة — bottom sheet تأكيد مع snackbar تراجع
  Future<void> handleMenuDelete() async {
    final noteId = menuNoteId;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.delete_outline_rounded,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.deleteNote,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;
    await provider.trashNote(noteId);
    if (!mounted) return;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToTrash,
      type: NotificationType.info,
      actionKey: 'menu_delete_$noteId',
      onExecute: () {},
      onUndo: () async => await provider.restoreNote(noteId),
      undoLabel: l10n.undo,
    );
    menuHandleBack();
  }

  /// فتح منتقي الكتالوج
  Future<void> handleMenuCategory() async {
    if (!mounted) return;
    final current = menuCoordinator.stateManager.categoryIds;
    final result = await CategoryPickerSheet.show(
      context,
      current,
      isHiddenFromHome: menuCoordinator.stateManager.isHiddenFromHome,
    );
    if (result != null && mounted) {
      menuSetState(() {
        menuCoordinator.stateManager.categoryIds =
            result['categoryIds'] as List<int>;
        menuCoordinator.stateManager.isHiddenFromHome =
            result['isHiddenFromHome'] as bool;
        menuCoordinator.stateManager.markDirty();
      });
    }
  }
}
