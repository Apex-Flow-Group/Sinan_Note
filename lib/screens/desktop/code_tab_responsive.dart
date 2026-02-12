// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/responsive_layout_wrapper.dart';
import '../../widgets/master_details_layout.dart';
import '../../widgets/details_panel.dart';
import '../shared/tabs/code_tab.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../providers/selected_note_provider.dart';
import '../../widgets/note_list_tile.dart';
import '../../widgets/home/add_menu_widget.dart';
import '../../models/note_mode.dart';
import '../../models/note.dart';
import '../shared/note_editor.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

class CodeTabResponsive extends StatelessWidget {
  const CodeTabResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      mobileLayout: const CodeTab(),
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    return MasterDetailsLayout(
      masterPanel: _buildMasterPanel(context),
      detailsPanel: const DetailsPanel(),
    );
  }

  Widget _buildMasterPanel(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_rounded, size: 22),
            const SizedBox(width: 8),
            Text(strings.professional),
          ],
        ),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          final professionalNotes = notesProvider.notes
              .where((note) =>
                  note.isProfessional &&
                  !note.isArchived &&
                  !note.isTrashed)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (professionalNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    strings.noProfessionalNotes,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: professionalNotes.length,
                itemBuilder: (context, index) {
                  final note = professionalNotes[index];
                  return Consumer<SelectedNoteProvider>(
                    builder: (context, selectedNoteProvider, _) {
                      final isSelected = selectedNoteProvider.isNoteSelected(note.id);
                      return NoteListTile(
                        note: note,
                        isSelected: isSelected,
                        onTap: () => selectedNoteProvider.selectNote(note),
                      );
                    },
                  );
                },
              ),
              _buildAddMenu(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool showMenu = false;
        
        return AddMenuWidget(
          showMenu: showMenu,
          onToggle: () => setState(() => showMenu = !showMenu),
          onModeSelected: (mode) async {
            setState(() => showMenu = false);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorImmersive(
                  mode: mode,
                  note: Note(
                    title: '',
                    content: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    colorIndex: 0,
                    noteType: mode.name,
                    isChecklist: mode == NoteMode.checklist,
                    isProfessional: mode == NoteMode.code,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
