// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:isolate';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// يبني [Delta] من نص خام في Isolate منفصل عبر document وهمي
Future<Delta> buildDeltaInIsolate(String text) async {
  final json = await Isolate.run(() => _buildJson(text));
  return Delta.fromJson(json);
}

List<Map<String, dynamic>> _buildJson(String text) {
  final doc = Document.fromJson([
    {'insert': '$text\n'}
  ]);
  return doc.toDelta().toJson();
}
