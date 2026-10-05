// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/ui/core/navigation/app_navigation.dart';
import 'package:sinan_note/ui/features/home/widgets/notes_grid/note_list_layout.dart';
import 'package:sinan_note/ui/features/layout/view_models/selected_note_provider.dart';

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

    final layout = context.read<NoteListLayout>();
    final offset = layout.offsetOf(selectedNote.id!);
    // غير معروضة (مُفلترة) أو ظاهرة: لا اتجاه
    if (offset == null ||
        layout.isVisible(selectedNote.id!, widget.scrollController)) {
      if (_direction.value != null) _direction.value = null;
      return;
    }

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

    final offset = context.read<NoteListLayout>().offsetOf(selectedNote.id!);
    if (offset == null) return;

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

        return ValueListenableBuilder<bool>(
          valueListenable: context.read<AppNavigation>().bottomBarHidden,
          builder: (context, isNavHidden, _) {
            final fabBottom = MediaQuery.of(context).padding.bottom +
                (isNavHidden ? 0.0 : kBottomNavigationBarHeight) +
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
      },
    );
  }
}
