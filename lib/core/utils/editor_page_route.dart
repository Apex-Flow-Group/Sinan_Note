// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// انيميشن فتح العارض/المحرر: fade مع Hero animation للبطاقة
class EditorPageRoute<T> extends PageRouteBuilder<T> {
  EditorPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
              reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeInCubic),
            );
            return FadeTransition(opacity: fadeCurve, child: child);
          },
        );
}
