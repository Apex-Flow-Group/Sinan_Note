// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/archive_screen.dart';
import 'package:apex_note/widgets/details_panel.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/master_details_layout.dart';
import 'package:apex_note/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArchiveScreenResponsive extends StatefulWidget {
  const ArchiveScreenResponsive({super.key});

  @override
  State<ArchiveScreenResponsive> createState() => _ArchiveScreenResponsiveState();
}

class _ArchiveScreenResponsiveState extends State<ArchiveScreenResponsive> {
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectedNoteProvider?.clearSelection();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedNoteProvider?.clearSelection();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      mobileLayout: const ArchiveScreen(),
      masterDetailsLayout: Scaffold(
        drawer: HomeDrawerWidget(onBackupTap: () {}, onNotesChanged: () {}),
        body: const MasterDetailsLayout(
          masterPanel: ArchiveScreen(),
          detailsPanel: DetailsPanel(),
        ),
      ),
    );
  }
}
