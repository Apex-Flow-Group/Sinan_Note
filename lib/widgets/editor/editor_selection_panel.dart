// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// بيانات زر واحد في الشريط
class BarEntry {
  final String label;
  final IconData icon;
  final VoidCallback action;
  final bool enabled;
  const BarEntry({
    required this.label,
    required this.icon,
    required this.action,
    this.enabled = true,
  });
}

// ── حالات الشريط ──────────────────────────────────────────────────────────────
enum BarSelectionState { noSelection, hasSelection, allSelected }

/// بانل خيارات النص — يُعرض داخل حاوية الهيدر ويحل محله مباشرة.
/// لا overlay، لا positioned — ويدجت عادي يملأ المساحة المتاحة.
class EditorSelectionPanel extends StatefulWidget {
  final QuillController ctrl;
  final Color backgroundColor;
  final Color textColor;
  final Future<void> Function() onPaste;
  final VoidCallback onDismiss;

  const EditorSelectionPanel({
    super.key,
    required this.ctrl,
    required this.backgroundColor,
    required this.textColor,
    required this.onPaste,
    required this.onDismiss,
  });

  @override
  State<EditorSelectionPanel> createState() => _EditorSelectionPanelState();
}

class _EditorSelectionPanelState extends State<EditorSelectionPanel> {
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

  BarSelectionState _getBarState() {
    final sel = widget.ctrl.selection;
    if (sel.isCollapsed) return BarSelectionState.noSelection;
    final docLen = widget.ctrl.document.length;
    if (sel.start == 0 && sel.end >= docLen - 1) {
      return BarSelectionState.allSelected;
    }
    return BarSelectionState.hasSelection;
  }

  List<BarEntry> _buildEntries(BarSelectionState state, bool isAr) {
    final ctrl = widget.ctrl;

    void doCut() {
      widget.onDismiss();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      Clipboard.setData(ClipboardData(
          text: ctrl.document.toPlainText().substring(sel.start, sel.end)));
      ctrl.replaceText(sel.start, sel.end - sel.start, '',
          TextSelection.collapsed(offset: sel.start));
    }

    void doCopy() {
      widget.onDismiss();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      Clipboard.setData(ClipboardData(
          text: ctrl.document.toPlainText().substring(sel.start, sel.end)));
    }

    void doPaste() {
      widget.onPaste();
      widget.onDismiss();
    }

    void doSelectAll() {
      final len = ctrl.document.length;
      ctrl.updateSelection(TextSelection(baseOffset: 0, extentOffset: len - 1),
          ChangeSource.local);
      _checkClipboard();
    }

    void doDeselect() {
      widget.onDismiss();
      ctrl.updateSelection(
          TextSelection.collapsed(offset: ctrl.selection.start),
          ChangeSource.local);
    }

    switch (state) {
      case BarSelectionState.noSelection:
        return [
          BarEntry(
              label: isAr ? 'لصق' : 'Paste',
              icon: Icons.content_paste_rounded,
              action: doPaste,
              enabled: _hasClipboard),
          BarEntry(
              label: isAr ? 'تحديد الكل' : 'Select all',
              icon: Icons.select_all_rounded,
              action: doSelectAll),
        ];
      case BarSelectionState.hasSelection:
        return [
          BarEntry(
              label: isAr ? 'قص' : 'Cut',
              icon: Icons.content_cut_rounded,
              action: doCut),
          BarEntry(
              label: isAr ? 'نسخ' : 'Copy',
              icon: Icons.content_copy_rounded,
              action: doCopy),
          if (_hasClipboard)
            BarEntry(
                label: isAr ? 'لصق' : 'Paste',
                icon: Icons.content_paste_rounded,
                action: doPaste),
          BarEntry(
              label: isAr ? 'الكل' : 'All',
              icon: Icons.select_all_rounded,
              action: doSelectAll),
          BarEntry(
              label: isAr ? 'إلغاء' : 'Deselect',
              icon: Icons.deselect_rounded,
              action: doDeselect),
        ];
      case BarSelectionState.allSelected:
        return [
          BarEntry(
              label: isAr ? 'قص' : 'Cut',
              icon: Icons.content_cut_rounded,
              action: doCut),
          BarEntry(
              label: isAr ? 'نسخ' : 'Copy',
              icon: Icons.content_copy_rounded,
              action: doCopy),
          if (_hasClipboard)
            BarEntry(
                label: isAr ? 'لصق' : 'Paste',
                icon: Icons.content_paste_rounded,
                action: doPaste),
          BarEntry(
              label: isAr ? 'إلغاء' : 'Deselect',
              icon: Icons.deselect_rounded,
              action: doDeselect),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final barText = widget.textColor;
    final disabledText = barText.withValues(alpha: 0.35);
    final dividerColor = barText.withValues(alpha: 0.15);

    final state = _getBarState();
    final entries = _buildEntries(state, isAr);

    return Container(
      color: widget.backgroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Row(
          key: ValueKey(state),
          children: entries.asMap().entries.map((e) {
            final isLast = e.key == entries.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _BarButton(
                      label: e.value.label,
                      icon: e.value.icon,
                      textColor: e.value.enabled ? barText : disabledText,
                      enabled: e.value.enabled,
                      onAction: e.value.action,
                    ),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 24, color: dividerColor),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// زر داخل الشريط
class _BarButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color textColor;
  final bool enabled;
  final VoidCallback onAction;

  const _BarButton({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.onAction,
    this.enabled = true,
  });

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              setState(() => _pressed = true);
              widget.onAction();
            }
          : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed && widget.enabled
            ? widget.textColor.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 20, color: widget.textColor),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                  fontSize: 10,
                  color: widget.textColor,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
