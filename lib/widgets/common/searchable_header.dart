// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// شريط بحث موحد — مطابق لـ SearchableHeader في نسخة Native
/// فريم مستدير يحتوي أيقونة بحث + عنوان، عند الضغط يتحول لحقل بحث
class SearchableHeader extends StatefulWidget {
  final String title;
  final IconData? icon;
  final bool isSearching;
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChange;
  final VoidCallback onToggleSearch;
  final Widget? trailing;
  final Widget? leading;
  final double extraBottomPadding;
  final bool includeSafeArea;
  final bool hideSearchFrame;
  final int? noteCount;

  const SearchableHeader({
    super.key,
    required this.title,
    this.icon,
    required this.isSearching,
    required this.searchController,
    this.onSearchChange,
    required this.onToggleSearch,
    this.trailing,
    this.leading,
    this.extraBottomPadding = 0,
    this.includeSafeArea = true,
    this.hideSearchFrame = false,
    this.noteCount,
  });

  @override
  State<SearchableHeader> createState() => _SearchableHeaderState();
}

class _SearchableHeaderState extends State<SearchableHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isSearching ? 1.0 : 0.0,
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(SearchableHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearching && !oldWidget.isSearching) {
      _controller.forward().then((_) {
        if (mounted && widget.isSearching) _focusNode.requestFocus();
      });
    } else if (!widget.isSearching && oldWidget.isSearching) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = widget.includeSafeArea ? MediaQuery.of(context).padding.top : 0.0;

    final appBarColor = AppTheme.secondaryBackground(colorScheme);
    final frameBg = AppTheme.scaffoldBackground(colorScheme);
    final hintColor = colorScheme.onSurface.withValues(alpha: 0.45);
    final textColor = colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: appBarColor,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        color: appBarColor,
        padding: EdgeInsets.only(
          top: topPadding + 6,
          bottom: 6 + widget.extraBottomPadding,
        ),
        child: Row(
          children: [
            if (widget.leading != null) widget.leading!,

            // ── الفريم الرئيسي ──
            Expanded(
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final t = _progress.value;
                  return GestureDetector(
                    onTap: () {
                      if (!widget.isSearching) widget.onToggleSearch();
                    },
                    child: Container(
                      height: 40,
                      decoration: widget.hideSearchFrame ? null : BoxDecoration(
                        color: frameBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: widget.hideSearchFrame
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          // أيقونة بحث / رجوع
                          if (!widget.hideSearchFrame)
                            if (widget.isSearching)
                              GestureDetector(
                                onTap: widget.onToggleSearch,
                                child: Icon(Icons.arrow_back_rounded,
                                    size: 20, color: hintColor),
                              )
                            else
                              Icon(Icons.search_rounded,
                                  size: 20, color: hintColor),
                          if (!widget.hideSearchFrame) const SizedBox(width: 6),

                          // العنوان يختفي / حقل البحث يظهر
                          Expanded(
                            child: Stack(
                              alignment: AlignmentDirectional.centerStart,
                              children: [
                                // العنوان
                                Opacity(
                                  opacity: (1.0 - t * 2).clamp(0.0, 1.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: hintColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.noteCount != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: hintColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${widget.noteCount}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: hintColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // حقل البحث
                                Opacity(
                                  opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                                  child: IgnorePointer(
                                    ignoring: !widget.isSearching,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: widget.searchController,
                                            focusNode: _focusNode,
                                            onChanged: widget.onSearchChange,
                                            decoration: InputDecoration(
                                              hintText: _hintText(context),
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(
                                                  color: hintColor,
                                                  fontSize: 15),
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: textColor),
                                          ),
                                        ),
                                        if (widget.searchController.text
                                            .isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              widget.searchController.clear();
                                              widget.onSearchChange?.call('');
                                            },
                                            child: Icon(Icons.close_rounded,
                                                size: 16, color: hintColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // أزرار trailing — تختفي عند البحث
            if (!widget.isSearching && widget.trailing != null)
              widget.trailing!,
          ],
        ),
      ),
    );
  }

  String _hintText(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ar' ? 'ابحث في الملاحظات' : 'Search notes';
  }
}
