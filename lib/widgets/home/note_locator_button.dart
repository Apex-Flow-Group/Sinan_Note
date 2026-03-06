// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// زر يحدد موضع النوتة المفتوحة في القائمة ويمرر إليها
class NoteLocatorButton extends StatefulWidget {
  final ScrollController scrollController;

  const NoteLocatorButton({super.key, required this.scrollController});

  @override
  State<NoteLocatorButton> createState() => _NoteLocatorButtonState();
}

class _NoteLocatorButtonState extends State<NoteLocatorButton> {
  // null = مرئية، true = أعلى، false = أسفل
  bool? _direction;
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateDirection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إزالة الـ listener القديم إن وجد
    _selectedNoteProvider?.removeListener(_onNoteChanged);
    // إضافة listener جديد على SelectedNoteProvider
    _selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    _selectedNoteProvider!.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    if (!mounted) return;
    // تأخير بسيط للتأكد من اكتمال الـ layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDirection();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateDirection);
    _selectedNoteProvider?.removeListener(_onNoteChanged);
    super.dispose();
  }

  void _updateDirection() {
    final selectedNote =
        Provider.of<SelectedNoteProvider>(context, listen: false).selectedNote;
    if (selectedNote == null) {
      if (_direction != null) setState(() => _direction = null);
      return;
    }

    final notes = Provider.of<NotesProvider>(context, listen: false).notes;
    final index = notes.indexWhere((n) => n.id == selectedNote.id);
    if (index < 0) return;

    // تقدير موضع العنصر بناءً على ارتفاع تقريبي لكل بطاقة
    const itemHeight = 80.0;
    final estimatedOffset = index * itemHeight;
    final scrollOffset = widget.scrollController.offset;
    final viewportHeight = widget.scrollController.position.viewportDimension;

    bool? newDirection;
    if (estimatedOffset < scrollOffset) {
      newDirection = true; // أعلى
    } else if (estimatedOffset > scrollOffset + viewportHeight - itemHeight) {
      newDirection = false; // أسفل
    }

    if (newDirection != _direction) setState(() => _direction = newDirection);
  }

  void _scrollToNote() {
    final selectedNote =
        Provider.of<SelectedNoteProvider>(context, listen: false).selectedNote;
    if (selectedNote == null) return;

    final notes = Provider.of<NotesProvider>(context, listen: false).notes;
    final index = notes.indexWhere((n) => n.id == selectedNote.id);
    if (index < 0) return;

    const itemHeight = 80.0;
    widget.scrollController.animateTo(
      index * itemHeight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedNoteProvider>(
      builder: (_, selectedNoteProvider, __) {
        final hasNote = selectedNoteProvider.selectedNote != null;

        if (!hasNote || _direction == null) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final fabBottom = MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            16;

        return Positioned(
          bottom: fabBottom,
          left: 16,
          child: GestureDetector(
            onTap: _scrollToNote,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _direction!
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}
