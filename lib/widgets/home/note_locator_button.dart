// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Registry عالمي يحفظ ارتفاع كل بطاقة بعد بنائها
class NoteCardKeyRegistry {
  NoteCardKeyRegistry._();
  static final NoteCardKeyRegistry instance = NoteCardKeyRegistry._();

  /// ارتفاع كل بطاقة محفوظ بعد أول بناء لها
  final Map<int, double> _heights = {};

  void recordHeight(int noteId, double height) {
    _heights[noteId] = height;
  }

  void remove(int noteId) => _heights.remove(noteId);

  Map<int, double> get heights => _heights;

  /// يحسب الـ offset المتراكم للبطاقة بناءً على ترتيب القائمة
  /// مع استخدام الارتفاعات المحفوظة لكل بطاقة
  double estimateOffset(int noteId, List<Note> orderedNotes,
      {double fallbackHeight = 72.0}) {
    double offset = 0;
    for (final note in orderedNotes) {
      if (note.id == noteId) break;
      offset += _heights[note.id] ?? fallbackHeight;
    }
    return offset;
  }

  /// هل الـ offset داخل الـ viewport الحالي؟
  bool isVisible(
      int noteId, List<Note> orderedNotes, ScrollController scrollController,
      {double fallbackHeight = 72.0}) {
    if (!scrollController.hasClients) return false;
    final offset =
        estimateOffset(noteId, orderedNotes, fallbackHeight: fallbackHeight);
    final height = _heights[noteId] ?? fallbackHeight;
    final scrollOffset = scrollController.offset;
    final viewportHeight = scrollController.position.viewportDimension;
    return offset >= scrollOffset &&
        offset + height <= scrollOffset + viewportHeight;
  }
}

/// زر يحدد موضع النوتة المفتوحة في القائمة ويمرر إليها
class NoteLocatorButton extends StatefulWidget {
  final ScrollController scrollController;

  const NoteLocatorButton({super.key, required this.scrollController});

  @override
  State<NoteLocatorButton> createState() => _NoteLocatorButtonState();
}

class _NoteLocatorButtonState extends State<NoteLocatorButton> {
  // null = مرئية، true = أعلى، false = أسفل
  final ValueNotifier<bool?> _direction = ValueNotifier(null);
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateDirection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNoteProvider?.removeListener(_onNoteChanged);
    _selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    _selectedNoteProvider!.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDirection();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateDirection);
    _selectedNoteProvider?.removeListener(_onNoteChanged);
    _direction.dispose();
    super.dispose();
  }

  void _updateDirection() {
    final selectedNote =
        Provider.of<SelectedNoteProvider>(context, listen: false).selectedNote;
    if (selectedNote == null || selectedNote.id == null) {
      if (_direction.value != null) _direction.value = null;
      return;
    }
    if (!widget.scrollController.hasClients) return;

    final notes = Provider.of<NotesProvider>(context, listen: false).notes;
    final registry = NoteCardKeyRegistry.instance;
    final isVis =
        registry.isVisible(selectedNote.id!, notes, widget.scrollController);

    if (isVis) {
      if (_direction.value != null) _direction.value = null;
      return;
    }

    final offset = registry.estimateOffset(selectedNote.id!, notes);
    final scrollOffset = widget.scrollController.offset;
    final viewportHeight = widget.scrollController.position.viewportDimension;

    bool? newDirection;
    if (offset < scrollOffset) {
      newDirection = true;
    } else if (offset > scrollOffset + viewportHeight) {
      newDirection = false;
    }

    if (newDirection != _direction.value) _direction.value = newDirection;
  }

  void _scrollToNote() {
    final selectedNote =
        Provider.of<SelectedNoteProvider>(context, listen: false).selectedNote;
    if (selectedNote == null || selectedNote.id == null) return;
    if (!widget.scrollController.hasClients) return;

    final notes = Provider.of<NotesProvider>(context, listen: false).notes;
    final offset =
        NoteCardKeyRegistry.instance.estimateOffset(selectedNote.id!, notes);

    final target = (offset - 8.0)
        .clamp(0.0, widget.scrollController.position.maxScrollExtent);
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedNoteProvider>(
      builder: (_, selectedNoteProvider, __) {
        final hasNote = selectedNoteProvider.selectedNote != null;
        if (!hasNote) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final fabBottom = MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            16;

        return ValueListenableBuilder<bool?>(
          valueListenable: _direction,
          builder: (context, direction, _) {
            if (direction == null) return const SizedBox.shrink();
            return Positioned(
              bottom: fabBottom,
              left: 16,
              child: GestureDetector(
                onTap: _scrollToNote,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
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
                    direction
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
      },
    );
  }
}
