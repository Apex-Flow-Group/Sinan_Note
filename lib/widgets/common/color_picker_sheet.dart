// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// مكون مشترك لاختيار لون النوتة — Bottom Sheet
///
/// الاستخدام:
/// ```dart
/// final index = await ColorPickerSheet.show(
///   context,
///   currentIndex: note.colorIndex,
/// );
/// if (index != null) { /* تم الاختيار */ }
/// ```
class ColorPickerSheet {
  /// يعرض الـ bottom sheet ويرجع index اللون المختار، أو null إذا أُغلق بدون اختيار
  static Future<int?> show(
    BuildContext context, {
    required int currentIndex,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) => _ColorPickerSheetContent(currentIndex: currentIndex),
    );
  }
}

class _ColorPickerSheetContent extends StatefulWidget {
  final int currentIndex;

  const _ColorPickerSheetContent({required this.currentIndex});

  @override
  State<_ColorPickerSheetContent> createState() =>
      _ColorPickerSheetContentState();
}

class _ColorPickerSheetContentState extends State<_ColorPickerSheetContent> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;

    final sheetBg = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final handleColor = isDark ? Colors.white24 : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────────────
              Text(
                l10n.chooseColor,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 20),

              // ── Color Grid ────────────────────────────────────────────
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(
                  AppColorPalette.palette.length,
                  (index) => _ColorCircle(
                    adaptiveColor: AppColorPalette.palette[index],
                    brightness: brightness,
                    isSelected: _selectedIndex == index,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIndex = index);
                      // أغلق وأرجع الـ index مباشرة
                      Navigator.pop(context, index);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final AdaptiveColor adaptiveColor;
  final Brightness brightness;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.adaptiveColor,
    required this.brightness,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = adaptiveColor.getColor(brightness);
    final isDark = brightness == Brightness.dark;

    // حافة داخلية للألوان الفاتحة جداً حتى تظهر على الخلفية البيضاء
    final needsBorder = color.computeLuminance() > 0.85;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : needsBorder
            ? Colors.black12
            : Colors.transparent;
    final borderWidth = isSelected ? 3.0 : 1.5;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: isSelected ? 52 : 48,
        height: isSelected ? 52 : 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.5 : 0.4),
              blurRadius: isSelected ? 10 : 4,
              spreadRadius: isSelected ? 1 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                size: 22,
                color: color.computeLuminance() > 0.5
                    ? Colors.black54
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}
