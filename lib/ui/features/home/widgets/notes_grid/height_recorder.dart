// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/ui/features/home/widgets/notes_grid/note_list_layout.dart';

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
        context
            .read<NoteListLayout>()
            .recordHeight(widget.noteId, ro.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
