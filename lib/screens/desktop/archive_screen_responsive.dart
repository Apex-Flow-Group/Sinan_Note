// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/archive_screen.dart';
import 'package:apex_note/widgets/details_panel.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/master_details_layout.dart';
import 'package:apex_note/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// نسخة Responsive من ArchiveScreen تدعم نمط Master-Details
class ArchiveScreenResponsive extends StatefulWidget {
  const ArchiveScreenResponsive({super.key});

  @override
  State<ArchiveScreenResponsive> createState() =>
      _ArchiveScreenResponsiveState();
}

class _ArchiveScreenResponsiveState extends State<ArchiveScreenResponsive> {
  final TextEditingController _searchController = TextEditingController();
  final bool _isEditMode = false;

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
      mobileLayout: const ArchiveScreen(),

      // Master-Details Layout - للشاشات الكبيرة
      masterDetailsLayout: _buildMasterDetailsLayout(context),
    );
  }

  Widget _buildMasterDetailsLayout(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawerWidget(
        onBackupTap: () {},
        onNotesChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
      body: MasterDetailsLayout(
        masterPanel: const ArchiveScreen(),
        detailsPanel: DetailsPanel(forceEditMode: _isEditMode),
      ),
    );
  }
}
