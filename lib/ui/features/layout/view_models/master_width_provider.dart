// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider مشترك لعرض Master Panel في جميع شاشات Master-Details
///
/// يضمن أن تغيير العرض في أي شاشة (الرئيسية، السلة، الأرشيف، التذكيرات)
/// يُطبَّق فوراً على جميع الشاشات الأخرى ويُحفظ في SharedPreferences.
class MasterWidthProvider extends ChangeNotifier {
  static const String _key = 'master_panel_width';

  double _width = 0; // 0 = لم يُحمَّل بعد، سيُحسب من الـ ratio عند أول بناء

  double get width => _width;

  MasterWidthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_key);
    if (saved != null && saved > 0) {
      _width = saved;
      notifyListeners();
    }
  }

  /// تحديث العرض وإخطار جميع المستمعين وحفظه
  void setWidth(double newWidth) {
    if ((_width - newWidth).abs() < 0.5) return; // تجاهل التغييرات الصغيرة جداً
    _width = newWidth;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _width);
  }
}
