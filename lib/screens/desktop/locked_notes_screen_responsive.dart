// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/mobile/locked_notes_screen.dart';
import 'package:sinan_note/widgets/master_details_layout.dart';
import 'package:sinan_note/widgets/vault_details_panel.dart';

/// نسخة Responsive من LockedNotesScreen تدعم نمط Master-Details على Desktop.
///
/// - Mobile  → [LockedNotesScreen] كما هو (بدون تغيير)
/// - Desktop → [LockedNotesScreen] كـ Master Panel + [VaultDetailsPanel] كـ Details Panel
///
/// ملاحظة: الخزنة تستخدم SearchableHeader + Drawer داخلياً بالفعل —
/// هنا نلفّها فقط بـ MasterDetailsLayout مع VaultDetailsPanel.
/// لا نعيد كتابتها لأنها تحتوي منطق تشفير وأمان حساس.
class LockedNotesScreenResponsive extends StatefulWidget {
  const LockedNotesScreenResponsive({super.key});

  @override
  State<LockedNotesScreenResponsive> createState() =>
      _LockedNotesScreenResponsiveState();
}

class _LockedNotesScreenResponsiveState
    extends State<LockedNotesScreenResponsive> {
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
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
    if (!PlatformHelper.shouldUseDesktopLayout(context)) {
      return const LockedNotesScreen();
    }

    // Desktop: LockedNotesScreen بداخلها scaffold + SearchableHeader + drawer
    // نستخدمها كـ masterPanel — الـ scaffold الداخلي يتعامل مع الـ drawer
    return const MasterDetailsLayout(
      includeSafeArea: false,
      masterPanel: LockedNotesScreen(),
      detailsPanel: VaultDetailsPanel(),
    );
  }
}
