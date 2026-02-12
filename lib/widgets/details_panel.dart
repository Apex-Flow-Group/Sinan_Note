// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../providers/selected_note_provider.dart';
import '../controllers/notes/notes_provider.dart';
import '../core/utils/adaptive_color.dart';
import '../core/utils/checklist_formatter.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../screens/shared/note_editor.dart';
import 'empty_details_view.dart';

/// Widget يعرض محتوى الملاحظة المختارة في Details Panel
/// 
/// المسؤوليات:
/// - عرض محرر الملاحظة المناسب حسب النوع (نص/checklist/كود)
/// - عرض EmptyDetailsView عند عدم وجود ملاحظة مختارة
/// - الاستماع لتغييرات الملاحظة المختارة من Provider
/// - مسح الاختيار عند حذف/نقل الملاحظة
class DetailsPanel extends StatefulWidget {
  final bool forceEditMode; // 🔥 فرض وضع التعديل
  
  const DetailsPanel({
    super.key,
    this.forceEditMode = false,
  });

  @override
  State<DetailsPanel> createState() => _DetailsPanelState();
}

class _DetailsPanelState extends State<DetailsPanel> {
  NotesProvider? _notesProvider;
  bool _isEditMode = false;
  int? _currentNoteId;

  void setEditMode(bool value) {
    if (mounted) {
      setState(() {
        _isEditMode = value;
      });
    }
  }

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

        if (selectedNote == null) {
          return const EmptyDetailsView();
        }

        // 🔥 إعادة تعيين وضع التعديل فقط عند تغيير الملاحظة
        if (_currentNoteId != selectedNote.id) {
          _currentNoteId = selectedNote.id;
          _isEditMode = false;
        }

        final isDesktop = MediaQuery.of(context).size.width >= 600;
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: (isDesktop && !widget.forceEditMode && !_isEditMode)
              ? _buildReadOnlyView(context, selectedNote, selectedNoteProvider)
              : _buildEditorView(context, selectedNote, selectedNoteProvider),
        );
      },
    );
  }

  Widget _buildEditorView(BuildContext context, Note selectedNote, SelectedNoteProvider selectedNoteProvider) {
    // تحديد نوع المحرر حسب نوع الملاحظة
    NoteMode mode;
    
    if (selectedNote.isProfessional == true) {
      mode = NoteMode.code;
    } else if (selectedNote.isChecklist == true) {
      mode = NoteMode.checklist;
    } else {
      mode = _getNoteMode(selectedNote.noteType);
    }

    try {
      return NoteEditorImmersive(
        key: ValueKey('editor_${selectedNote.id}'),
        mode: mode,
        note: selectedNote,
        onClose: () {
          selectedNoteProvider.clearSelection();
        },
      );
    } catch (e) {
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
  }

  /// وضع العرض لسطح المكتب - بنفس خلفية النوت
  Widget _buildReadOnlyView(BuildContext context, Note note, SelectedNoteProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    
    final baseColor = AppColorPalette.palette[note.colorIndex].getColor(brightness);
    final textColor = baseColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    
    return Scaffold(
      key: const ValueKey('readonly_view'),
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          if (note.isArchived) ...[
            IconButton(
              icon: const Icon(Icons.unarchive_rounded),
              tooltip: l10n.unarchive,
              onPressed: () async {
                final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                if (note.id != null) {
                  await notesProvider.unarchiveNote(note.id!);
                  provider.clearSelection();
                }
              },
            ),
          ] else if (note.isTrashed) ...[
            IconButton(
              icon: const Icon(Icons.restore_rounded, color: Colors.green),
              tooltip: l10n.restore,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.restore),
                    content: Text('${l10n.restore}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                        child: Text(l10n.restore),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && note.id != null) {
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.restoreNote(note.id!);
                  provider.clearSelection();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              tooltip: l10n.permanentDelete,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.permanentDelete),
                    content: Text(l10n.confirmPermanentDelete),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && note.id != null) {
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.deleteNote(note.id!);
                  provider.clearSelection();
                }
              },
            ),
          ],
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () {
          if (!note.isArchived && !note.isTrashed) {
            setState(() {
              _isEditMode = true;
            });
          }
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: textColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                  ],
                  note.isChecklist
                      ? _buildChecklistView(note.content, textColor)
                      : SelectableText(
                          note.content.isEmpty ? l10n.noNotes : note.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// عرض Checklist منسق - نفس تنسيق الموبايل
  Widget _buildChecklistView(String content, Color textColor) {
    final items = ChecklistFormatter.parseJson(content);
    
    if (items.isEmpty) {
      return Text(
        'Empty checklist',
        style: TextStyle(color: textColor.withValues(alpha: 0.6)),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.isDone ? '☑' : '☐', // ☑ ☐
                style: TextStyle(
                  fontSize: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
