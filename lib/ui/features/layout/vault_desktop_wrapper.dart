// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

/// يُغلّف محتوى شاشات الخزنة ليكون مناسباً لسطح المكتب.
/// على Desktop (عرض >= 600): محتوى مركزي بعرض 480px داخل Card.
/// على Mobile: المحتوى كما هو.
class VaultDesktopWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const VaultDesktopWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return child;
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: SizedBox(
                width: maxWidth,
                child: Card(
                  elevation: 3,
                  shadowColor: context.colors.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
