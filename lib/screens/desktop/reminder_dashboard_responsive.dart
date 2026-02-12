// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/selected_note_provider.dart';
import '../../widgets/responsive_layout_wrapper.dart';
import '../../widgets/master_details_layout.dart';
import '../../widgets/details_panel.dart';
import '../shared/tabs/reminder_dashboard.dart';

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
    return ResponsiveLayoutWrapper(
      mobileLayout: const ReminderDashboard(),
      masterDetailsLayout: const MasterDetailsLayout(
        masterPanel: ReminderDashboard(),
        detailsPanel: DetailsPanel(),
      ),
    );
  }
}
