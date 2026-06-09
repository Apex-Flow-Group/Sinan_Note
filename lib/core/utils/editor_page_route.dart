// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Route فتح العارض/المحرر.
///
/// الـ Hero يطير بشكل مستقل فوق الـ fade — الخلفية لا تكون سوداء.
class EditorPageRoute<T> extends PageRouteBuilder<T> {
  EditorPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          opaque: false, // شفاف حتى تظهر الشاشة السابقة خلف الـ Hero
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
              reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeInCubic),
            );
            return FadeTransition(opacity: fadeCurve, child: child);
          },
        );
}
