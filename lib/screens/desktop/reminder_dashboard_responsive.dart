// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/shared/tabs/reminder_dashboard.dart';
import 'package:sinan_note/widgets/details_panel.dart';
import 'package:sinan_note/widgets/master_details_layout.dart';
import 'package:sinan_note/widgets/responsive_layout_wrapper.dart';

class ReminderDashboardResponsive extends StatefulWidget {
  const ReminderDashboardResponsive({super.key});

  @override
  State<ReminderDashboardResponsive> createState() => _ReminderDashboardResponsiveState();
}

class _ReminderDashboardResponsiveState extends State<ReminderDashboardResponsive> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedNoteProvider = Provider.of<SelectedNoteProvider>(
        context,
        listen: false,
      );
      selectedNoteProvider.clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayoutWrapper(
      mobileLayout: ReminderDashboard(),
      masterDetailsLayout: MasterDetailsLayout(
        masterPanel: ReminderDashboard(),
        detailsPanel: DetailsPanel(),
      ),
    );
  }
}

