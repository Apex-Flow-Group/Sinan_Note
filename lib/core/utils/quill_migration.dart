// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Converts plain text or existing Delta JSON to a Quill Document
class QuillMigration {
  /// Returns a QuillController from note content (plain text or Delta JSON)
  static QuillController controllerFromContent(String content) {
    if (content.isEmpty) {
      return QuillController.basic();
    }

    // Try to parse as Delta JSON
    if (content.trimLeft().startsWith('[')) {
      try {
        final delta = Delta.fromJson(jsonDecode(content) as List);
        final doc = Document.fromDelta(delta);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fall through to plain text
      }
    }

    // Plain text → Delta
    final doc = Document()..insert(0, content);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// Converts a Quill document to plain text for storage
  static String toPlainText(QuillController controller) {
    return controller.document.toPlainText().trimRight();
  }

  /// Converts a Quill document to Delta JSON string for storage
  static String toDeltaJson(QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  /// Checks if content is already Delta JSON
  static bool isDelta(String content) {
    if (!content.trimLeft().startsWith('[')) return false;
    try {
      final decoded = jsonDecode(content);
      return decoded is List;
    } catch (_) {
      return false;
    }
  }
}
