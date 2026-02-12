// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notes/notes_provider.dart';
import '../providers/selected_note_provider.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../widgets/master_details_layout.dart';
import '../widgets/master_panel.dart';
import '../widgets/details_panel.dart';
import '../widgets/home/home_drawer_widget.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'trash_screen.dart';

/// نسخة Responsive من TrashScreen تدعم نمط Master-Details
class TrashScreenResponsive extends StatefulWidget {
  const TrashScreenResponsive({super.key});

  @override
  State<TrashScreenResponsive> createState() => _TrashScreenResponsiveState();
}

class _TrashScreenResponsiveState extends State<TrashScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // مسح الاختيار عند فتح الشاشة
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
      mobileLayout: const TrashScreen(),
      
      // Master-Details Layout - للشاشات الكبيرة
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      drawer: HomeDrawerWidget(
        onBackupTap: () {},
        onNotesChanged: () {
          if (mounted) {
            setState(() {}); // تحديث القائمة عند تغيير الملاحظات
          }
        },
      ),
      appBar: AppBar(
        title: _searchController.text.isEmpty
            ? Text(l10n.trash)
            : TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchInTrash,
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
                  _searchController.text = ' ';
                  _searchController.selection = TextSelection.fromPosition(
                    const TextPosition(offset: 0),
                  );
                } else {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: MasterDetailsLayout(
        // Master Panel - قائمة الملاحظات المحذوفة
        masterPanel: Consumer<NotesProvider>(
          builder: (context, notesProvider, child) {
            // الحصول على الملاحظات المحذوفة فقط
            var notes = notesProvider.trashedNotes;

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
            );
          },
        ),
        
        // Details Panel - محتوى الملاحظة المختارة
        detailsPanel: const DetailsPanel(),
      ),
    );
  }
}
