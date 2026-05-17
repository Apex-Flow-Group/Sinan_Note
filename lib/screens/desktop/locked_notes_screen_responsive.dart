// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/widgets/details_panel.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/master_details_layout.dart';
import 'package:apex_note/widgets/master_panel.dart';
import 'package:apex_note/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// نسخة Responsive من LockedNotesScreen تدعم نمط Master-Details
class LockedNotesScreenResponsive extends StatefulWidget {
  const LockedNotesScreenResponsive({super.key});

  @override
  State<LockedNotesScreenResponsive> createState() =>
      _LockedNotesScreenResponsiveState();
}

class _LockedNotesScreenResponsiveState
    extends State<LockedNotesScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

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

      // جلب الملاحظات المقفلة المفككة للعرض في desktop
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.fetchLockedNotes();
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
      mobileLayout: const LockedNotesScreen(),

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
        title: !_isSearchActive
            ? Text(l10n.locked)
            : TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchInVault,
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
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_searchController.text.isEmpty) {
                  _searchController.text = '';
                  _isSearchActive = true;
                } else {
                  _searchController.clear();
                  _isSearchActive = false;
                }
              });
            },
          ),
        ],
      ),
      body: MasterDetailsLayout(
        // Master Panel - قائمة الملاحظات المقفلة
        masterPanel: Consumer<NotesProvider>(
          builder: (context, notesProvider, child) {
            // lockedNotes تحتوي على الملاحظات المفككة بعد fetchLockedNotes()
            // بخلاف notes (activeNotes) التي تحتوي محتوى مشفر
            var notes = notesProvider.lockedNotes
                .where((note) => !note.isTrashed)
                .toList();

            // تطبيق البحث
            final searchQuery = _searchController.text.trim();
            if (searchQuery.isNotEmpty) {
              final q = Note.normalize(searchQuery);
              notes = notes.where((note) {
                return note.normalizedTitle.contains(q) ||
                    note.normalizedContent.contains(q);
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
