// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/state/editor_state_manager.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/editor_palette.dart';
import 'package:sinan_note/ui/core/theme/note_palette.dart';
import 'package:sinan_note/ui/features/reminders/view_models/reminder_permissions.dart';
import 'package:sinan_note/widgets/common/color_picker_sheet.dart';
import 'package:sinan_note/widgets/common/rename_dialog.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/editor/note_history_sheet.dart';
import 'package:sinan_note/widgets/editor/reminder_picker_sheet.dart';

/// Handles all dialog interactions for the note editor
class EditorDialogHandlers {
  /// Show reminder picker dialog
  static Future<void> showReminderDialog({
    required BuildContext context,
    required EditorStateManager stateManager,
    required Color backgroundColor,
    required Note? note,
    required Future<void> Function({bool isManualSave}) saveCallback,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await ReminderPickerSheet.show(
      context,
      stateManager.reminderDateTime ?? note?.reminderDateTime,
      stateManager.recurrenceRule ?? note?.recurrenceRule,
      backgroundColor,
    );

    if (result != null) {
      if (result['remove'] == true) {
        // إلغاء الإشعار يتبع الحفظ (آثار المستودع الجانبية)
        stateManager.reminderDateTime = null;
        stateManager.recurrenceRule = null;
        stateManager.markDirty();

        await saveCallback(isManualSave: true);
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.reminderRemoved,
          type: NotificationType.info,
        );
        return;
      }

      final reminderDateTime = result['dateTime'] as DateTime?;
      final recurrence = result['recurrence'] as String?;

      if (reminderDateTime != null && context.mounted) {
        final hasExactAlarmPermission =
            await context.read<ReminderPermissions>().canScheduleExact();

        if (!hasExactAlarmPermission) {
          if (!context.mounted) return;
          UnifiedNotificationService().showWithAction(
            context: context,
            message: l10n.precisePermissionRequired,
            actionLabel: l10n.openSettings,
            type: NotificationType.error,
            duration: const Duration(seconds: 5),
            onAction: () => openAppSettings(),
          );
          return;
        }

        stateManager.reminderDateTime = reminderDateTime;
        stateManager.recurrenceRule = recurrence == 'none' ? null : recurrence;
        stateManager.markDirty();

        await saveCallback(isManualSave: true);
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.reminderAdded,
          type: NotificationType.success,
        );
      }
    }
  }

  /// Show color palette bottom sheet
  static Future<void> showColorPalette({
    required BuildContext context,
    required EditorStateManager stateManager,
    required NoteMode mode,
    required Function(int colorIndex, Color textColor) onColorSelected,
  }) async {
    final selectedIndex = await ColorPickerSheet.show(
      context,
      currentIndex: stateManager.colorIndex,
    );

    if (selectedIndex == null || !context.mounted) return;

    final brightness = Theme.of(context).brightness;
    final color = AppColorPalette.palette[selectedIndex].getColor(brightness);
    final isDarkBg = color.computeLuminance() < 0.5;
    final textColor =
        isDarkBg ? EditorPalette.inkOnDark : EditorPalette.inkOnLight;

    stateManager.colorIndex = selectedIndex;
    stateManager.markDirty();
    onColorSelected(selectedIndex, textColor);

    // حفظ آخر لون مستخدم لهذا النوع
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    String colorMode = 'simple';
    if (mode == NoteMode.reminder) {
      colorMode = 'reminder';
    } else if (mode == NoteMode.code) {
      colorMode = 'professional';
    } else if (mode == NoteMode.checklist) {
      colorMode = 'checklist';
    } else if (mode == NoteMode.rich) {
      colorMode = 'rich';
    }
    await settings.setDefaultColorIndex(colorMode, selectedIndex);
  }

  /// Show inline text color picker and apply to Quill selection
  static Future<void> showInlineColorPicker({
    required BuildContext context,
    required Color backgroundColor,
    required QuillController quillController,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final textColors = <Color?>[
      null, // reset
      ...EditorPalette.textColors,
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.chooseTextColor,
                  style: ctx.text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: textColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      if (color == null) {
                        quillController
                            .formatSelection(const ColorAttribute(null));
                      } else {
                        final hex =
                            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                        quillController.formatSelection(ColorAttribute(hex));
                      }
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color ?? Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == null
                              ? ctx.colors.muted
                              : ctx.colors.subtle,
                          width: 2,
                        ),
                      ),
                      child: color == null
                          ? Icon(Icons.format_clear,
                              size: 20, color: ctx.colors.muted)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show note history sheet
  static void showHistorySheet({
    required BuildContext context,
    required Note? note,
  }) {
    if (note?.id == null) return;
    NoteHistorySheet.show(context, note!.id!);
  }

  /// Show rename title dialog
  static Future<String?> showRenameTitleDialog({
    required BuildContext context,
    required String currentTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dialogBg =
        theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;
    final dialogText =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RenameDialog(
        initialTitle: currentTitle,
        backgroundColor: dialogBg,
        textColor: dialogText,
        hintText: l10n.enterCustomTitle,
        titleText: l10n.renameNote,
        cancelText: l10n.cancel,
        saveText: l10n.save,
      ),
    );
  }

  /// Show smart save dialog with language mismatch warning
  static Future<void> showSmartSaveDialog({
    required BuildContext context,
    required String selectedExtension,
    required String? detectedLanguage,
    required EditorSmartController smartController,
    required Color backgroundColor,
    required Color textColor,
    required Future<void> Function() saveAsMarkdown,
    required Future<void> Function(String extension) saveWithExtension,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    bool hasMismatch = false;
    if (detectedLanguage != null && selectedExtension.isNotEmpty) {
      final expectedExt =
          smartController.getExtensionForLanguage(detectedLanguage);
      hasMismatch = expectedExt != selectedExtension;
    }

    if (hasMismatch) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(l10n.warning, style: TextStyle(color: textColor)),
          content: Text(
            l10n.fileContainsErrors,
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'force'),
              child: Text(l10n.saveAnyway,
                  style: TextStyle(color: ctx.colors.warning)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'markdown'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: ctx.colors.success),
              child: Text(l10n.saveAsMarkdown),
            ),
          ],
        ),
      );

      if (action == 'markdown') {
        await saveAsMarkdown();
      } else if (action == 'force') {
        await saveWithExtension(selectedExtension);
      }
    } else {
      await saveWithExtension(selectedExtension);
    }
  }
}
