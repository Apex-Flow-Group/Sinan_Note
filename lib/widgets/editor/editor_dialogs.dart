// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/common/color_picker_sheet.dart';
import 'package:flutter/material.dart';

class WidgetEditorDialogs {
  static Future<String?> showPasswordDialog(
    BuildContext context,
    String title,
    String hint,
    Color backgroundColor,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Create fresh controller to avoid stale state
    final controller = TextEditingController();
    final isLight = backgroundColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(title, style: TextStyle(color: textColor)),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear(); // Clear before closing
              Navigator.pop(ctx);
            },
            child: Text(l10n.cancel, style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              final password = controller.text;
              controller.clear(); // Clear before closing
              Navigator.pop(ctx, password);
            },
            child: Text(l10n.confirm, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );

    // Dispose controller after dialog closes
    controller.dispose();
    return result;
  }

  static void showRenameDialog(
    BuildContext context,
    String? currentTitle,
    Color backgroundColor,
    Function(String?) onRename,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(l10n.renameNote),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.enterCustomTitle,
            border: const UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onRename(null);
              Navigator.pop(ctx);
            },
            child: Text(l10n.automatic,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              onRename(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  static void showColorPalette(
    BuildContext context,
    List<Color> colors,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    // ── محوّل للمكون المشترك ColorPickerSheet ──────────────────────────
    // نحوّل currentColor إلى index ثم نستخدم ColorPickerSheet
    final brightness = Theme.of(context).brightness;
    final currentIndex =
        colors.indexOf(currentColor).clamp(0, colors.length - 1);

    ColorPickerSheet.show(context, currentIndex: currentIndex).then((index) {
      if (index != null) {
        final color = AppColorPalette.palette[index].getColor(brightness);
        onColorSelected(color);
      }
    });
  }
}
