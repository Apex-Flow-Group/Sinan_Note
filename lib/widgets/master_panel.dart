// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../providers/selected_note_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'note_list_tile.dart';

/// Widget يعرض قائمة الملاحظات في Master Panel
/// 
/// المسؤوليات:
/// - عرض قائمة الملاحظات في ListView قابل للتمرير
/// - تمييز الملاحظة المختارة بصرياً
/// - معالجة حدث النقر على ملاحظة لاختيارها
/// - عرض رسالة عند عدم وجود ملاحظات
/// - عرض AppBar اختياري في الأعلى
/// - عرض زر إضافة اختياري
class MasterPanel extends StatelessWidget {
  /// قائمة الملاحظات المراد عرضها
  final List<Note> notes;
  
  /// دالة تُستدعى عند اختيار ملاحظة
  final Function(Note) onNoteSelected;
  
  /// دالة تُستدعى عند فتح context menu لملاحظة (اختياري)
  final Function(Note, BuildContext)? onNoteContextMenu;
  
  /// عنوان AppBar (اختياري)
  final String? appBarTitle;
  
  /// أيقونة AppBar (اختياري)
  final IconData? appBarIcon;
  
  /// دالة تُستدعى عند الضغط على زر الإضافة (اختياري)
  final VoidCallback? onAddPressed;
  
  /// دالة تُستدعى عند اختيار نوع ملاحظة جديدة (اختياري)
  final Function(NoteMode)? onAddNote;

  const MasterPanel({
    super.key,
    required this.notes,
    required this.onNoteSelected,
    this.appBarTitle,
    this.appBarIcon,
    this.onAddPressed,
    this.onAddNote,
    this.onNoteContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final content = notes.isEmpty
        ? _buildEmptyState(l10n)
        : _buildNotesList();
    
    // إذا كان هناك عنوان AppBar، نعرض Column مع AppBar
    if (appBarTitle != null) {
      return Column(
        children: [
          _buildAppBar(context),
          Expanded(child: content),
        ],
      );
    }
    
    // إذا كان هناك زر إضافة، نعرض Stack مع FAB
    if (onAddPressed != null || onAddNote != null) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 16,
            right: 16,
            child: onAddNote != null
                ? _buildAddNoteMenu(context)
                : FloatingActionButton(
                    onPressed: onAddPressed,
                    child: const Icon(Icons.add),
                  ),
          ),
        ],
      );
    }
    
    // بدون AppBar أو FAB، نعرض المحتوى مباشرة
    return content;
  }
  
  /// بناء AppBar للـ Master Panel
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor ?? 
               Theme.of(context).primaryColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (appBarIcon != null) ...[
                Icon(
                  appBarIcon,
                  color: Theme.of(context).appBarTheme.iconTheme?.color ??
                         Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  appBarTitle!,
                  style: Theme.of(context).appBarTheme.titleTextStyle ??
                         Theme.of(context).textTheme.titleLarge?.copyWith(
                           color: Theme.of(context).colorScheme.onPrimary,
                         ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// بناء حالة القائمة الفارغة
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noNotes,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  /// بناء قائمة الملاحظات
  Widget _buildNotesList() {
    return Consumer<SelectedNoteProvider>(
      builder: (context, selectedNoteProvider, child) {
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = selectedNoteProvider.isNoteSelected(note.id);

            return NoteListTile(
              note: note,
              isSelected: isSelected,
              onTap: () => onNoteSelected(note),
              onContextMenu: onNoteContextMenu != null
                  ? () => onNoteContextMenu!(note, context)
                  : null,
            );
          },
        );
      },
    );
  }
  
  /// بناء قائمة إضافة ملاحظة جديدة
  Widget _buildAddNoteMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.note_outlined, color: colorScheme.outline),
                  title: Text(l10n.simpleNoteMenu),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAddNote!(NoteMode.simple);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.format_paint_rounded, color: colorScheme.primary),
                  title: Text(l10n.richNoteMenu),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAddNote!(NoteMode.rich);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.code_rounded, color: colorScheme.secondary),
                  title: Text(l10n.codeEditorMenu),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAddNote!(NoteMode.code);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.checklist_rounded, color: colorScheme.tertiary),
                  title: Text(l10n.checklistMenu),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAddNote!(NoteMode.checklist);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
