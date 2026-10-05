// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

/// زر مفردة في لوحة أرقام PIN
class PinNumpadKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDark;
  final Color? color;
  final double size;

  const PinNumpadKey({
    super.key,
    required this.child,
    required this.onTap,
    required this.isDark,
    required this.size,
    this.onLongPress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color != null
            ? color!.withValues(alpha: 0.08)
            : context.scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(size / 2),
        elevation: isDark ? 0 : 1,
        shadowColor: context.colors.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor:
              (color ?? context.scheme.primary).withValues(alpha: 0.15),
          highlightColor:
              (color ?? context.scheme.primary).withValues(alpha: 0.08),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: color ?? context.scheme.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// صف أرقام في لوحة PIN
class PinNumpadRow extends StatelessWidget {
  final List<String> digits;
  final bool isDark;
  final double keySize;
  final double spacing;
  final void Function(String digit) onDigit;

  const PinNumpadRow({
    super.key,
    required this.digits,
    required this.isDark,
    required this.keySize,
    required this.spacing,
    required this.onDigit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) => PinNumpadKey(
              isDark: isDark,
              size: keySize,
              onTap: () => onDigit(d),
              child: Text(
                d,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.scheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
