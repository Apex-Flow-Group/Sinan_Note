// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math';

import 'package:flutter/material.dart';

class BreathingSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onMenuTap;
  final VoidCallback? onViewToggle;
  final VoidCallback? onFilterTap;
  final ValueNotifier<String> viewTypeNotifier;

  const BreathingSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onMenuTap,
    this.onViewToggle,
    this.onFilterTap,
    required this.viewTypeNotifier,
  });

  @override
  State<BreathingSearchField> createState() => _BreathingSearchFieldState();
}

class _BreathingSearchFieldState extends State<BreathingSearchField>
    with SingleTickerProviderStateMixin { // استخدمنا Ticker واحد فقط للبساطة
  late AnimationController _waveController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    // حركة بطيئة ومريحة جداً (4 ثوانٍ للدورة الكاملة)
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // تشغيل التموج فقط عندما يبدأ المستخدم بالكتابة
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
      
      if (_focusNode.hasFocus) {
        _waveController.repeat();
      } else {
        _waveController.stop();
        // إعادته للصفر ببطء عند الخروج
        _waveController.animateTo(0, duration: const Duration(milliseconds: 500));
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final Color searchBarColor = brightness == Brightness.light
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceBright;
    final Color contentColor = colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        // نستخدم Container كخلفية متدرجة لتعمل كـ "إطار مضيء"
        return Container(
          // سماكة الإطار المضيء تظهر فقط عند التركيز
          padding: EdgeInsets.all(_focusNode.hasFocus ? 1.5 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: _focusNode.hasFocus
                ? LinearGradient(
                    // ألوان هادئة ومريحة للعين (سماوي وبنفسجي مع شفافية)
                    colors: [
                      searchBarColor, // لون مخفي للدمج
                      const Color(0xFF00D4FF).withValues(alpha: 0.5), // إضاءة هادئة
                      const Color(0xFF7B2FFF).withValues(alpha: 0.5), // إضاءة هادئة
                      searchBarColor, // لون مخفي للدمج
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                    // هنا يحدث سحر الحركة (التموج حول العنصر)
                    transform: GradientRotation(_waveController.value * 2 * pi),
                  )
                : null,
            // ظل طبيعي ثابت وبسيط لا يسبب الهلوسة
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child, // شريط البحث الأساسي
        );
      },
      // شريط البحث محتفظ بلونه الثابت بالداخل
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: searchBarColor,
          borderRadius: BorderRadius.circular(28.5), // أصغر قليلاً من الإطار الخارجي
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search,
                    color: contentColor.withValues(alpha: 0.6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(color: contentColor, fontSize: 14),
                    cursorColor: const Color(0xFF00D4FF), // مؤشر كتابة متناسق
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                          color: contentColor.withValues(alpha: 0.5),
                          fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.onViewToggle != null || widget.onFilterTap != null)
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: SizedBox(
                        width: _focusNode.hasFocus ? 0 : null,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.onViewToggle != null)
                                ValueListenableBuilder<String>(
                                  valueListenable: widget.viewTypeNotifier,
                                  builder: (context, viewType, child) {
                                    return IconButton(
                                      icon: Icon(
                                        viewType == 'listExpanded'
                                            ? Icons.view_headline
                                            : viewType == 'listCompact'
                                                ? Icons.grid_view
                                                : Icons.view_day,
                                        color: contentColor.withValues(alpha: 0.7),
                                      ),
                                      onPressed: widget.onViewToggle,
                                      splashRadius: 24,
                                    );
                                  },
                                ),
                              if (widget.onFilterTap != null)
                                IconButton(
                                  icon: Icon(Icons.filter_list_rounded,
                                      color: contentColor.withValues(alpha: 0.7)),
                                  onPressed: widget.onFilterTap,
                                  splashRadius: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
