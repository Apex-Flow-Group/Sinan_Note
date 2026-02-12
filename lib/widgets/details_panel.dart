// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_mode.dart';
import '../providers/selected_note_provider.dart';
import '../controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../screens/note_editor.dart';
import 'empty_details_view.dart';

/// Widget يعرض محتوى الملاحظة المختارة في Details Panel
/// 
/// المسؤوليات:
/// - عرض محرر الملاحظة المناسب حسب النوع (نص/checklist/كود)
/// - عرض EmptyDetailsView عند عدم وجود ملاحظة مختارة
/// - الاستماع لتغييرات الملاحظة المختارة من Provider
/// - مسح الاختيار عند حذف/نقل الملاحظة
class DetailsPanel extends StatefulWidget {
  const DetailsPanel({super.key});

  @override
  State<DetailsPanel> createState() => _DetailsPanelState();
}

class _DetailsPanelState extends State<DetailsPanel> {
  NotesProvider? _notesProvider;

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات الملاحظات لمسح الاختيار عند الحذف/النقل
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
  void _checkSelectedNoteStatus() {
    if (!mounted) return;
    
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
      context,
      listen: false,
    );
    final selectedNote = selectedNoteProvider.selectedNote;

    if (selectedNote != null && _notesProvider != null) {
      // البحث عن الملاحظة في القائمة الحالية
      final noteExists = _notesProvider!.notes.any((note) => note.id == selectedNote.id);
      
      if (noteExists) {
        final currentNote = _notesProvider!.notes.firstWhere(
          (note) => note.id == selectedNote.id,
        );
        
        // مسح الاختيار إذا تم حذف/أرشفة/قفل الملاحظة
        if (currentNote.isTrashed || currentNote.isArchived || currentNote.isLocked) {
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

        // حالة عدم وجود ملاحظة مختارة
        if (selectedNote == null) {
          return const EmptyDetailsView();
        }

        // تحديد نوع المحرر حسب نوع الملاحظة
        NoteMode mode;
        
        // استخدام isProfessional كمصدر موثوق أولاً
        if (selectedNote.isProfessional == true) {
          mode = NoteMode.code;
        } else if (selectedNote.isChecklist == true) {
          mode = NoteMode.checklist;
        } else {
          mode = _getNoteMode(selectedNote.noteType);
        }
        
        // Debug: طباعة معلومات الملاحظة
        debugPrint('DetailsPanel: Opening note');
        debugPrint('  - ID: ${selectedNote.id}');
        debugPrint('  - Type: ${selectedNote.noteType}');
        debugPrint('  - Mode: $mode');
        debugPrint('  - isProfessional: ${selectedNote.isProfessional}');
        debugPrint('  - isChecklist: ${selectedNote.isChecklist}');
        debugPrint('  - Content length: ${selectedNote.content.length}');

        // عرض محرر الملاحظة مع معالجة الأخطاء
        try {
          return NoteEditorImmersive(
            mode: mode,
            note: selectedNote,
            onClose: () {
              // في وضع Desktop، مسح الاختيار بدلاً من Navigator.pop
              selectedNoteProvider.clearSelection();
            },
          );
        } catch (e) {
          // في حالة حدوث خطأ، عرض رسالة خطأ
          debugPrint('DetailsPanel Error: $e');
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
      },
    );
  }

  /// تحويل نوع الملاحظة (String) إلى NoteMode
  NoteMode _getNoteMode(String noteType) {
    debugPrint('_getNoteMode: noteType = $noteType');
    
    // تطبيع النوع
    final normalizedType = noteType.toLowerCase().trim();
    
    switch (normalizedType) {
      case 'code':
      case 'professional':
      case 'pro':
        return NoteMode.code;
      case 'checklist':
        return NoteMode.checklist;
      case 'reminder':
        return NoteMode.reminder;
      case 'rich':
        return NoteMode.rich;
      case 'simple':
      default:
        return NoteMode.simple;
    }
  }
}
