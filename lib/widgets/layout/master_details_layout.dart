// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/master_width_provider.dart';

/// Widget يعرض Master Panel و Details Panel جنباً إلى جنب مع إمكانية تغيير الحجم
///
/// يقسم الشاشة إلى جزئين:
/// - Master Panel (اليسار): قائمة الملاحظات
/// - Details Panel (اليمين): محتوى الملاحظة المختارة
///
/// العرض مشترك بين جميع الشاشات عبر [MasterWidthProvider] —
/// تغييره في أي شاشة يُطبَّق فوراً على الكل ويُحفظ تلقائياً.
///
/// ✅ OPTIMIZED: يستخدم RepaintBoundary لعزل إعادة الرسم
class MasterDetailsLayout extends StatefulWidget {
  final Widget masterPanel;
  final Widget detailsPanel;
  final double initialMasterWidthRatio;
  final bool includeSafeArea;

  const MasterDetailsLayout({
    super.key,
    required this.masterPanel,
    required this.detailsPanel,
    this.initialMasterWidthRatio = 0.35,
    this.includeSafeArea = true,
  });

  @override
  State<MasterDetailsLayout> createState() => _MasterDetailsLayoutState();
}

class _MasterDetailsLayoutState extends State<MasterDetailsLayout> {
  bool _isDragging = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masterPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerLowest;
    final detailsPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surface;

    final content = Padding(
      padding: const EdgeInsets.all(8.0),
      child: _MasterDetailsRow(
        isDragging: _isDragging,
        initialized: _initialized,
        initialRatio: widget.initialMasterWidthRatio,
        masterPanelColor: masterPanelColor,
        detailsPanelColor: detailsPanelColor,
        masterPanel: widget.masterPanel,
        detailsPanel: widget.detailsPanel,
        onInit: (width) {
          if (!_initialized) {
            _initialized = true;
            final provider =
                Provider.of<MasterWidthProvider>(context, listen: false);
            if (provider.width == 0) {
              provider.setWidth(width * widget.initialMasterWidthRatio);
            }
          }
        },
        onDragStart: () => setState(() => _isDragging = true),
        onDragUpdate: (dx, totalWidth) {
          final provider =
              Provider.of<MasterWidthProvider>(context, listen: false);
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          final effectiveDx = isRtl ? -dx : dx;
          final newWidth = (provider.width + effectiveDx)
              .clamp(totalWidth * 0.2, (totalWidth - 20) * 0.6);
          provider.setWidth(newWidth);
        },
        onDragEnd: () => setState(() => _isDragging = false),
      ),
    );

    if (widget.includeSafeArea) {
      return SafeArea(child: content);
    }
    return SafeArea(top: false, child: content);
  }
}

// widget منفصل يحتوي LayoutBuilder مرة واحدة فقط عند التهيئة
class _MasterDetailsRow extends StatelessWidget {
  final bool isDragging;
  final bool initialized;
  final double initialRatio;
  final Color masterPanelColor;
  final Color detailsPanelColor;
  final Widget masterPanel;
  final Widget detailsPanel;
  final void Function(double totalWidth) onInit;
  final VoidCallback onDragStart;
  final void Function(double dx, double totalWidth) onDragUpdate;
  final VoidCallback onDragEnd;

  const _MasterDetailsRow({
    required this.isDragging,
    required this.initialized,
    required this.initialRatio,
    required this.masterPanelColor,
    required this.detailsPanelColor,
    required this.masterPanel,
    required this.detailsPanel,
    required this.onInit,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        if (!initialized) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onInit(totalWidth));
        }

        // قراءة العرض من Provider المشترك — مع clamp لمنع الفيضان
        final masterWidth = context.watch<MasterWidthProvider>().width;
        final rawWidth =
            masterWidth == 0 ? totalWidth * initialRatio : masterWidth;
        // ضمان أن العرض لا يتجاوز المساحة المتاحة (مع مراعاة الـ divider 20px)
        final effectiveWidth =
            rawWidth.clamp(totalWidth * 0.2, (totalWidth - 20) * 0.6);

        return Row(
          children: [
            // Master Panel — عرض ثابت بالـ pixel
            RepaintBoundary(
              child: SizedBox(
                width: effectiveWidth,
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
            ),

            // Divider قابل للسحب
            GestureDetector(
              onHorizontalDragStart: (_) => onDragStart(),
              onHorizontalDragUpdate: (d) =>
                  onDragUpdate(d.delta.dx, totalWidth),
              onHorizontalDragEnd: (_) => onDragEnd(),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  color: isDragging
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3)
                      : Colors.transparent,
                  child: Center(
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: isDragging
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Details Panel — يأخذ باقي المساحة
            Expanded(
              child: RepaintBoundary(
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
            ),
          ],
        );
      },
    );
  }
}
