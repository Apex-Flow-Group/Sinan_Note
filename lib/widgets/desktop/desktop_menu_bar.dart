// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/shortcuts/app_shortcuts.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/other/about_screen.dart';
import 'package:apex_note/screens/shared/backup_wizard_screen.dart';
import 'package:apex_note/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MenuBar(
      children: [
        // ── File ──────────────────────────────────────────────────
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: AppShortcuts.newNote,
              leadingIcon: const Icon(Icons.note_outlined, size: 16),
              onPressed: () => onNewNote(NoteMode.simple),
              child: Text(l10n.simpleNote),
            ),
            MenuItemButton(
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
            const Divider(),
            MenuItemButton(
              leadingIcon: const Icon(Icons.backup_outlined, size: 16),
              onPressed: () =>
                  AppDialog.show(context, const BackupWizardScreen()),
              child: Text('${l10n.exportBackup} & ${l10n.restore}'),
            ),
            // إغلاق العارض إذا كان مفتوحاً
            Consumer<SelectedNoteProvider>(
              builder: (context, selectedNote, _) {
                if (selectedNote.selectedNote == null) {
                  return const SizedBox.shrink();
                }
                return MenuItemButton(
                  leadingIcon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => selectedNote.clearSelection(),
                  child: Text(l10n.close),
                );
              },
            ),
          ],
          child: Text(l10n.file),
        ),

        // ── Edit ──────────────────────────────────────────────────
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: AppShortcuts.search,
              leadingIcon: const Icon(Icons.search_rounded, size: 16),
              onPressed: onSearch,
              child: Text(l10n.searchNotes),
            ),
            MenuItemButton(
              shortcut: AppShortcuts.refresh,
              leadingIcon: const Icon(Icons.refresh_rounded, size: 16),
              onPressed: onRefresh,
              child: Text(l10n.refresh),
            ),
          ],
          child: Text(l10n.edit),
        ),

        // ── View ──────────────────────────────────────────────────
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.settings_outlined, size: 16),
              onPressed: onSettings,
              child: Text(l10n.settings),
            ),
          ],
          child: Text(l10n.view),
        ),

        // ── Help ──────────────────────────────────────────────────
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
  }
}
