// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/editor/checklist_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChecklistUndoRedoController {
  final VoidCallback undo;
  final VoidCallback redo;
  final bool canUndo;
  final bool canRedo;

  ChecklistUndoRedoController({
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
  });
}

class ChecklistEditor extends StatefulWidget {
  final String initialContent;
  final Function(String jsonContent) onChanged;
  final Color backgroundColor;
  final VoidCallback? onUndoRedoChanged;
  final Function(ChecklistUndoRedoController)? onUndoRedoControllerCreated;

  const ChecklistEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
    required this.backgroundColor,
    this.onUndoRedoChanged,
    this.onUndoRedoControllerCreated,
  });

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  List<ChecklistItem> _items = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, VoidCallback> _listeners = {};
  final TextEditingController _titleController = TextEditingController();

  // Undo/Redo support
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _isUndoRedoAction = false;

  TextDirection _titleDirection = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _parseContent();
    _titleDirection = TextDirectionUtils.getDirection(_titleController.text);
    _titleController.addListener(_notifyParent);
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final newDir = TextDirectionUtils.getDirection(_titleController.text);
    if (newDir != _titleDirection) {
      setState(() => _titleDirection = newDir);
    }
  }

  void _parseContent() {
    if (widget.initialContent.trim().isEmpty) {
      // 🎯 SMART SOLUTION: Add auto item for UX, but mark it as "ghost"
      _addNewItem(isGhostItem: true);
      return;
    }

    try {
      final dynamic decoded = jsonDecode(widget.initialContent);

      if (decoded is Map<String, dynamic>) {
        _titleController.text = decoded['title'] ?? '';
        if (decoded['items'] != null && decoded['items'] is List) {
          _items = (decoded['items'] as List)
              .map((e) => ChecklistItem.fromJson(e))
              .toList();
        }
      } else if (decoded is List) {
        _items = decoded
            .whereType<Map>()
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Fallback: Parse as plain text
      if (widget.initialContent.trim().isNotEmpty) {
        final lines = widget.initialContent
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        _items = lines.map((line) {
          return ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                line.hashCode.toString(),
            text: line.replaceAll(RegExp(r'^-\s*\[.\]\s*'), '').trim(),
          );
        }).toList();
      }
    }

    // Only add item if we have existing content but no parsed items
    if (_items.isEmpty && widget.initialContent.trim().isNotEmpty) {
      _addNewItem();
    }

    for (var item in _items) {
      _initializeController(item);
    }
  }

  void _initializeController(ChecklistItem item) {
    _controllers[item.id] = TextEditingController(text: item.text);
    _focusNodes[item.id] = FocusNode();

    // Store listener reference so we can remove it later
    void listener() {
      item.text = _controllers[item.id]!.text;
      _notifyParent();
    }
    _listeners[item.id] = listener;
    _controllers[item.id]!.addListener(listener);

    _focusNodes[item.id]!.addListener(() {
      if (_focusNodes[item.id]!.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = _focusNodes[item.id]!.context;
          if (context != null && context.mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }
        });
      }
    });
  }

  void _addNewItem({int? insertIndex, bool autoFocus = false, bool isGhostItem = false}) {
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isGhost: isGhostItem, // Mark as ghost for smart filtering
    );

    setState(() {
      if (insertIndex != null) {
        _items.insert(insertIndex, newItem);
      } else {
        _items.add(newItem);
      }
      _initializeController(newItem);
    });

    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[newItem.id]?.requestFocus();
      });
    }
    
    // Only notify parent if not a ghost item or if ghost item gets content
    if (!isGhostItem) {
      _notifyParent();
    }
  }

  void _deleteItem(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1 || _items.length == 1) return;

    setState(() {
      _items.removeAt(index);
      // Remove listener before disposing
      if (_controllers.containsKey(id) && _listeners.containsKey(id)) {
        _controllers[id]!.removeListener(_listeners[id]!);
      }
      _controllers[id]?.dispose();
      _focusNodes[id]?.dispose();
      _controllers.remove(id);
      _focusNodes.remove(id);
      _listeners.remove(id);
    });

    // Safe focus: Check bounds before accessing
    if (index > 0 && _items.isNotEmpty && index - 1 < _items.length) {
      _focusNodes[_items[index - 1].id]?.requestFocus();
    }
    _notifyParent();
  }

  void _toggleDone(ChecklistItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      item.isDone = !item.isDone;
    });
    _notifyParent();
  }

  void sortItems(String type) {
    setState(() {
      if (type == 'doneBottom') {
        _items.sort((a, b) => a.isDone == b.isDone ? 0 : (a.isDone ? 1 : -1));
      } else if (type == 'doneTop') {
        _items.sort((a, b) => a.isDone == b.isDone ? 0 : (a.isDone ? -1 : 1));
      } else if (type == 'original') {
        _items.sort((a, b) => a.id.toString().compareTo(b.id.toString()));
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    if (!mounted) return;
    
    // 🛡️ Force sync all controllers to models
    for (var item in _items) {
      if (_controllers.containsKey(item.id)) {
        item.text = _controllers[item.id]!.text;
        if (item.isGhost && item.text.trim().isNotEmpty) {
          item.isGhost = false;
        }
      }
    }
    
    // 🎯 Filter empty ghost items
    final realItems = _items.where((item) => 
      !item.isGhost || item.text.trim().isNotEmpty
    ).toList();
    
    // ✅ VALIDATION: Prevent saving completely empty checklists
    final title = _titleController.text.trim();
    final hasContent = title.isNotEmpty || 
        realItems.any((item) => item.text.trim().isNotEmpty);
    
    if (!hasContent) {
      // Empty checklist - don't save garbage
      widget.onChanged(jsonEncode({'title': '', 'items': []}));
      return;
    }
    
    final data = {
      'title': title,
      'items': realItems.map((e) => e.toJson()).toList(),
    };
    final jsonData = jsonEncode(data);

    // Save to history for undo/redo
    if (!_isUndoRedoAction) {
      _history.removeRange(_historyIndex + 1, _history.length);
      _history.add(jsonData);
      _historyIndex = _history.length - 1;
      // MEMORY FIX: Reduced from 50 to 20 to limit memory usage
      if (_history.length > 20) {
        _history.removeAt(0);
        _historyIndex--;
      }
    }

    widget.onChanged(jsonData);
    
    // 🔧 FIX: Defer state updates to avoid build-phase conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateUndoRedoController();
        widget.onUndoRedoChanged?.call();
      }
    });
  }

  void _updateUndoRedoController() {
    widget.onUndoRedoControllerCreated?.call(
      ChecklistUndoRedoController(
        undo: undo,
        redo: redo,
        canUndo: canUndo,
        canRedo: canRedo,
      ),
    );
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _restoreState(_history[_historyIndex]);
      widget.onUndoRedoChanged?.call();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _restoreState(_history[_historyIndex]);
      widget.onUndoRedoChanged?.call();
    }
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _restoreState(String jsonData) {
    _isUndoRedoAction = true;
    try {
      final decoded = jsonDecode(jsonData);
      _titleController.text = decoded['title'] ?? '';

      // Clear old items
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      for (var node in _focusNodes.values) {
        node.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();

      // Restore items
      _items = (decoded['items'] as List)
          .map((e) => ChecklistItem.fromJson(e))
          .toList();

      for (var item in _items) {
        _initializeController(item);
      }

      setState(() {});
    } finally {
      _isUndoRedoAction = false;
    }
  }

  double get _progress {
    if (_items.isEmpty) return 0.0;
    final done = _items.where((e) => e.isDone).length;
    return done / _items.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isLightColor = widget.backgroundColor.computeLuminance() > 0.5;
    final Color textColor = isLightColor ? Colors.black87 : Colors.white;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    textDirection: _titleDirection,
                    textAlign: _titleDirection == TextDirection.rtl
                        ? TextAlign.right
                        : TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.checklistTitle,
                      hintStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    maxLines: null,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort_rounded,
                      color: textColor.withValues(alpha: 0.6)),
                  tooltip: l10n.sort,
                  onSelected: sortItems,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'doneBottom',
                      child: Row(children: [
                        const Icon(Icons.arrow_downward, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.sortDoneToBottom, textDirection: Directionality.of(context)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'doneTop',
                      child: Row(children: [
                        const Icon(Icons.arrow_upward, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.sortDoneToTop, textDirection: Directionality.of(context)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'original',
                      child: Row(children: [
                        const Icon(Icons.restore, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.sortOriginal, textDirection: Directionality.of(context)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${_items.where((e) => e.isDone).length} / ${_items.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: textColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress == 1.0 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverReorderableList(
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildItemRow(item, index, textColor);
          },
          itemCount: _items.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
            _notifyParent();
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              shadowColor: Colors.black26,
              elevation: 10,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: keyboardHeight)),
      ],
    );
  }

  Widget _buildItemRow(ChecklistItem item, int index, Color textColor) {
    final controller = _controllers[item.id]!;
    final focusNode = _focusNodes[item.id]!;

    return ChecklistItemWidget(
      key: ValueKey(item.id),
      item: item,
      index: index,
      controller: controller,
      focusNode: focusNode,
      textColor: textColor,
      backgroundColor: widget.backgroundColor,
      showControls: true,
      canDelete: _items.length > 1,
      onToggleDone: () => _toggleDone(item),
      onDelete: () => _deleteItem(item.id),
      onAddBelow: () => _addNewItem(insertIndex: index + 1, autoFocus: true),
      onSubmitted: () => _addNewItem(insertIndex: index + 1, autoFocus: true),
    );
  }

  String get checklistTitle {
    if (_titleController.text.trim().isNotEmpty) {
      return _titleController.text.trim();
    }
    if (_items.isNotEmpty && _items.first.text.isNotEmpty) {
      return _items.first.text;
    }
    return 'Checklist'; // Safe fallback without context access
  }

  @override
  void dispose() {
    // 🛑 CRITICAL: Remove title listeners BEFORE clearing
    _titleController.removeListener(_notifyParent);
    _titleController.removeListener(_onTitleChanged);
    _titleController.clear();
    _titleController.dispose();
    
    // 🛑 CRITICAL: Remove ALL item listeners BEFORE clearing to prevent empty save
    for (var item in _items) {
      if (_controllers.containsKey(item.id) && _listeners.containsKey(item.id)) {
        _controllers[item.id]!.removeListener(_listeners[item.id]!);
      }
    }
    _listeners.clear();
    
    // Now safe to clear and dispose
    for (var controller in _controllers.values) {
      controller.clear();
      controller.dispose();
    }
    _controllers.clear();
    
    // Dispose focus nodes
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
    
    // CRITICAL: Clear undo/redo history to free memory
    _history.clear();
    _historyIndex = -1;
    
    // Clear items list
    _items.clear();
    
    super.dispose();
  }
}
