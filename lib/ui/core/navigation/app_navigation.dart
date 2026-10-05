// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';

/// حالة التنقل في الشاشة الرئيسية، تُحقن من نقطة التركيب.
class AppNavigation {
  /// التبويب الحالي (0 الرئيسية، 1 التذكيرات، 2 الكود).
  final tab = ValueNotifier<int>(0);

  /// الشريط السفلي مخفي بالتمرير.
  final bottomBarHidden = ValueNotifier<bool>(false);

  /// ما يصل من خارج التطبيق (ويدجت، مشاركة، ملف، إشعار).
  final intents = IntentInbox();

  void goHome() => tab.value = 0;

  void dispose() {
    tab.dispose();
    bottomBarHidden.dispose();
  }
}

/// النوايا الخارجية تُنفَّذ فقط والشاشة الرئيسية جاهزة (بعد المصادقة)،
/// وما يصل قبل ذلك ينتظر. آخر نية تغلب، ولا تُنفَّذ نية مرتين.
class IntentInbox {
  /// المنفّذ، يعيّنه التطبيق.
  void Function(Map data)? execute;

  bool _ready = false;
  Map? _pending;

  /// النية المنتظرة (للاختبار والتشخيص).
  Map? get pending => _pending;

  bool get isReady => _ready;

  void deliver(Map data) {
    _pending = Map.of(data);
    _flush();
  }

  /// تعيّنه الشاشة الرئيسية عند ظهورها واختفائها.
  set ready(bool value) {
    _ready = value;
    _flush();
  }

  void _flush() {
    final run = execute;
    final data = _pending;
    if (!_ready || run == null || data == null) return;
    _pending = null;
    run(data);
  }
}
