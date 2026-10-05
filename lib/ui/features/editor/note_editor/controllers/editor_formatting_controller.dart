// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


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
}

