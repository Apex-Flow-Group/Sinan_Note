// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Widget يعرض Master Panel و Details Panel جنباً إلى جنب مع إمكانية تغيير الحجم
/// 
/// يقسم الشاشة إلى جزئين:
/// - Master Panel (اليسار): قائمة الملاحظات
/// - Details Panel (اليمين): محتوى الملاحظة المختارة
/// 
/// يمكن سحب المقبض بين اللوحتين لتغيير النسبة
class MasterDetailsLayout extends StatefulWidget {
  final Widget masterPanel;
  final Widget detailsPanel;
  final double initialMasterWidthRatio;

  const MasterDetailsLayout({
    super.key,
    required this.masterPanel,
    required this.detailsPanel,
    this.initialMasterWidthRatio = 0.35,
  });

  @override
  State<MasterDetailsLayout> createState() => _MasterDetailsLayoutState();
}

class _MasterDetailsLayoutState extends State<MasterDetailsLayout> {
  late double _masterWidthRatio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _masterWidthRatio = widget.initialMasterWidthRatio;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masterPanelColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final detailsPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Master Panel
              SizedBox(
                width: constraints.maxWidth * _masterWidthRatio,
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
                    child: widget.masterPanel,
                  ),
                ),
              ),
              
              // Resizable Divider
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _isDragging = true;
                    final delta = details.delta.dx / constraints.maxWidth;
                    _masterWidthRatio = (_masterWidthRatio + delta).clamp(0.25, 0.5);
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 8,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 2,
                        color: _isDragging
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Details Panel
              Expanded(
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
                    child: widget.detailsPanel,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
