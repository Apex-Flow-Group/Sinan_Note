// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// مؤشر يساري يطابق تصميم الصفحة الرئيسية — خط صغير + إزاحة خفيفة.
class SelectedNoteIndicator extends StatelessWidget {
  final Note note;
  final Widget child;

  const SelectedNoteIndicator({
    super.key,
    required this.note,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<SelectedNoteProvider, bool>(
      selector: (_, p) => p.selectedNote?.id == note.id,
      builder: (context, isOpen, _) {
        return Padding(
          padding: isOpen ? const EdgeInsets.only(left: 4) : EdgeInsets.zero,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isOpen ? 3 : 0,
                height: 48,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
