// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/widgets/home/note_card_widget.dart';

class NoteCardWrapper extends StatefulWidget {
  final Note note;
  final ViewType viewType;
  final ValueNotifier<int> closeAllSlidables;
  final ValueNotifier<Set<int>> selectedNoteIdsNotifier;
  final String source;
  final bool isFiltering;

  const NoteCardWrapper({
    super.key,
    required this.note,
    required this.viewType,
    required this.closeAllSlidables,
    required this.selectedNoteIdsNotifier,
    required this.source,
    required this.isFiltering,
  });

  @override
  State<NoteCardWrapper> createState() => _NoteCardWrapperState();
}

class _NoteCardWrapperState extends State<NoteCardWrapper> {
  bool _isSelected = false;
  bool _selectionMode = false;
  bool _isCurrentlyOpen = false;
  SelectedNoteProvider? _selectedNoteProvider;

  @override
  void initState() {
    super.initState();
    _updateSelection(widget.selectedNoteIdsNotifier.value);
    widget.selectedNoteIdsNotifier.addListener(_onSelectionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SelectedNoteProvider>();
    if (_selectedNoteProvider != provider) {
      _selectedNoteProvider?.removeListener(_onOpenChanged);
      _selectedNoteProvider = provider;
      _selectedNoteProvider!.addListener(_onOpenChanged);
      _isCurrentlyOpen = provider.selectedNote?.id == widget.note.id;
    }
  }

  @override
  void dispose() {
    widget.selectedNoteIdsNotifier.removeListener(_onSelectionChanged);
    _selectedNoteProvider?.removeListener(_onOpenChanged);
    super.dispose();
  }

  void _onOpenChanged() {
    final newOpen = _selectedNoteProvider?.selectedNote?.id == widget.note.id;
    if (newOpen != _isCurrentlyOpen) setState(() => _isCurrentlyOpen = newOpen);
  }

  void _onSelectionChanged() {
    final ids = widget.selectedNoteIdsNotifier.value;
    final newSelected = ids.contains(widget.note.id);
    final newMode = ids.isNotEmpty;
    if (newSelected != _isSelected || newMode != _selectionMode) {
      setState(() {
        _isSelected = newSelected;
        _selectionMode = newMode;
      });
    }
  }

  void _updateSelection(Set<int> ids) {
    _isSelected = ids.contains(widget.note.id);
    _selectionMode = ids.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _isCurrentlyOpen ? const EdgeInsets.only(left: 4) : EdgeInsets.zero,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isCurrentlyOpen ? 3 : 0,
            height: 48,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: NoteCardWidget(
              key: ValueKey(widget.note.id),
              note: widget.note,
              viewType: widget.viewType,
              closeAllSlidables: widget.closeAllSlidables,
              isCurrentlyOpen: _isCurrentlyOpen,
              onNoteChanged: () {},
              isSelected: _isSelected,
              selectionMode: _selectionMode,
              source: widget.source,
              isFiltering: widget.isFiltering,
              onLongPress: () {
                if (widget.selectedNoteIdsNotifier.value.isNotEmpty) return;
                widget.selectedNoteIdsNotifier.value = {widget.note.id!};
              },
              onTap: () {
                final current = widget.selectedNoteIdsNotifier.value;
                if (current.isNotEmpty) {
                  final newSet = Set<int>.from(current);
                  newSet.contains(widget.note.id)
                      ? newSet.remove(widget.note.id)
                      : newSet.add(widget.note.id!);
                  widget.selectedNoteIdsNotifier.value = Set<int>.of(newSet);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

