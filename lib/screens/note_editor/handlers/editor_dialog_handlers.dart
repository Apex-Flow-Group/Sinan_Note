// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../services/notification_service.dart';
import '../../../controllers/settings/settings_provider.dart';
import '../../../core/utils/adaptive_color.dart';
import '../../../widgets/common/apex_snackbar.dart';
import '../../../widgets/editor/reminder_picker_sheet.dart';
import '../../../widgets/editor/note_history_sheet.dart';
import '../../../widgets/common/rename_dialog.dart';
import '../../../controllers/editor/editor_state_manager.dart';
import '../controllers/editor_smart_controller.dart';

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
        if (note?.id != null) {
          await NotificationService().cancelNotification(note!.id!);
        }
        stateManager.reminderDateTime = null;
        stateManager.recurrenceRule = null;
        stateManager.markDirty();
        
        await saveCallback(isManualSave: true);
        if (context.mounted) {
          ApexSnackBar.show(context, l10n.reminderRemoved, type: SnackBarType.info);
        }
        return;
      }

      final reminderDateTime = result['dateTime'] as DateTime?;
      final recurrence = result['recurrence'] as String?;

      if (reminderDateTime != null) {
        final hasExactAlarmPermission =
            await NotificationService().checkExactAlarmPermission();

        if (!hasExactAlarmPermission) {
          if (context.mounted) {
            ApexSnackBar.show(
              context,
              l10n.precisePermissionRequired,
              type: SnackBarType.error,
              duration: const Duration(seconds: 5),
              actionLabel: l10n.openSettings,
              onAction: () => openAppSettings(),
            );
          }
          return;
        }

        stateManager.reminderDateTime = reminderDateTime;
        stateManager.recurrenceRule = recurrence == 'none' ? null : recurrence;
        stateManager.markDirty();

        await saveCallback(isManualSave: true);
        if (context.mounted) {
          ApexSnackBar.show(context, l10n.reminderAdded,
              type: SnackBarType.success);
        }
      }
    }
  }

  /// Show color palette dialog
  static Future<void> showColorPalette({
    required BuildContext context,
    required EditorStateManager stateManager,
    required NoteMode mode,
    required Function(int colorIndex, Color textColor) onColorSelected,
  }) async {
    final brightness = Theme.of(context).brightness;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseColor),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(AppColorPalette.palette.length, (index) {
            final adaptiveColor = AppColorPalette.palette[index];
            final color = adaptiveColor.getColor(brightness);
            
            return GestureDetector(
              key: ValueKey('color_$index'),
              onTap: () async {
                final isDarkBg = color.computeLuminance() < 0.5;
                final textColor = isDarkBg ? Colors.white : Colors.black87;
                
                stateManager.colorIndex = index;
                stateManager.markDirty();
                onColorSelected(index, textColor);
                
                // Save last used color for this note type
                if (context.mounted) {
                  final settings = Provider.of<SettingsProvider>(context, listen: false);
                  String colorMode = 'simple';
                  if (mode == NoteMode.reminder) {
                    colorMode = 'reminder';
                  } else if (mode == NoteMode.code) {
                    colorMode = 'professional';
                  }
                  await settings.setDefaultColorIndex(colorMode, index);
                }
                
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stateManager.colorIndex == index
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Show inline text color picker
  static Future<void> showInlineColorPicker({
    required BuildContext context,
    required Color backgroundColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final textColors = [
      Colors.black87,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.chooseTextColor,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: textColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
    final dialogBg = theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;
    final dialogText = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

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
                  style: const TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'markdown'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
