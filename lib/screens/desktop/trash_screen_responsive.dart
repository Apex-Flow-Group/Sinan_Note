// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/trash_screen.dart';
import 'package:apex_note/widgets/details_panel.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/master_details_layout.dart';
import 'package:apex_note/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      drawer: HomeDrawerWidget(
        onBackupTap: () {},
        onNotesChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
      body: const MasterDetailsLayout(
        masterPanel: TrashScreen(),
        detailsPanel: DetailsPanel(),
      ),
    );
  }
}
