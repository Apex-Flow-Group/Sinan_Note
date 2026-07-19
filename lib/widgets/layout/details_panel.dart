// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';
import 'package:sinan_note/widgets/layout/empty_details_view.dart';

/// Widget يعرض محتوى الملاحظة المختارة في Details Panel
///
/// المسؤوليات:
/// - عرض محرر الملاحظة المناسب حسب النوع (نص/checklist/كود)
/// - عرض EmptyDetailsView عند عدم وجود ملاحظة مختارة
/// - الاستماع لتغييرات الملاحظة المختارة من Provider
/// - مسح الاختيار عند حذف/نقل الملاحظة
class DetailsPanel extends StatefulWidget {
  final bool forceEditMode;
  final Set<int> selectedIds;
  final VoidCallback? onClearSelection;

  const DetailsPanel({
    super.key,
    this.forceEditMode = false,
    this.selectedIds = const {},
    this.onClearSelection,
  });

  @override
  State<DetailsPanel> createState() => _DetailsPanelState();
}

class _DetailsPanelState extends State<DetailsPanel> {
  NotesProvider? _notesProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notesProvider = Provider.of<NotesProvider>(context, listen: false);
        _notesProvider?.addListener(_checkSelectedNoteStatus);
      }
    });
  }

  @override
  void dispose() {
    // إزالة الـ listener بشكل آمن
    _notesProvider?.removeListener(_checkSelectedNoteStatus);
    super.dispose();
  }

  /// التحقق من حالة الملاحظة المختارة ومسح الاختيار إذا تم حذفها/نقلها
  /// وتحديث الملاحظة المختارة إذا تغيّرت بياناتها (مثل اللون)
  void _checkSelectedNoteStatus() {
    if (!mounted) return;
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
      context,
      listen: false,
    );
    final selectedNote = selectedNoteProvider.selectedNote;

    if (selectedNote != null && _notesProvider != null) {
      // البحث عن الملاحظة في القائمة الحالية
      final noteExists =
          _notesProvider!.notes.any((note) => note.id == selectedNote.id);

      if (noteExists) {
        final currentNote = _notesProvider!.notes.firstWhere(
          (note) => note.id == selectedNote.id,
        );

        // مسح الاختيار إذا تم أرشفة/قفل الملاحظة — لكن السلة تُعرض بوضع القراءة
        if (currentNote.isArchived || currentNote.isLocked) {
          selectedNoteProvider.clearSelection();
        }
      } else {
        // الملاحظة لم تعد موجودة - مسح الاختيار
        selectedNoteProvider.clearSelection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedNoteProvider>(
      builder: (context, selectedNoteProvider, child) {
        final selectedNote = selectedNoteProvider.selectedNote;

        if (selectedNote == null) {
          return const EmptyDetailsView();
        }

        return _buildEditorView(context, selectedNote, selectedNoteProvider);
      },
    );
  }

  Widget _buildEditorView(BuildContext context, Note selectedNote,
      SelectedNoteProvider selectedNoteProvider) {
    final NoteMode mode = NoteCardUtils.getNoteMode(selectedNote);

    try {
      return NoteEditorImmersive(
        key: ValueKey('editor_${selectedNote.id}'),
        mode: mode,
        note: selectedNote,
        readOnly: selectedNote.id != null &&
            (selectedNote.isTrashed ||
                selectedNote.title.isNotEmpty ||
                selectedNote.content.isNotEmpty),
        onClose: () {
          selectedNoteProvider.clearSelection();
        },
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorOpeningNote,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.noteType}: ${selectedNote.noteType}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                selectedNoteProvider.clearSelection();
              },
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }
  }
}
