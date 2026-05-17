// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Route فتح العارض/المحرر.
///
/// يستخدم fade transition مع Hero animation للبطاقة.
/// الـ Hero يطير داخل حدود الـ route فقط — لا يطير فوق BottomNavBar.
class EditorPageRoute<T> extends PageRouteBuilder<T> {
  EditorPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              // نُزيل الـ bottom padding من MediaQuery داخل الـ route
              // هذا يُخبر Hero بأن المنطقة السفلية (BottomNavBar) خارج حدوده
              MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(bottom: 0),
              viewPadding:
                  MediaQuery.of(context).viewPadding.copyWith(bottom: 0),
            ),
            child: builder(context),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              reverseCurve: const Interval(0.0, 0.9, curve: Curves.easeInCubic),
            );
            return FadeTransition(opacity: fadeCurve, child: child);
          },
        );
}
