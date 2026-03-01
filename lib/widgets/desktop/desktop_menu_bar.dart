// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/shortcuts/app_shortcuts.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:flutter/material.dart';

class DesktopMenuBar extends StatelessWidget {
  final void Function(NoteMode) onNewNote;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onAbout;

  const DesktopMenuBar({
    super.key,
    required this.onNewNote,
    required this.onSearch,
    required this.onRefresh,
    required this.onSettings,
    required this.onExport,
    required this.onImport,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MenuBar(
      children: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: AppShortcuts.newNote,
              leadingIcon: const Icon(Icons.note_add, size: 16),
              onPressed: () => onNewNote(NoteMode.simple),
              child: Text(l10n.simpleNote),
            ),
            MenuItemButton(
              shortcut: AppShortcuts.codeNote,
              leadingIcon: const Icon(Icons.code, size: 16),
              onPressed: () => onNewNote(NoteMode.code),
              child: Text(l10n.codeNote),
            ),
            MenuItemButton(
              shortcut: AppShortcuts.checklist,
              leadingIcon: const Icon(Icons.checklist, size: 16),
              onPressed: () => onNewNote(NoteMode.checklist),
              child: Text(l10n.checklist),
            ),
            MenuItemButton(
              shortcut: AppShortcuts.reminder,
              leadingIcon: const Icon(Icons.alarm, size: 16),
              onPressed: () => onNewNote(NoteMode.reminder),
              child: Text(l10n.reminder),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: const Icon(Icons.upload_file, size: 16),
              onPressed: onExport,
              child: Text(l10n.exportBackup),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.download, size: 16),
              onPressed: onImport,
              child: Text(l10n.importBackup),
            ),
          ],
          child: Text(l10n.file),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: AppShortcuts.search,
              leadingIcon: const Icon(Icons.search, size: 16),
              onPressed: onSearch,
              child: Text(l10n.searchNotes),
            ),
            MenuItemButton(
              shortcut: AppShortcuts.refresh,
              leadingIcon: const Icon(Icons.refresh, size: 16),
              onPressed: onRefresh,
              child: Text(l10n.refresh),
            ),
          ],
          child: Text(l10n.edit),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.settings, size: 16),
              onPressed: onSettings,
              child: Text(l10n.settings),
            ),
          ],
          child: Text(l10n.view),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.info_outline, size: 16),
              onPressed: onAbout,
              child: Text(l10n.about),
            ),
          ],
          child: Text(l10n.help),
        ),
      ],
    );
  }
}
