// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/selected_note_provider.dart';
import '../../widgets/responsive_layout_wrapper.dart';
import '../../widgets/master_details_layout.dart';
import '../../widgets/details_panel.dart';
import '../shared/tabs/code_tab.dart';

class CodeTabResponsive extends StatefulWidget {
  const CodeTabResponsive({super.key});

  @override
  State<CodeTabResponsive> createState() => _CodeTabResponsiveState();
}

class _CodeTabResponsiveState extends State<CodeTabResponsive> {
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
      mobileLayout: const CodeTab(),
      masterDetailsLayout: const MasterDetailsLayout(
        masterPanel: CodeTab(),
        detailsPanel: DetailsPanel(),
      ),
    );
  }
}
