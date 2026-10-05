// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

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
        : Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05), scheme.surface);
  }

  /// لون خلفية الـ Sidebar/Master panel في الـ Desktop layout
  static Color sidebarBackground(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? const Color(0xFF1A1D21)
        : scheme.surfaceContainerHigh;
  }

  /// سلّم أحجام الخطوط — بقيم ما يستخدمه التطبيق فعلاً، فلا يتغيّر شكله.
  /// الواجهات تطلب `context.text.bodySmall` لا `fontSize: 13`:
  ///
  /// | الحجم | النمط |
  /// |---|---|
  /// | 10–11 | labelSmall |
  /// | 12 | labelMedium |
  /// | 13 | bodySmall |
  /// | 14 | bodyMedium (labelLarge للأزرار) |
  /// | 15 | titleSmall |
  /// | 16 | bodyLarge (titleMedium للعريض) |
  /// | 18 | titleLarge |
  /// | 20–22 | headlineSmall |
  /// | 24 | headlineMedium |
  /// | 28 | headlineLarge |
  static const textScale = TextTheme(
    labelSmall: TextStyle(fontSize: 11),
    labelMedium: TextStyle(fontSize: 12),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: TextStyle(fontSize: 13),
    bodyMedium: TextStyle(fontSize: 14),
    bodyLarge: TextStyle(fontSize: 16),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 22),
    headlineMedium: TextStyle(fontSize: 24),
    headlineLarge: TextStyle(fontSize: 28),
  );

  static ThemeData _build(ColorScheme scheme, String? fontFamily) {
    final scaffoldBg = AppTheme.scaffoldBackground(scheme);
    final secondaryBg = AppTheme.secondaryBackground(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [
        scheme.brightness == Brightness.dark ? AppColors.dark : AppColors.light,
      ],
      fontFamily: fontFamily,
      textTheme: textScale,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryBg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontFamily: fontFamily,
          color: scheme.onSurface,
        ),
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
