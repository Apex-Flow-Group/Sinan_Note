// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';import 'package:flutter/material.dart'; import 'package:flutter/services.dart'; import 'package:flutter_quill/flutter_quill.dart';
// ── حالات القائمة ─────────────────────────────────────────────────────────────
enum _MenuState { noSelection, hasSelection, allSelected }

/// يبني قائمة السياق الذكية للمحرر على سطح المكتب
Widget buildQuillContextMenu(
  BuildContext context,
  QuillRawEditorState rawEditorState,
  QuillController ctrl,
  VoidCallback onPaste,
) {
  return _DesktopContextMenu(
    rawEditorState: rawEditorState,
    ctrl: ctrl,
    onPaste: onPaste,
  );
}

class _DesktopContextMenu extends StatefulWidget {
  final QuillRawEditorState rawEditorState;
  final QuillController ctrl;
  final VoidCallback onPaste;

  const _DesktopContextMenu({
    required this.rawEditorState,
    required this.ctrl,
    required this.onPaste,
  });

  @override
  State<_DesktopContextMenu> createState() => _DesktopContextMenuState();
}

class _DesktopContextMenuState extends State<_DesktopContextMenu> {
  bool _hasClipboard = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
    widget.ctrl.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (mounted) {
      setState(() => _hasClipboard = data?.text?.isNotEmpty ?? false);
    }
  }

  _MenuState _getState() {
    final sel = widget.ctrl.selection;
    if (sel.isCollapsed) return _MenuState.noSelection;
    final docLen = widget.ctrl.document.length;
    if (sel.start == 0 && sel.end >= docLen - 1) return _MenuState.allSelected;
    return _MenuState.hasSelection;
  }

  @override
  Widget build(BuildContext context) {
    final anchor = widget.rawEditorState.contextMenuAnchors;
    final ctrl = widget.ctrl;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBg = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final textClr = scheme.onSurface;
    final state = _getState();

    // ── الأوامر ──────────────────────────────────────────────────────────────
    void doCut() {
      ContextMenuController.removeAny();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      final text = ctrl.document.toPlainText();
      Clipboard.setData(
          ClipboardData(text: text.substring(sel.start, sel.end)));
      ctrl.replaceText(sel.start, sel.end - sel.start, '',
          TextSelection.collapsed(offset: sel.start));
    }

    void doCopy() {
      ContextMenuController.removeAny();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      final text = ctrl.document.toPlainText();
      Clipboard.setData(
          ClipboardData(text: text.substring(sel.start, sel.end)));
    }

    void doPaste() {
      // اللصق أولاً قبل الإغلاق — حتى لا يُفقد التحديد
      widget.onPaste();
      ContextMenuController.removeAny();
    }

    void doSelectAll() {
      // لا نُغلق — يتحول لحالة allSelected
      final len = ctrl.document.length;
      ctrl.updateSelection(
        TextSelection(baseOffset: 0, extentOffset: len - 1),
        ChangeSource.local,
      );
      _checkClipboard();
    }

    void doDeselect() {
      ContextMenuController.removeAny();
      ctrl.updateSelection(
        TextSelection.collapsed(offset: ctrl.selection.start),
        ChangeSource.local,
      );
    }

    // ── بناء الأزرار حسب الحالة ──────────────────────────────────────────────
    final entries =
        <({String label, IconData icon, VoidCallback action, bool enabled})>[];

    switch (state) {
      case _MenuState.noSelection:
        entries.addAll([
          (
            label: isAr ? 'لصق' : 'Paste',
            icon: Icons.content_paste_rounded,
            action: doPaste,
            enabled: _hasClipboard
          ),
          (
            label: isAr ? 'تحديد الكل' : 'Select all',
            icon: Icons.select_all_rounded,
            action: doSelectAll,
            enabled: true
          ),
        ]);
      case _MenuState.hasSelection:
        entries.addAll([
          (
            label: isAr ? 'قص' : 'Cut',
            icon: Icons.content_cut_rounded,
            action: doCut,
            enabled: true
          ),
          (
            label: isAr ? 'نسخ' : 'Copy',
            icon: Icons.content_copy_rounded,
            action: doCopy,
            enabled: true
          ),
          if (_hasClipboard)
            (
              label: isAr ? 'لصق' : 'Paste',
              icon: Icons.content_paste_rounded,
              action: doPaste,
              enabled: true
            ),
          (
            label: isAr ? 'تحديد الكل' : 'All',
            icon: Icons.select_all_rounded,
            action: doSelectAll,
            enabled: true
          ),
          (
            label: isAr ? 'إلغاء' : 'Deselect',
            icon: Icons.deselect_rounded,
            action: doDeselect,
            enabled: true
          ),
        ]);
      case _MenuState.allSelected:
        entries.addAll([
          (
            label: isAr ? 'قص' : 'Cut',
            icon: Icons.content_cut_rounded,
            action: doCut,
            enabled: true
          ),
          (
            label: isAr ? 'نسخ' : 'Copy',
            icon: Icons.content_copy_rounded,
            action: doCopy,
            enabled: true
          ),
          if (_hasClipboard)
            (
              label: isAr ? 'لصق' : 'Paste',
              icon: Icons.content_paste_rounded,
              action: doPaste,
              enabled: true
            ),
          (
            label: isAr ? 'إلغاء التحديد' : 'Deselect',
            icon: Icons.deselect_rounded,
            action: doDeselect,
            enabled: true
          ),
        ]);
    }

    // ── حساب الموضع داخل حدود الشاشة ─────────────────────────────────────────
    const menuWidth = 180.0;
    const itemHeight = 40.0;
    final menuHeight = entries.length * itemHeight;
    final screen = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    double dx = anchor.primaryAnchor.dx;
    double dy = anchor.primaryAnchor.dy;

    if (dx + menuWidth > screen.width - 8) dx = screen.width - menuWidth - 8;
    if (dx < 8) dx = 8;
    if (dy + menuHeight > screen.height - safeBottom - 8) {
      dy = dy - menuHeight - 8;
    }
    if (dy < 8) dy = 8;

    return Positioned(
      left: dx,
      top: dy,
      child: Material(
        color: Colors.transparent,
        child: TapRegion(
          onTapOutside: (_) => ContextMenuController.removeAny(),
          child: Container(
            width: menuWidth,
            decoration: BoxDecoration(
              color: menuBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final isFirst = i == 0;
                final isLast = i == entries.length - 1;
                return _DesktopMenuItem(
                  label: e.label,
                  icon: e.icon,
                  onAction: e.action,
                  textColor:
                      e.enabled ? textClr : textClr.withValues(alpha: 0.3),
                  enabled: e.enabled,
                  isFirst: isFirst,
                  isLast: isLast,
                  menuBg: menuBg,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onAction;
  final Color textColor;
  final bool enabled;
  final bool isFirst;
  final bool isLast;
  final Color menuBg;

  const _DesktopMenuItem({
    required this.label,
    required this.icon,
    required this.onAction,
    required this.textColor,
    required this.enabled,
    required this.isFirst,
    required this.isLast,
    required this.menuBg,
  });

  @override
  State<_DesktopMenuItem> createState() => _DesktopMenuItemState();
}

class _DesktopMenuItemState extends State<_DesktopMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.vertical(
      top: widget.isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: widget.isLast ? const Radius.circular(12) : Radius.zero,
    );

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => widget.onAction() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? scheme.onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: widget.textColor),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.textColor,
                    fontWeight: FontWeight.w500,
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

