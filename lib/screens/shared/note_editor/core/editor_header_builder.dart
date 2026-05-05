// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/widgets/editor/apex_editor_header.dart';
import 'package:apex_note/widgets/editor/category_picker_sheet.dart';
import 'package:apex_note/widgets/editor/editor_selection_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorHeaderBuilder {
  static Widget build({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required String currentTitle,
    required Note? note,
    required String? notePassword,
    required VoidCallback onReminderTap,
    required VoidCallback onHistoryTap,
    VoidCallback? onTitleTap,
    VoidCallback? onSaveTap,
    VoidCallback? onBackTap,
    required void Function(List<int>) onCategoryChanged,
    bool originallyLocked = false,
    ValueNotifier<double>? scrollProgress,
    bool isReadOnly = false,
    VoidCallback? onEditTap,
    ValueNotifier<bool>? selectionBarActive,
    QuillController? quillController,
    Future<void> Function()? onPaste,
  }) {
    final base = coordinator.getBackgroundColor(context);
    final isDark = base.computeLuminance() < 0.5;
    final scrolled = Color.alphaBlend(
      isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      base,
    );

    Widget buildHeaderWidget(Color bg) => SafeArea(
          bottom: false,
          child: ApexEditorHeader(
            backgroundColor: bg,
            textColor: finalTextColor,
            title: currentTitle,
            isLocked: note?.isLocked == true || notePassword != null,
            hasHistory: note?.id != null,
            hasReminder: coordinator.stateManager.reminderDateTime != null,
            onReminderTap: isReadOnly
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onReminderTap();
                  },
            onHistoryTap: onHistoryTap,
            onTitleTap: isReadOnly
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTitleTap?.call();
                  },
            onSaveTap: isReadOnly
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    onSaveTap?.call();
                  },
            onEditTap: isReadOnly
                ? () {
                    HapticFeedback.mediumImpact();
                    onEditTap?.call();
                  }
                : null,
            onBackTap: onBackTap,
            onCategoryTap: (isReadOnly || originallyLocked)
                ? null
                : () async {
                    final current = coordinator.stateManager.categoryIds;
                    final result = await CategoryPickerSheet.show(
                      context,
                      current,
                      isHiddenFromHome:
                          coordinator.stateManager.isHiddenFromHome,
                    );
                    if (result != null) {
                      onCategoryChanged(result['categoryIds'] as List<int>);
                      coordinator.stateManager.isHiddenFromHome =
                          result['isHiddenFromHome'] as bool;
                    }
                  },
          ),
        );

    Widget buildSelectionBar(Color bg) =>
        (selectionBarActive != null &&
                quillController != null &&
                onPaste != null)
            ? SafeArea(
                bottom: false,
                child: EditorSelectionPanel(
                  ctrl: quillController,
                  backgroundColor: bg,
                  textColor: finalTextColor,
                  onPaste: onPaste,
                  onDismiss: () => selectionBarActive.value = false,
                ),
              )
            : buildHeaderWidget(bg);

    Widget buildContainer(Color bg) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: selectionBarActive != null
              ? ValueListenableBuilder<bool>(
                  valueListenable: selectionBarActive,
                  builder: (_, isBarActive, __) => Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: isBarActive ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: buildHeaderWidget(bg),
                      ),
                      if (isBarActive) buildSelectionBar(bg),
                    ],
                  ),
                )
              : buildHeaderWidget(bg),
        );

    if (scrollProgress == null) return buildContainer(base);
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (_, progress, __) =>
          buildContainer(Color.lerp(base, scrolled, progress)!),
    );
  }
}
