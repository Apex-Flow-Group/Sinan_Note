// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

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
            : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
        borderRadius: BorderRadius.circular(size / 2),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: (color ?? Colors.blue).withValues(alpha: 0.15),
          highlightColor: (color ?? Colors.blue).withValues(alpha: 0.08),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: color ?? (isDark ? Colors.white : Colors.black87),
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
