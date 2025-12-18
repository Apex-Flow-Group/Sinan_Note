// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class RenameDialog extends StatefulWidget {
  final String initialTitle;
  final Color? backgroundColor;
  final Color? textColor;
  final String? hintText;
  final String? titleText;
  final String? cancelText;
  final String? saveText;

  const RenameDialog({
    super.key,
    required this.initialTitle,
    this.backgroundColor,
    this.textColor,
    this.hintText,
    this.titleText,
    this.cancelText,
    this.saveText,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialTitle.length,
      );
  }

  @override
  void dispose() {
    // 🛑 Flutter يستدعي هذا فقط بعد unmount كامل
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogBg = widget.backgroundColor ??
        theme.dialogTheme.backgroundColor ??
        theme.colorScheme.surface;
    final dialogText = widget.textColor ??
        theme.textTheme.bodyLarge?.color ??
        theme.colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: dialogBg,
      title: Text(
        widget.titleText ?? 'تعديل العنوان',
        style: TextStyle(color: dialogText),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: dialogText),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'أدخل العنوان...',
          hintStyle: TextStyle(color: dialogText.withValues(alpha: 0.5)),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: dialogText.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.cancelText ?? 'إلغاء',
            style: TextStyle(color: dialogText.withValues(alpha: 0.7)),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.saveText ?? 'حفظ',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
