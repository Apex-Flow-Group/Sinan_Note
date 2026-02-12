// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Widget يعرض Master Panel و Details Panel جنباً إلى جنب
/// 
/// يقسم الشاشة إلى جزئين:
/// - Master Panel (اليسار): قائمة الملاحظات - 35% من العرض
/// - Details Panel (اليمين): محتوى الملاحظة المختارة - 65% من العرض
/// 
/// يستخدم Row مع Expanded لتقسيم المساحة بشكل مرن
class MasterDetailsLayout extends StatelessWidget {
  /// قائمة الملاحظات (Master Panel)
  final Widget masterPanel;
  
  /// محتوى الملاحظة المختارة (Details Panel)
  final Widget detailsPanel;
  
  /// نسبة عرض Master Panel من إجمالي العرض
  /// القيمة الافتراضية: 0.35 (35%)
  final double masterWidthRatio;

  const MasterDetailsLayout({
    super.key,
    required this.masterPanel,
    required this.detailsPanel,
    this.masterWidthRatio = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ألوان للوضع الفاتح والداكن
    final masterPanelColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    
    final detailsPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surface;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Master Panel - قائمة الملاحظات (35%) - لون أغمق
          Expanded(
            flex: (masterWidthRatio * 100).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: masterPanelColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: masterPanel,
              ),
            ),
          ),
          
          // مسافة بين اللوحتين
          const SizedBox(width: 8),
          
          // Details Panel - محتوى الملاحظة (65%) - لون أفتح
          Expanded(
            flex: ((1 - masterWidthRatio) * 100).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: detailsPanelColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: detailsPanel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
