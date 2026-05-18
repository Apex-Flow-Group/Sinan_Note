// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/widgets/home/note_locator_button.dart' show NoteCardKeyRegistry;

class HeightRecorder extends StatefulWidget {
  final int noteId;
  final Widget child;
  const HeightRecorder({super.key, required this.noteId, required this.child});

  @override
  State<HeightRecorder> createState() => _HeightRecorderState();
}

class _HeightRecorderState extends State<HeightRecorder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ro = context.findRenderObject() as RenderBox?;
      if (ro != null && ro.hasSize) {
        NoteCardKeyRegistry.instance.recordHeight(widget.noteId, ro.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

