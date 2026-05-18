// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


/// شريط بحث متحرك يتوسع ليدفع العنوان ويتقلص عند الإغلاق
class AnimatedSearchBar extends StatefulWidget {
  final bool isSearchMode;
  final TextEditingController searchController;
  final Widget titleWidget;
  final String hintText;
  final VoidCallback onClose;
  final VoidCallback? onChanged;

  const AnimatedSearchBar({
    super.key,
    required this.isSearchMode,
    required this.searchController,
    required this.titleWidget,
    required this.hintText,
    required this.onClose,
    this.onChanged,
  });

  @override
  State<AnimatedSearchBar> createState() => AnimatedSearchBarState();
}

class AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  final FocusNode _focusNode = FocusNode();

  bool get isFocused => _focusNode.hasFocus;

  void unfocus() => _focusNode.unfocus();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.isSearchMode) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchMode && !oldWidget.isSearchMode) {
      // فتح: شغّل الأنيميشن ثم أظهر الكيبورد بعد اكتمالها
      _controller.forward().then((_) {
        if (mounted && widget.isSearchMode) {
          _focusNode.requestFocus();
        }
      });
    } else if (!widget.isSearchMode && oldWidget.isSearchMode) {
      // إغلاق: أخفِ الكيبورد فوراً ثم شغّل أنيميشن التقلص
      _focusNode.unfocus();
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, _) {
        final t = _expandAnimation.value;
        return Row(
          children: [
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1.0 - t,
                child: Opacity(
                  opacity: (1.0 - t * 2).clamp(0.0, 1.0),
                  child: widget.titleWidget,
                ),
              ),
            ),
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: t,
                  child: Opacity(
                    opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: _focusNode,
                      onChanged: (_) => widget.onChanged?.call(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
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

