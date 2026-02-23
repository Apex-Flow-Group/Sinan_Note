// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles text formatting operations
class EditorFormattingController {
  /// Insert text at cursor position
  void insertText(
    TextEditingController controller,
    String text,
  ) {
    final currentText = controller.text;
    final selection = controller.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  /// Wrap selected text with wrapper (e.g., ** for bold)
  void wrapText(
    TextEditingController controller,
    String wrapper,
  ) {
    final currentText = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.start == selection.end) return;

    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(0, currentText.length);

    if (start >= end) return;

    final selectedText = currentText.substring(start, end);
    final wrappedText = '$wrapper$selectedText$wrapper';

    final beforeSelection = currentText.substring(0, start);
    final afterSelection = currentText.substring(end);
    final newText = beforeSelection + wrappedText + afterSelection;

    final newCursorPosition = start + wrappedText.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Insert symbol at cursor (handles pairs like {}, [], etc.)
  void insertSymbol(
    TextEditingController controller,
    String symbol,
  ) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    String newText;
    int newCursorPos;

    if (symbol.length == 2 &&
        (symbol == '{}' ||
            symbol == '[]' ||
            symbol == '()' ||
            symbol == '<>' ||
            symbol == '""' ||
            symbol == "''")) {
      newText = text.replaceRange(cursorPos, cursorPos, symbol);
      newCursorPos = cursorPos + 1;
    } else if (symbol == '/**/') {
      newText = text.replaceRange(cursorPos, cursorPos, symbol);
      newCursorPos = cursorPos + 2;
    } else {
      newText = text.replaceRange(cursorPos, cursorPos, symbol);
      newCursorPos = cursorPos + symbol.length;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  /// Show formatting hint dialog
  Future<bool> showFormattingHint(
    BuildContext context,
    Color backgroundColor,
    Color textColor,
    VoidCallback onApply,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = await SharedPreferences.getInstance();
    final hideHint = prefs.getBool('hide_formatting_hint') ?? false;

    if (hideHint) {
      onApply();
      return true;
    }

    bool dontShowAgain = false;
    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: backgroundColor,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.formattingHint, style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.formattingHintMessage,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontShowAgain,
                    onChanged: (val) =>
                        setState(() => dontShowAgain = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      l10n.dontShowAgain,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (dontShowAgain) {
        await prefs.setBool('hide_formatting_hint', true);
      }
      onApply();
      return true;
    }
    return false;
  }
}
