// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget يعرض Master Panel و Details Panel جنباً إلى جنب مع إمكانية تغيير الحجم
///
/// يقسم الشاشة إلى جزئين:
/// - Master Panel (اليسار): قائمة الملاحظات
/// - Details Panel (اليمين): محتوى الملاحظة المختارة
///
/// يمكن سحب المقبض بين اللوحتين لتغيير النسبة
///
/// ✅ OPTIMIZED: يستخدم RepaintBoundary لعزل إعادة الرسم
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
  // عرض بالـ pixel بدل ratio — لا يحتاج LayoutBuilder
  double _masterWidth = 0;
  bool _isDragging = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedWidth();
  }

  Future<void> _loadSavedWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('master_panel_width');
    if (mounted && saved != null) {
      setState(() => _masterWidth = saved);
    }
  }

  Future<void> _saveWidth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('master_panel_width', _masterWidth);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masterPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerLowest;
    final detailsPanelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _MasterDetailsRow(
        masterWidth: _masterWidth,
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
            if (_masterWidth == 0) {
              setState(
                  () => _masterWidth = width * widget.initialMasterWidthRatio);
            }
          }
        },
        onDragStart: () => setState(() => _isDragging = true),
        onDragUpdate: (dx, totalWidth) {
          setState(() {
            // في RTL، الـ Row ينعكس فيصبح Master على اليمين
            // لذلك نعكس اتجاه السحب ليتوافق مع الاتجاه المنطقي
            final isRtl = Directionality.of(context) == TextDirection.rtl;
            final effectiveDx = isRtl ? -dx : dx;
            _masterWidth = (_masterWidth + effectiveDx)
                .clamp(totalWidth * 0.2, totalWidth * 0.6);
          });
        },
        onDragEnd: () {
          setState(() => _isDragging = false);
          _saveWidth();
        },
      ),
    );
  }
}

// widget منفصل يحتوي LayoutBuilder مرة واحدة فقط عند التهيئة
class _MasterDetailsRow extends StatelessWidget {
  final double masterWidth;
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
    required this.masterWidth,
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
    // LayoutBuilder فقط لمعرفة العرض الكلي — لا يُعيد بناء الأبناء
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // نُخبر الـ parent بالعرض الكلي مرة واحدة فقط
        if (!initialized) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onInit(totalWidth));
        }
        final effectiveWidth =
            masterWidth == 0 ? totalWidth * initialRatio : masterWidth;

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
