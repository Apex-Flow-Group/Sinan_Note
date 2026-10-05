// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان التطبيق الدلالية — كل لون خارج ColorScheme له اسم معناه هنا،
/// بقيمة للفاتح وأخرى للداكن. الواجهات تطلب `context.colors.danger` لا
/// `Colors.red`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.vault,
    required this.onVault,
    required this.vaultContainer,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.dangerContainer,
    required this.warning,
    required this.info,
    required this.muted,
    required this.subtle,
    required this.scrim,
    required this.shadow,
    required this.gold,
  });

  /// الخزنة والملاحظات المقفلة.
  final Color vault;
  final Color onVault;
  final Color vaultContainer;

  final Color success;
  final Color successContainer;

  /// حذف ودمار لا رجعة فيه.
  final Color danger;
  final Color dangerContainer;

  final Color warning;
  final Color info;

  /// نص ثانوي وأيقونات خاملة.
  final Color muted;

  /// فواصل وحدود خفيفة.
  final Color subtle;

  /// طبقة معتمة خلف المحتوى المنبثق.
  final Color scrim;
  final Color shadow;

  /// التمييز (المثبّت، المميز).
  final Color gold;

  static const light = AppColors(
    vault: Color(0xFFE65100),
    onVault: Color(0xFFFFFFFF),
    vaultContainer: Color(0xFFFFF3E0),
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFE8F5E9),
    danger: Color(0xFFC62828),
    dangerContainer: Color(0xFFFFEBEE),
    warning: Color(0xFFF9A825),
    info: Color(0xFF1E88E5),
    muted: Color(0xFF616161),
    subtle: Color(0xFFE0E0E0),
    scrim: Color(0x66000000),
    shadow: Color(0x1F000000),
    gold: Color(0xFFB8860B),
  );

  static const dark = AppColors(
    vault: Color(0xFFFFA726),
    onVault: Color(0xFF1E1E1E),
    vaultContainer: Color(0xFF3E2A10),
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1B3A1E),
    danger: Color(0xFFEF5350),
    dangerContainer: Color(0xFF3B1414),
    warning: Color(0xFFFFD54F),
    info: Color(0xFF64B5F6),
    muted: Color(0xFFBDBDBD),
    subtle: Color(0xFF424242),
    scrim: Color(0x99000000),
    shadow: Color(0x47000000),
    gold: Color(0xFFFFD700),
  );

  @override
  AppColors copyWith({
    Color? vault,
    Color? onVault,
    Color? vaultContainer,
    Color? success,
    Color? successContainer,
    Color? danger,
    Color? dangerContainer,
    Color? warning,
    Color? info,
    Color? muted,
    Color? subtle,
    Color? scrim,
    Color? shadow,
    Color? gold,
  }) =>
      AppColors(
        vault: vault ?? this.vault,
        onVault: onVault ?? this.onVault,
        vaultContainer: vaultContainer ?? this.vaultContainer,
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        danger: danger ?? this.danger,
        dangerContainer: dangerContainer ?? this.dangerContainer,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        muted: muted ?? this.muted,
        subtle: subtle ?? this.subtle,
        scrim: scrim ?? this.scrim,
        shadow: shadow ?? this.shadow,
        gold: gold ?? this.gold,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      vault: mix(vault, other.vault),
      onVault: mix(onVault, other.onVault),
      vaultContainer: mix(vaultContainer, other.vaultContainer),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      danger: mix(danger, other.danger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      warning: mix(warning, other.warning),
      info: mix(info, other.info),
      muted: mix(muted, other.muted),
      subtle: mix(subtle, other.subtle),
      scrim: mix(scrim, other.scrim),
      shadow: mix(shadow, other.shadow),
      gold: mix(gold, other.gold),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
