// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notes/notes_provider.dart';
import '../controllers/settings/settings_provider.dart';
import '../providers/selected_note_provider.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../widgets/common/custom_share_sheet.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../widgets/master_details_layout.dart';
import '../widgets/master_panel.dart';
import '../widgets/details_panel.dart';
import '../widgets/home/home_drawer_widget.dart';
import '../widgets/home/dialogs/backup_options_dialog.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'home_screen.dart';

/// نسخة Responsive من HomeScreen تدعم نمط Master-Details
/// 
/// على الشاشات الكبيرة (>= 600px):
/// - يعرض Master-Details Layout (قائمة + محتوى)
/// 
/// على الشاشات الصغيرة (< 600px):
/// - يعرض HomeScreen التقليدي
class HomeScreenResponsive extends StatefulWidget {
  final String? sharedText;
  final Function(bool)? onDrawerChanged;

  const HomeScreenResponsive({
    super.key,
    this.sharedText,
    this.onDrawerChanged,
  });

  @override
  State<HomeScreenResponsive> createState() => _HomeScreenResponsiveState();
}

class _HomeScreenResponsiveState extends State<HomeScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // مسح الاختيار عند فتح الشاشة (الانتقال من تبويب آخر)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
        context,
        listen: false,
      );
      selectedNoteProvider.clearSelection();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      // Mobile Layout - الشاشة التقليدية
      mobileLayout: HomeScreen(
        sharedText: widget.sharedText,
        onDrawerChanged: widget.onDrawerChanged,
      ),
      
      // Master-Details Layout - للشاشات الكبيرة
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // Drawer - القائمة الجانبية
      drawer: HomeDrawerWidget(
        onBackupTap: () {
          final tempStrings = {
            'exportBackup': l10n.exportBackup,
            'importBackup': l10n.importBackup,
            'googleDrive': l10n.googleDrive,
            'share': l10n.share,
            'soon': 'قريباً',
          };
          BackupOptionsDialog.show(context, tempStrings);
        },
        onNotesChanged: () {},
      ),
      
      // AppBar مع عنوان التبويب
      appBar: AppBar(
        title: _searchController.text.isEmpty
            ? Text(l10n.myNotes)
            : TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchNotes,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_searchController.text.isEmpty ? Icons.search : Icons.close),
            onPressed: () {
              setState(() {
                if (_searchController.text.isEmpty) {
                  // فتح البحث
                  _searchController.text = ' '; // مسافة لتفعيل وضع البحث
                  _searchController.selection = TextSelection.fromPosition(
                    const TextPosition(offset: 0),
                  );
                } else {
                  // إغلاق البحث
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      
      body: MasterDetailsLayout(
        // Master Panel - قائمة الملاحظات العادية
        masterPanel: Consumer<NotesProvider>(
          builder: (context, notesProvider, child) {
            // الحصول على الملاحظات العادية فقط
            var notes = notesProvider.notes
                .where((note) => !note.isLocked && !note.isArchived && !note.isTrashed)
                .toList();

            // تطبيق البحث
            final searchQuery = _searchController.text.trim();
            if (searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              notes = notes.where((note) {
                return note.title.toLowerCase().contains(query) ||
                    note.content.toLowerCase().contains(query);
              }).toList();
            }

            return MasterPanel(
              notes: notes,
              onNoteSelected: (note) {
                final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
                  context,
                  listen: false,
                );
                selectedNoteProvider.selectNote(note);
              },
              onAddNote: (mode) => _createNewNote(context, mode: mode),
              onNoteContextMenu: _showNoteContextMenu,
            );
          },
        ),
        
        // Details Panel - محتوى الملاحظة المختارة
        detailsPanel: const DetailsPanel(),
      ),
    );
  }

  /// إنشاء ملاحظة جديدة واختيارها تلقائياً
  Future<void> _createNewNote(BuildContext context, {required NoteMode mode}) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);

    // تحديد نوع اللون حسب النوع
    String colorMode = 'simple';
    if (mode == NoteMode.reminder) {
      colorMode = 'reminder';
    } else if (mode == NoteMode.code) {
      colorMode = 'professional';
    } else if (mode == NoteMode.checklist) {
      colorMode = 'checklist';
    } else if (mode == NoteMode.rich) {
      colorMode = 'rich';
    }

    // إنشاء ملاحظة جديدة
    final newNote = Note(
      title: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: settings.getDefaultColorIndex(colorMode),
      noteType: mode.name,
      isChecklist: mode == NoteMode.checklist,
      isProfessional: mode == NoteMode.code,
    );

    // حفظ الملاحظة في قاعدة البيانات
    final noteId = await notesProvider.addOrUpdateNote(newNote, silent: true);
    
    // الحصول على الملاحظة المحفوظة مع ID
    final savedNote = notesProvider.notes.firstWhere(
      (note) => note.id == noteId,
      orElse: () => newNote,
    );

    // اختيار الملاحظة الجديدة في Details Panel
    selectedNoteProvider.selectNote(savedNote);
  }
  
  /// عرض context menu للملاحظة
  void _showNoteContextMenu(Note note, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حفظ كملف - يفتح قائمة المشاركة
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(isArabic ? 'مشاركة' : 'Share'),
            onTap: () {
              Navigator.pop(ctx);
              final shareText = '${note.title}\n\n${note.content}';
              CustomShareSheet.show(
                context, 
                shareText, 
                subject: note.title, 
                note: note,
                onNoteCopied: () async {
                  // إنشاء نسخة من الملاحظة
                  if (note.id != null) {
                    final newNote = Note(
                      title: '${note.title} (نسخة)',
                      content: note.content,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      colorIndex: note.colorIndex,
                      noteType: note.noteType,
                      isProfessional: note.isProfessional,
                      isChecklist: note.isChecklist,
                    );
                    await notesProvider.addOrUpdateNote(newNote);
                  }
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.archive),
            title: Text(l10n.archive),
            onTap: () async {
              Navigator.pop(ctx);
              if (note.id != null) {
                await notesProvider.archiveNote(note.id!);
                // مسح الاختيار إذا كانت الملاحظة مختارة
                if (selectedNoteProvider.selectedNote?.id == note.id) {
                  selectedNoteProvider.clearSelection();
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(l10n.delete),
            onTap: () async {
              Navigator.pop(ctx);
              if (note.id != null) {
                await notesProvider.trashNote(note.id!);
                // مسح الاختيار إذا كانت الملاحظة مختارة
                if (selectedNoteProvider.selectedNote?.id == note.id) {
                  selectedNoteProvider.clearSelection();
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
}
