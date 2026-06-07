// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// مصدر واحد لكل إعدادات الثيم.
/// القاعدة: لا يوجد لون hardcoded خارج هذا الملف.
class AppTheme {
  AppTheme._();

  /// اللون الأساسي الوحيد — يولّد كل شيء تلقائياً
  static const Color _seed = Color(0xFF1A73E8);

  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData light({
    ColorScheme? dynamicScheme,
    String? fontFamily,
  }) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        );
    return _build(scheme, fontFamily);
  }

  static ThemeData dark({
    ColorScheme? dynamicScheme,
    String? fontFamily,
  }) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        );
    return _build(scheme, fontFamily);
  }

  /// اللون الثانوي — يُستخدم في AppBar, Drawer, BottomNav, Cards
  /// فاتح → رمادي واضح يتباين مع الخلفية البيضاء
  /// داكن → surfaceContainerLow (أفتح قليلاً من الخلفية الداكنة)
  static Color secondaryBackground(ColorScheme scheme) {
    return scheme.brightness == Brightness.light
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.04), scheme.surface)
        : scheme.surfaceContainerLow;
  }

  /// لون خلفية الـ Scaffold — أبيض/حليب في الفاتح
  static Color scaffoldBackground(ColorScheme scheme) {
    return scheme.brightness == Brightness.light
        ? scheme.surface
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.05), scheme.surface);
  }

  /// لون خلفية الـ Sidebar/Master panel في الـ Desktop layout
  static Color sidebarBackground(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? const Color(0xFF1A1D21)
        : scheme.surfaceContainerHigh;
  }

  static ThemeData _build(ColorScheme scheme, String? fontFamily) {
    final scaffoldBg = AppTheme.scaffoldBackground(scheme);
    final secondaryBg = AppTheme.secondaryBackground(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryBg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: secondaryBg,
          statusBarIconBrightness: scheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: secondaryBg,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: secondaryBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            );
          }
          return TextStyle(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: secondaryBg,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: secondaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      pageTransitionsTheme: _transitions,
    );
  }
}

