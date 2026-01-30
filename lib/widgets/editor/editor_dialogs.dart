// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.chooseColor,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor == color
                            ? Colors.blue
                            : (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300),
                        width: currentColor == color ? 3 : 1,
                      ),
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
}
