// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/core/shortcuts/app_shortcuts.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/other/about_screen.dart';
import 'package:sinan_note/screens/shared/backup_wizard_screen.dart';
import 'package:sinan_note/services/keyboard/editor_command_bus.dart';
import 'package:sinan_note/widgets/common/app_dialog.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

class DesktopMenuBar extends StatelessWidget {
  final void Function(NoteMode) onNewNote;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  const DesktopMenuBar({
    super.key,
    required this.onNewNote,
    required this.onSearch,
    required this.onRefresh,
    required this.onSettings,
  });

  /// هل الملاحظة المفتوحة تدعم تنسيق النص (Bold/Italic/...)
  static bool _supportsFormatting(Note? note) {
    if (note == null) return false;
    final mode = NoteCardUtils.getNoteMode(note);
    return mode == NoteMode.rich;
  }

  /// هل توجد ملاحظة مفتوحة في Details Panel
  static bool _hasOpenNote(Note? note) => note != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // نستمع لـ SelectedNoteProvider لتحديث القائمة عند تغيير الملاحظة
    return Consumer<SelectedNoteProvider>(
      builder: (context, selectedNoteProvider, _) {
        final selectedNote = selectedNoteProvider.selectedNote;
        final hasNote = _hasOpenNote(selectedNote);
        final supportsFormatting = _supportsFormatting(selectedNote);

        return MenuBar(
          children: [
            // ── File ────────────────────────────────────────────────
            SubmenuButton(
              menuChildren: [
                MenuItemButton(
                  shortcut: AppShortcuts.newNote,
                  leadingIcon: const Icon(Icons.note_outlined, size: 16),
                  onPressed: () => onNewNote(NoteMode.simple),
                  child: Text(l10n.simpleNote),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.richNote,
                  leadingIcon: const Icon(Icons.text_fields_rounded, size: 16),
                  onPressed: () => onNewNote(NoteMode.rich),
                  child: Text(l10n.richNoteMenu),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.codeNote,
                  leadingIcon: const Icon(Icons.code_rounded, size: 16),
                  onPressed: () => onNewNote(NoteMode.code),
                  child: Text(l10n.codeNote),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.checklist,
                  leadingIcon: const Icon(Icons.checklist_rounded, size: 16),
                  onPressed: () => onNewNote(NoteMode.checklist),
                  child: Text(l10n.checklist),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.reminder,
                  leadingIcon: const Icon(Icons.alarm_rounded, size: 16),
                  onPressed: () => onNewNote(NoteMode.reminder),
                  child: Text(l10n.reminder),
                ),
                const Divider(),
                // حفظ — يعمل فقط عند وجود ملاحظة مفتوحة
                MenuItemButton(
                  shortcut: AppShortcuts.save,
                  leadingIcon: const Icon(Icons.save_outlined, size: 16),
                  onPressed:
                      hasNote ? null : null, // ShortcutScope يتولى التنفيذ
                  child: Text(l10n.save),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.saveAs,
                  leadingIcon: const Icon(Icons.save_as_outlined, size: 16),
                  onPressed: null,
                  child: Text(l10n.saveAs),
                ),
                const Divider(),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.backup_outlined, size: 16),
                  onPressed: () =>
                      AppDialog.show(context, const BackupWizardScreen()),
                  child: Text('${l10n.exportBackup} & ${l10n.restore}'),
                ),
                // إغلاق العارض — يظهر فقط عند وجود ملاحظة مفتوحة
                if (hasNote)
                  MenuItemButton(
                    shortcut: AppShortcuts.close,
                    leadingIcon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => selectedNoteProvider.clearSelection(),
                    child: Text(l10n.close),
                  ),
              ],
              child: Text(l10n.file),
            ),

            // ── Edit ────────────────────────────────────────────────
            SubmenuButton(
              menuChildren: [
                // تراجع/إعادة — يعملان عبر EditorCommandBus
                MenuItemButton(
                  shortcut: AppShortcuts.undo,
                  leadingIcon: const Icon(Icons.undo_rounded, size: 16),
                  onPressed: () => EditorCommandBus().triggerUndo(),
                  child: Text(l10n.undo),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.redo,
                  leadingIcon: const Icon(Icons.redo_rounded, size: 16),
                  onPressed: () => EditorCommandBus().triggerRedo(),
                  child: Text(l10n.redo),
                ),

                // تنسيق النص — يظهر فقط لـ Rich
                if (supportsFormatting) ...[
                  const Divider(),
                  MenuItemButton(
                    shortcut: AppShortcuts.bold,
                    leadingIcon:
                        const Icon(Icons.format_bold_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerBold(),
                    child: Text(l10n.bold),
                  ),
                  MenuItemButton(
                    shortcut: AppShortcuts.italic,
                    leadingIcon:
                        const Icon(Icons.format_italic_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerItalic(),
                    child: Text(l10n.italic),
                  ),
                  MenuItemButton(
                    shortcut: AppShortcuts.underline,
                    leadingIcon:
                        const Icon(Icons.format_underline_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerUnderline(),
                    child: Text(l10n.underline),
                  ),
                  MenuItemButton(
                    shortcut: AppShortcuts.strikethrough,
                    leadingIcon: const Icon(Icons.format_strikethrough_rounded,
                        size: 16),
                    onPressed: () => EditorCommandBus().triggerStrikethrough(),
                    child: Text(l10n.strikethrough),
                  ),
                ],

                const Divider(),
                // إعادة تسمية — تعمل فقط عند وجود ملاحظة مفتوحة
                MenuItemButton(
                  shortcut: AppShortcuts.rename,
                  leadingIcon:
                      const Icon(Icons.drive_file_rename_outline, size: 16),
                  onPressed:
                      hasNote ? () => EditorCommandBus().triggerRename() : null,
                  child: Text(l10n.rename),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.search,
                  leadingIcon: const Icon(Icons.search_rounded, size: 16),
                  onPressed: onSearch,
                  child: Text(l10n.searchNotes),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.selectAll,
                  leadingIcon: const Icon(Icons.select_all_rounded, size: 16),
                  onPressed: null,
                  child: Text(l10n.selectAll),
                ),
              ],
              child: Text(l10n.edit),
            ),

            // ── Note ────────────────────────────────────────────────
            // يظهر فقط عند وجود ملاحظة مفتوحة
            if (hasNote)
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    shortcut: AppShortcuts.archive,
                    leadingIcon:
                        const Icon(Icons.inventory_2_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerArchive(),
                    child: Text(l10n.archive),
                  ),
                  MenuItemButton(
                    shortcut: AppShortcuts.pin,
                    leadingIcon: const Icon(Icons.push_pin_outlined, size: 16),
                    onPressed: () => EditorCommandBus().triggerPin(),
                    child: Text(l10n.pin),
                  ),
                  MenuItemButton(
                    leadingIcon:
                        const Icon(Icons.label_outline_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerCategory(),
                    child: Text(l10n.categories),
                  ),
                  MenuItemButton(
                    shortcut: AppShortcuts.duplicate,
                    leadingIcon: const Icon(Icons.copy_outlined, size: 16),
                    onPressed: () => EditorCommandBus().triggerDuplicate(),
                    child: Text(l10n.duplicate),
                  ),
                  const Divider(),
                  MenuItemButton(
                    shortcut: AppShortcuts.delete,
                    leadingIcon:
                        const Icon(Icons.delete_outline_rounded, size: 16),
                    onPressed: () => EditorCommandBus().triggerDelete(),
                    child: Text(l10n.delete),
                  ),
                ],
                child: Text(l10n.note),
              ),

            // ── View ────────────────────────────────────────────────
            SubmenuButton(
              menuChildren: [
                MenuItemButton(
                  shortcut: AppShortcuts.refresh,
                  leadingIcon: const Icon(Icons.refresh_rounded, size: 16),
                  onPressed: onRefresh,
                  child: Text(l10n.refresh),
                ),
                MenuItemButton(
                  shortcut: AppShortcuts.toggleView,
                  leadingIcon: const Icon(Icons.view_list_rounded, size: 16),
                  onPressed: null,
                  child: Text(l10n.toggleView),
                ),
                const Divider(),
                MenuItemButton(
                  shortcut: AppShortcuts.settings,
                  leadingIcon: const Icon(Icons.settings_outlined, size: 16),
                  onPressed: onSettings,
                  child: Text(l10n.settings),
                ),
              ],
              child: Text(l10n.view),
            ),

            // ── Help ────────────────────────────────────────────────
            SubmenuButton(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.info_outline_rounded, size: 16),
                  onPressed: () => AppDialog.show(context, const AboutScreen()),
                  child: Text(l10n.about),
                ),
              ],
              child: Text(l10n.help),
            ),
          ],
        );
      },
    );
  }
}
