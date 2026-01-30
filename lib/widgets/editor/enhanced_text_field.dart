// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../core/utils/apex_smart_controller.dart';

/// Enhanced TextField with better cursor visibility and selection handling
class EnhancedTextField extends StatelessWidget {
  final ApexSmartController controller;
  final String? hintText;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final InputDecoration? decoration;

  const EnhancedTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.autofocus = false,
    this.focusNode,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textAlign: textAlign,
      maxLines: maxLines,

      // Enhanced cursor settings
      cursorWidth: 2.5,
      cursorHeight: (style?.fontSize ?? 16) * 1.2,
      cursorRadius: const Radius.circular(2),
      cursorColor: isDark ? Colors.blue[300] : Colors.blue[700],
      showCursor: true,

      // Enhanced selection settings
      enableInteractiveSelection: true,
      selectionControls: MaterialTextSelectionControls(),

      // Selection colors
      style: style,

      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
    );
  }
}
