// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/shared/note_editor.dart';
import 'package:sinan_note/widgets/empty_details_view.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

/// Details Panel مخصص للخزنة — يعرض الملاحظة المقفلة المختارة.
///
/// الفروق عن [DetailsPanel] الأصلي:
/// 1. لا يمسح الاختيار بسبب [Note.isLocked] (كل ملاحظات الخزنة مقفلة).
/// 2. يمرر [skipAuthentication: true] لأن الملاحظة فُكَّ تشفيرها مسبقاً.
/// 3. لا يستمع لـ [NotesProvider] لأن الملاحظات المفككة تُدار بواسطة
///    [LockedNotesScreen] مباشرة — نعتمد فقط على [SelectedNoteProvider].
class VaultDetailsPanel extends StatefulWidget {
  const VaultDetailsPanel({super.key});

  @override
  State<VaultDetailsPanel> createState() => _VaultDetailsPanelState();
}

class _VaultDetailsPanelState extends State<VaultDetailsPanel> {
  int? _currentNoteId;

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedNoteProvider>(
      builder: (context, selectedNoteProvider, _) {
        final selectedNote = selectedNoteProvider.selectedNote;

        if (selectedNote == null) {
          return const EmptyDetailsView();
        }

        if (_currentNoteId != selectedNote.id) {
          _currentNoteId = selectedNote.id;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          ),
          child: _buildEditorView(context, selectedNote, selectedNoteProvider),
        );
      },
    );
  }

  Widget _buildEditorView(
    BuildContext context,
    Note selectedNote,
    SelectedNoteProvider selectedNoteProvider,
  ) {
    final NoteMode mode = NoteCardUtils.getNoteMode(selectedNote);
    try {
      final displayNote = selectedNote.isLocked
          ? selectedNote.copyWith(isLocked: false)
          : selectedNote;
      final isExistingNote = selectedNote.id != null;

      return NoteEditorImmersive(
        key: ValueKey('vault_editor_${selectedNote.id}'),
        mode: mode,
        note: displayNote,
        skipAuthentication: true,
        originallyLocked: true,
        readOnly: isExistingNote,
        onClose: () => selectedNoteProvider.clearSelection(),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              l10n.errorOpeningNote,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => selectedNoteProvider.clearSelection(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }
  }
}
