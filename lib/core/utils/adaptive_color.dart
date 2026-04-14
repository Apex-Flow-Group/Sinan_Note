// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class AdaptiveColor {
  final Color light;
  final Color dark;
  final String name;

  const AdaptiveColor({
    required this.light,
    required this.dark,
    required this.name,
  });

  Color getColor(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

class AppColorPalette {
  static const List<AdaptiveColor> palette = [
    AdaptiveColor(
      light: Color(0xFFFFFFFF),
      dark: Color(0xFF202124),
      name: 'Default',
    ),
    AdaptiveColor(
      light: Color(0xFFF5F5F7),
      dark: Color(0xFF2D2E30),
      name: 'Gray',
    ),
    AdaptiveColor(
      light: Color(0xFFF28B82),
      dark: Color(0xFF5C2B29),
      name: 'Red',
    ),
    AdaptiveColor(
      light: Color(0xFFFBBC04),
      dark: Color(0xFF635D19),
      name: 'Orange',
    ),
    AdaptiveColor(
      light: Color(0xFFFFF475),
      dark: Color(0xFF7C7C24),
      name: 'Yellow',
    ),
    AdaptiveColor(
      light: Color(0xFFCCFF90),
      dark: Color(0xFF345920),
      name: 'Green',
    ),
    AdaptiveColor(
      light: Color(0xFFA7FFEB),
      dark: Color(0xFF16504B),
      name: 'Teal',
    ),
    AdaptiveColor(
      light: Color(0xFFCBF0F8),
      dark: Color(0xFF2D555E),
      name: 'Cyan',
    ),
    AdaptiveColor(
      light: Color(0xFFAECBFA),
      dark: Color(0xFF1E3A5F),
      name: 'Blue',
    ),
    AdaptiveColor(
      light: Color(0xFFD7AEFB),
      dark: Color(0xFF3E2A47),
      name: 'Purple',
    ),
    AdaptiveColor(
      light: Color(0xFFFDCFE8),
      dark: Color(0xFF5B2245),
      name: 'Pink',
    ),
    AdaptiveColor(
      light: Color(0xFFE6C9A8),
      dark: Color(0xFF442F1F),
      name: 'Brown',
    ),
  ];

  static int get defaultIndex => 0;
}
