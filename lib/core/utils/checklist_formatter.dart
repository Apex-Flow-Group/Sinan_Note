// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
/// Checklist item model
class ChecklistItem {
  final dynamic id;
  String text;
  bool isDone;
  bool isGhost; // 🎯 Smart ghost item flag

  ChecklistItem({
    required this.id,
    this.text = '',
    this.isDone = false,
    this.isGhost = false, // Default to real item
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
        // Note: isGhost is not saved to JSON (runtime-only flag)
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: json['text'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        isGhost: false, // Loaded items are never ghost
      );
}

/// Central utility for checklist formatting
class ChecklistFormatter {
  /// Parse JSON string to checklist items
  static List<ChecklistItem> parseJson(String content) {
    try {
      final decoded = jsonDecode(content);

      // Handle {"title":"...", "items":[...]} format
      if (decoded is Map && decoded.containsKey('items')) {
        final List<dynamic> items = decoded['items'];
        return items.map((item) => ChecklistItem.fromJson(item)).toList();
      }

      // Handle direct array format
      if (decoded is List) {
        return decoded.map((item) => ChecklistItem.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Convert checklist items to JSON string
  static String toJson(List<ChecklistItem> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  /// Format checklist for display (read-only text)
  static String toDisplayText(String content) {
    final items = parseJson(content);
    if (items.isEmpty) return '';

    return items.map((item) {
      final checkbox = item.isDone ? '☑' : '☐';
      return '$checkbox ${item.text}';
    }).join('\n');
  }

  /// Check if content is valid JSON checklist
  static bool isValidChecklist(String content) {
    try {
      // Delta JSON ليس checklist
      if (content.trimLeft().startsWith('[')) {
        final decoded = jsonDecode(content);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          // Delta له 'insert' key، Checklist له 'text' أو 'isDone'
          if (first is Map && first.containsKey('insert')) return false;
        }
      }

      final decoded = jsonDecode(content);

      // Check for {"title":"...", "items":[...]} format
      if (decoded is Map && decoded.containsKey('items')) {
        return true;
      }

      // Check for direct array format
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        final first = decoded.first as Map;
        if (first.containsKey('insert')) return false; // Delta
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Convert checklist JSON to plain text (each item = one line)
  static String toPlainText(String jsonContent) {
    final items = parseJson(jsonContent);
    if (items.isEmpty) return '';
    return items
        .where((item) => item.text.isNotEmpty)
        .map((item) => item.text)
        .join('\n');
  }

  /// Convert plain text to checklist JSON (each \n = one item)
  static String fromPlainText(String plainText, {String title = ''}) {
    final lines = plainText.split('\n');
    final items = lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => {
              'id': DateTime.now().microsecondsSinceEpoch.toString() +
                  line.hashCode.toString(),
              'text': line.trim(),
              'isDone': false,
            })
        .toList();
    return jsonEncode({'title': title, 'items': items});
  }

  /// Format checklist for sharing (Unicode format)
  static String formatForSharing(String title, String jsonContent) {
    try {
      final buffer = StringBuffer();
      if (title.isNotEmpty) {
        buffer.writeln(title);
        buffer.writeln('----------------');
      }

      final Map<String, dynamic> data = jsonDecode(jsonContent);
      final List<dynamic> itemsJson = data['items'] ?? [];

      for (var item in itemsJson) {
        final text = item['text'] ?? '';
        final isDone = item['isDone'] ?? false;
        final checkbox = isDone ? '☑' : '☐'; // ☑ ☐
        buffer.writeln('$checkbox $text');
      }

      return buffer.toString();
    } catch (e) {
      return '$title\n\n$jsonContent';
    }
  }
}

