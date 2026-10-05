// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/services/widget_service.dart';

/// ويدجت الشاشة الرئيسية للواجهات.
class HomeWidgets {
  HomeWidgets([WidgetService? service]) : _service = service ?? WidgetService();

  final WidgetService _service;

  /// يثبّت الملاحظة في ويدجت الملاحظة أو القائمة حسب نوعها.
  Future<void> pin(Note note) => _service.pin(note);
}
