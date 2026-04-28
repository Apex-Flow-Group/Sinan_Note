// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// يبني قائمة السياق المخصصة للمحرر
Widget buildQuillContextMenu(
  BuildContext context,
  QuillRawEditorState rawEditorState,
  QuillController ctrl,
  VoidCallback onPaste,
) {
  final anchor = rawEditorState.contextMenuAnchors;
  final sel = ctrl.selection;
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final menuBg = isDark ? scheme.surfaceContainerHigh : scheme.surface;
  final textClr = scheme.onSurface;

  void doCut() {
    ContextMenuController.removeAny();
    if (sel.isCollapsed) return;
    final text = ctrl.document.toPlainText();
    Clipboard.setData(ClipboardData(text: text.substring(sel.start, sel.end)));
    ctrl.replaceText(
      sel.start,
      sel.end - sel.start,
      '',
      TextSelection.collapsed(offset: sel.start),
    );
  }

  void doCopy() {
    ContextMenuController.removeAny();
    if (sel.isCollapsed) return;
    final text = ctrl.document.toPlainText();
    Clipboard.setData(ClipboardData(text: text.substring(sel.start, sel.end)));
  }

  void doPaste() {
    ContextMenuController.removeAny();
    onPaste();
  }

  void doSelectAll() {
    ContextMenuController.removeAny();
    ctrl.updateSelection(
      TextSelection(baseOffset: 0, extentOffset: ctrl.document.length - 1),
      ChangeSource.local,
    );
  }

  final entries = <({String label, VoidCallback action})>[
    if (!sel.isCollapsed) (label: isAr ? 'قص' : 'Cut', action: doCut),
    if (!sel.isCollapsed) (label: isAr ? 'نسخ' : 'Copy', action: doCopy),
    (label: isAr ? 'لصق' : 'Paste', action: doPaste),
    (label: isAr ? 'تحديد الكل' : 'Select all', action: doSelectAll),
  ];

  return Positioned(
    left: anchor.primaryAnchor.dx,
    top: anchor.primaryAnchor.dy,
    child: Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: menuBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: entries
                .map((e) => _ContextMenuItem(
                      label: e.label,
                      onAction: e.action,
                      textColor: textClr,
                    ))
                .toList(),
          ),
        ),
      ),
    ),
  );
}

/// زر في قائمة السياق — يستخدم onTapDown لضمان التنفيذ قبل فقدان الـ focus
class _ContextMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onAction;
  final Color textColor;

  const _ContextMenuItem({
    required this.label,
    required this.onAction,
    required this.textColor,
  });

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => widget.onAction(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hovered
              ? scheme.onSurface.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              widget.label,
              style: TextStyle(fontSize: 14, color: widget.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
